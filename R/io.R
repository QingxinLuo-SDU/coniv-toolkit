coniv_abort <- function(message, class = "coniv_error") {
  condition <- structure(
    list(message = message, call = NULL),
    class = c(class, "error", "condition")
  )
  stop(condition)
}

read_coniv_config <- function(config) {
  if (is.list(config)) {
    return(config)
  }

  if (!is.character(config) || length(config) != 1L || !nzchar(config)) {
    coniv_abort("config must be a list or one JSON file path.")
  }
  if (!file.exists(config)) {
    coniv_abort(sprintf("Configuration file does not exist: %s", config))
  }

  path <- normalizePath(config, winslash = "/", mustWork = TRUE)
  out <- jsonlite::fromJSON(path, simplifyVector = TRUE)
  attr(out, "config_dir") <- dirname(path)
  out
}

resolve_config_path <- function(path, config_dir = NULL) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    coniv_abort("Input path must be one non-empty string.")
  }
  if (!grepl("^(?:[A-Za-z]:[/\\\\]|/)", path) && !is.null(config_dir)) {
    path <- file.path(config_dir, path)
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

load_coniv_data <- function(config, data_key, path_key) {
  value <- config[[data_key]]
  if (is.data.frame(value)) {
    return(value)
  }

  path <- config[[path_key]]
  if (is.null(path)) {
    coniv_abort(sprintf("Provide %s as a data frame or %s as a CSV path.",
                        data_key, path_key))
  }
  path <- resolve_config_path(path, attr(config, "config_dir"))
  utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

config_value <- function(x, name, default = NULL) {
  value <- x[[name]]
  if (is.null(value)) default else value
}

normalize_coniv_inputs <- function(config) {
  columns <- config$columns
  if (!is.list(columns)) {
    coniv_abort("config$columns must define center, exposure, and outcome.")
  }
  required_column_keys <- c("center", "exposure", "outcome")
  if (!all(required_column_keys %in% names(columns))) {
    coniv_abort("config$columns must define center, exposure, and outcome.")
  }

  observational <- load_coniv_data(
    config, "observational_data", "observational_path"
  )
  reference <- load_coniv_data(config, "reference_data", "reference_path")

  obs_required <- unlist(columns[required_column_keys], use.names = FALSE)
  ref_required <- columns$outcome
  missing_obs <- setdiff(obs_required, names(observational))
  missing_ref <- setdiff(ref_required, names(reference))
  if (length(missing_obs)) {
    coniv_abort(sprintf("Observational data are missing columns: %s",
                        paste(missing_obs, collapse = ", ")))
  }
  if (length(missing_ref)) {
    coniv_abort(sprintf("Reference data are missing columns: %s",
                        paste(missing_ref, collapse = ", ")))
  }

  candidates <- unique(as.character(config$candidate_variables))
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  if (!length(candidates)) {
    coniv_abort("candidate_variables must contain at least one variable.")
  }
  missing_candidates <- setdiff(
    candidates,
    intersect(names(observational), names(reference))
  )
  if (length(missing_candidates)) {
    coniv_abort(sprintf(
      "Candidate variables must occur in both datasets: %s",
      paste(missing_candidates, collapse = ", ")
    ))
  }

  center <- observational[[columns$center]]
  if (anyNA(center) || any(!nzchar(trimws(as.character(center))))) {
    coniv_abort("Center identifiers must be non-missing and non-empty.")
  }
  center <- as.character(center)
  exposure <- observational[[columns$exposure]]
  outcome_obs <- observational[[columns$outcome]]
  outcome_ref <- reference[[columns$outcome]]

  numeric_names <- c(columns$exposure, columns$outcome, candidates)
  non_numeric_obs <- numeric_names[!vapply(
    observational[numeric_names], is.numeric, logical(1)
  )]
  non_numeric_ref <- c(columns$outcome, candidates)[!vapply(
    reference[c(columns$outcome, candidates)], is.numeric, logical(1)
  )]
  if (length(non_numeric_obs) || length(non_numeric_ref)) {
    coniv_abort("Exposure, outcome, and candidate variables must be numeric.")
  }
  if (anyNA(observational[c(columns$exposure, columns$outcome, candidates)]) ||
      anyNA(reference[c(columns$outcome, candidates)])) {
    coniv_abort("Missing values are not supported in version 0.1.0.")
  }
  if (any(!is.finite(as.matrix(
    observational[c(columns$exposure, columns$outcome, candidates)]
  ))) || any(!is.finite(as.matrix(reference[c(columns$outcome, candidates)])))) {
    coniv_abort("Exposure, outcome, and candidate variables must be finite.")
  }

  outcome_type <- match.arg(
    as.character(config$outcome_type), c("continuous", "binary")
  )
  if (outcome_type == "binary") {
    observed_values <- sort(unique(c(outcome_obs, outcome_ref)))
    if (!all(observed_values %in% c(0, 1))) {
      coniv_abort("Binary outcomes must be coded 0/1 in both datasets.")
    }
  }

  list(
    observational = data.frame(
      .center = center,
      .x = exposure,
      .y = outcome_obs,
      observational[candidates],
      check.names = FALSE
    ),
    reference = data.frame(
      .y = outcome_ref,
      reference[candidates],
      check.names = FALSE
    ),
    centers = unique(center),
    candidates = candidates,
    outcome_type = outcome_type,
    original_columns = columns
  )
}

