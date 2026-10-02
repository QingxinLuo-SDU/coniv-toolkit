#' Run an MCM-CONIV analysis
#'
#' @param config A configuration list or a path to a JSON configuration file.
#' @return A structured MCM-CONIV analysis result.
#' @export
run_coniv <- function(config) {
  config <- read_coniv_config(config)
  inputs <- normalize_coniv_inputs(config)
  strategies <- unique(as.character(config_value(
    config,
    "strategies",
    c("IV_single_same", "IV_single_diff", "IV_multi_same", "IV_multi_diff")
  )))
  allowed_strategies <- c(
    "IV_single_same", "IV_single_diff", "IV_multi_same", "IV_multi_diff"
  )
  if (!length(strategies) || !all(strategies %in% allowed_strategies)) {
    coniv_abort("strategies contains an unknown method name.")
  }

  estimation <- config_value(config, "estimation", list())
  hc_type <- as.character(config_value(estimation, "hc_type", "HC1"))
  min_n <- as.integer(config_value(estimation, "min_n", 20L))
  min_abs_pi <- as.numeric(config_value(estimation, "min_abs_pi", 0.02))
  ridge_relative <- as.numeric(config_value(estimation, "ridge_relative", 0))
  weight_type_multi <- as.character(config_value(
    estimation, "weight_type_multi", "diag_delta"
  ))

  method_results <- list()
  estimate_rows <- list()
  center_rows <- list()
  selection_rows <- list()
  gls_weight_rows <- list()
  covariance_matrices <- list()
  diagnostic_records <- list()

  for (strategy in strategies) {
    selection_result <- select_iv_lists(config, inputs, strategy)
    iv_lists <- selection_result$iv_lists
    all_ivs <- unique(unlist(iv_lists, use.names = FALSE))
    if (!all(all_ivs %in% inputs$candidates)) {
      coniv_abort(sprintf("Strategy %s uses variables outside candidate_variables.", strategy))
    }
    reference_info <- make_reference_info(
      inputs$reference, all_ivs, hc_type = hc_type, min_n = min_n
    )
    weight_type <- if (grepl("multi", strategy, fixed = TRUE)) {
      weight_type_multi
    } else {
      "identity"
    }

    centers <- stats::setNames(vector("list", length(inputs$centers)), inputs$centers)
    for (center_id in inputs$centers) {
      observed <- inputs$observational[
        inputs$observational$.center == center_id, , drop = FALSE
      ]
      centers[[center_id]] <- tryCatch(
        estimate_coniv_center(
          observed = observed,
          reference_info = reference_info,
          iv_names = iv_lists[[center_id]],
          weight_type = weight_type,
          hc_type = hc_type,
          min_n = min_n,
          min_abs_pi = min_abs_pi,
          center_id = center_id
        ),
        error = function(error) list(
          valid = FALSE, reason = conditionMessage(error), center = center_id,
          IV_names = iv_lists[[center_id]]
        )
      )
    }
    gls <- combine_coniv_gls(
      centers, reference_info, ridge_relative = ridge_relative
    )
    method_results[[strategy]] <- list(
      strategy = strategy,
      outcome_type = inputs$outcome_type,
      selection = iv_lists,
      reference_info = reference_info,
      center_results = centers,
      gls = gls
    )

    covariance_matrices[[strategy]] <- list(
      V_raw = gls$V_raw,
      V_sym = gls$V_sym,
      V_used = gls$V_used
    )
    if (isTRUE(gls$valid)) {
      gls_weight_rows[[strategy]] <- data.frame(
        strategy = strategy,
        center = gls$center_order,
        center_estimate = as.numeric(gls$theta_centers[gls$center_order]),
        weight = as.numeric(gls$weights[gls$center_order]),
        contribution = as.numeric(
          gls$weights[gls$center_order] * gls$theta_centers[gls$center_order]
        ),
        negative_weight = as.numeric(gls$weights[gls$center_order]) < 0,
        stringsAsFactors = FALSE
      )
    }
    diagnostic_records[[strategy]] <- list(
      valid = isTRUE(gls$valid),
      reason = gls$reason,
      center_order = gls$center_order,
      symmetry_error_raw = gls$symmetry_error_raw,
      eigen_min_raw = gls$eigen_min_raw,
      eigen_max_raw = gls$eigen_max_raw,
      condition_number_raw = gls$condition_number_raw,
      gls_method = gls$method,
      ridge_added = gls$ridge_added,
      stabilization_norm = gls$stabilization_norm
    )

    estimate_rows[[strategy]] <- data.frame(
      strategy = strategy,
      outcome_type = inputs$outcome_type,
      valid = isTRUE(gls$valid),
      reason = if (isTRUE(gls$valid)) NA_character_ else gls$reason,
      estimate = if (isTRUE(gls$valid)) gls$estimate else NA_real_,
      se = if (isTRUE(gls$valid)) gls$se else NA_real_,
      variance = if (isTRUE(gls$valid)) gls$variance else NA_real_,
      ci_lower = if (isTRUE(gls$valid)) gls$ci_lower else NA_real_,
      ci_upper = if (isTRUE(gls$valid)) gls$ci_upper else NA_real_,
      p_value = if (isTRUE(gls$valid)) gls$p_value else NA_real_,
      valid_centers = sum(vapply(centers, function(x) isTRUE(x$valid), logical(1))),
      gls_method = if (isTRUE(gls$valid)) gls$method else NA_character_,
      stringsAsFactors = FALSE
    )

    for (center_id in names(centers)) {
      item <- centers[[center_id]]
      center_rows[[paste(strategy, center_id, sep = "::")]] <- data.frame(
        strategy = strategy,
        center = center_id,
        valid = isTRUE(item$valid),
        reason = if (isTRUE(item$valid)) NA_character_ else item$reason,
        estimate = if (isTRUE(item$valid)) item$theta else NA_real_,
        se = if (isTRUE(item$valid)) item$se else NA_real_,
        denominator = if (!is.null(item$denominator)) item$denominator else NA_real_,
        variables = paste(item$IV_names, collapse = ";"),
        stringsAsFactors = FALSE
      )
    }
    selection_rows[[strategy]] <- selection_result$diagnostics
  }

  result <- list(
    estimates = do.call(rbind, estimate_rows),
    center_estimates = do.call(rbind, center_rows),
    selected_variables = do.call(rbind, selection_rows),
    gls_weights = if (length(gls_weight_rows)) {
      do.call(rbind, gls_weight_rows)
    } else {
      data.frame()
    },
    covariance_matrices = covariance_matrices,
    diagnostics = diagnostic_records,
    methods = method_results,
    config = config,
    metadata = list(
      package_version = as.character(utils::packageVersion("coniv")),
      outcome_type = inputs$outcome_type,
      centers = inputs$centers,
      observational_n = nrow(inputs$observational),
      reference_n = nrow(inputs$reference)
    )
  )
  class(result) <- "coniv_result"
  result
}

#' Write MCM-CONIV result files
#'
#' @param result A result returned by [run_coniv()].
#' @param output_dir Output directory.
#' @return The normalized output directory, invisibly.
#' @export
write_coniv_results <- function(result, output_dir) {
  if (!inherits(result, "coniv_result")) {
    coniv_abort("result must be returned by run_coniv().")
  }
  if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
    coniv_abort("output_dir must be one non-empty path.")
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir)) {
    coniv_abort(sprintf("Could not create output directory: %s", output_dir))
  }
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)
  matrix_dir <- file.path(output_dir, "matrices")
  dir.create(matrix_dir, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(result$estimates, file.path(output_dir, "estimates.csv"),
                   row.names = FALSE, na = "")
  utils::write.csv(result$center_estimates,
                   file.path(output_dir, "center_estimates.csv"),
                   row.names = FALSE, na = "")
  utils::write.csv(result$selected_variables,
                   file.path(output_dir, "selected_variables.csv"),
                   row.names = FALSE, na = "")
  utils::write.csv(result$gls_weights,
                   file.path(output_dir, "gls_weights.csv"),
                   row.names = FALSE, na = "")

  for (strategy in names(result$covariance_matrices)) {
    matrices <- result$covariance_matrices[[strategy]]
    for (matrix_name in c("V_raw", "V_sym", "V_used")) {
      matrix_value <- matrices[[matrix_name]]
      if (!is.null(matrix_value)) {
        utils::write.csv(
          matrix_value,
          file.path(matrix_dir, paste0(strategy, "-", matrix_name, ".csv")),
          row.names = TRUE,
          na = ""
        )
      }
    }
  }

  jsonlite::write_json(
    result$diagnostics,
    file.path(output_dir, "diagnostics.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    na = "null",
    digits = NA
  )

  manifest <- list(
    status = if (all(result$estimates$valid)) "success" else "partial_or_failed",
    package = "coniv",
    package_version = result$metadata$package_version,
    outcome_type = result$metadata$outcome_type,
    strategies = as.character(result$estimates$strategy),
    observational_n = result$metadata$observational_n,
    reference_n = result$metadata$reference_n,
    center_order = result$metadata$centers,
    random_seed = config_value(result$config, "random_seed", NA_integer_),
    R_version = R.version.string,
    platform = R.version$platform,
    jsonlite_version = as.character(utils::packageVersion("jsonlite")),
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
  jsonlite::write_json(
    manifest,
    file.path(output_dir, "run_manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    na = "null"
  )

  paper_table <- result$estimates[c(
    "strategy", "outcome_type", "estimate", "se", "ci_lower", "ci_upper",
    "p_value", "valid_centers", "gls_method"
  )]
  utils::write.csv(paper_table, file.path(output_dir, "paper_table.csv"),
                   row.names = FALSE, na = "")
  header <- paste(names(paper_table), collapse = " | ")
  divider <- paste(rep("---", ncol(paper_table)), collapse = " | ")
  rows <- apply(paper_table, 1L, function(row) {
    values <- ifelse(is.na(row), "", as.character(row))
    paste(values, collapse = " | ")
  })
  writeLines(
    c(paste0("| ", header, " |"),
      paste0("| ", divider, " |"),
      paste0("| ", rows, " |")),
    file.path(output_dir, "paper_table.md"),
    useBytes = TRUE
  )

  log_lines <- c(
    sprintf("status=%s", manifest$status),
    sprintf("package_version=%s", manifest$package_version),
    sprintf("outcome_type=%s", manifest$outcome_type),
    sprintf("strategies=%s", paste(manifest$strategies, collapse = ",")),
    sprintf("observational_n=%d", manifest$observational_n),
    sprintf("reference_n=%d", manifest$reference_n)
  )
  writeLines(log_lines, file.path(output_dir, "run.log"), useBytes = TRUE)

  invisible(output_dir)
}
