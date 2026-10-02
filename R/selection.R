provided_iv_lists <- function(config, centers, strategy) {
  selection <- config$selection
  shared <- unique(as.character(selection$shared))
  shared <- shared[!is.na(shared) & nzchar(shared)]
  center_specific <- selection$center_specific
  if (!is.list(center_specific)) {
    center_specific <- stats::setNames(rep(list(shared), length(centers)), centers)
  }
  missing_centers <- setdiff(centers, names(center_specific))
  if (length(missing_centers)) {
    coniv_abort(sprintf("center_specific is missing centers: %s",
                        paste(missing_centers, collapse = ", ")))
  }

  if (strategy == "IV_single_same") {
    iv_lists <- stats::setNames(rep(list(shared[1L]), length(centers)), centers)
  } else if (strategy == "IV_multi_same") {
    iv_lists <- stats::setNames(rep(list(shared), length(centers)), centers)
  } else if (strategy == "IV_single_diff") {
    iv_lists <- lapply(center_specific[centers], function(x) as.character(x)[1L])
  } else if (strategy == "IV_multi_diff") {
    iv_lists <- lapply(center_specific[centers], as.character)
  } else {
    coniv_abort(sprintf("Unknown MCM-CONIV strategy: %s", strategy))
  }

  diagnostics <- do.call(rbind, lapply(centers, function(center_id) {
    data.frame(
      strategy = strategy,
      center = center_id,
      variable = iv_lists[[center_id]],
      selected = TRUE,
      selection_mode = "provided",
      reason = "provided",
      rank = seq_along(iv_lists[[center_id]]),
      pi = NA_real_,
      F_statistic = NA_real_,
      p_x = NA_real_,
      p_y = NA_real_,
      stringsAsFactors = FALSE
    )
  }))
  list(iv_lists = iv_lists, diagnostics = diagnostics)
}

fit_screen_term <- function(observed, variable, y_adjust_x) {
  frame <- data.frame(
    y = observed$.y,
    x = observed$.x,
    z = observed[[variable]]
  )
  fit_x <- stats::lm(x ~ z, data = frame)
  summary_x <- summary(fit_x)$coefficients
  pi <- unname(summary_x["z", "Estimate"])
  se_pi <- unname(summary_x["z", "Std. Error"])
  p_x <- unname(summary_x["z", "Pr(>|t|)"])

  fit_y <- if (isTRUE(y_adjust_x)) {
    stats::lm(y ~ x + z, data = frame)
  } else {
    stats::lm(y ~ z, data = frame)
  }
  summary_y <- summary(fit_y)$coefficients
  p_y <- if ("z" %in% rownames(summary_y)) {
    unname(summary_y["z", "Pr(>|t|)"])
  } else {
    NA_real_
  }

  data.frame(
    variable = variable,
    pi = pi,
    se_pi = se_pi,
    F_statistic = if (is.finite(se_pi) && se_pi > 0) (pi / se_pi)^2 else NA_real_,
    p_x = p_x,
    p_y = p_y,
    abs_cor_x = abs(stats::cor(frame$x, frame$z)),
    stringsAsFactors = FALSE
  )
}

screen_one_center <- function(observed, candidates, selection) {
  pi_min <- as.numeric(config_value(selection, "pi_min", 0.02))
  f_min <- as.numeric(config_value(selection, "F_min", 10))
  p_y_cutoff <- as.numeric(config_value(selection, "p_y_cutoff", 0.10))
  correlation_threshold <- as.numeric(config_value(
    selection, "correlation_threshold", 0.90
  ))
  y_adjust_x <- isTRUE(config_value(selection, "y_adjust_x", TRUE))

  diagnostics <- do.call(rbind, lapply(candidates, function(variable) {
    tryCatch(
      fit_screen_term(observed, variable, y_adjust_x),
      error = function(error) data.frame(
        variable = variable, pi = NA_real_, se_pi = NA_real_,
        F_statistic = NA_real_, p_x = NA_real_, p_y = NA_real_,
        abs_cor_x = NA_real_, stringsAsFactors = FALSE
      )
    )
  }))
  diagnostics$eligible <- with(
    diagnostics,
    is.finite(pi) & abs(pi) >= pi_min &
      is.finite(F_statistic) & F_statistic >= f_min &
      is.finite(p_y) & p_y <= p_y_cutoff
  )
  diagnostics$reason <- ifelse(
    diagnostics$eligible, "eligible", "failed_relevance_or_outcome_screen"
  )
  diagnostics$rank <- NA_integer_

  eligible <- diagnostics$variable[diagnostics$eligible]
  if (length(eligible)) {
    ordering <- order(
      diagnostics$abs_cor_x[match(eligible, diagnostics$variable)],
      decreasing = TRUE
    )
    eligible <- eligible[ordering]
  }
  kept <- character()
  for (variable in eligible) {
    correlated <- if (!length(kept)) FALSE else any(vapply(
      kept,
      function(previous) {
        value <- abs(stats::cor(observed[[variable]], observed[[previous]]))
        is.finite(value) && value > correlation_threshold
      },
      logical(1)
    ))
    if (correlated) {
      diagnostics$reason[diagnostics$variable == variable] <-
        "correlated_with_higher_ranked_variable"
    } else {
      kept <- c(kept, variable)
    }
  }
  diagnostics$rank[match(kept, diagnostics$variable)] <- seq_along(kept)
  diagnostics$eligible <- diagnostics$variable %in% kept
  list(variables = kept, diagnostics = diagnostics)
}

screen_iv_lists <- function(config, inputs, strategy) {
  selection <- config$selection
  centers <- inputs$centers
  screened <- stats::setNames(lapply(centers, function(center_id) {
    observed <- inputs$observational[
      inputs$observational$.center == center_id, , drop = FALSE
    ]
    screen_one_center(observed, inputs$candidates, selection)
  }), centers)

  shared_strategy <- strategy %in% c("IV_single_same", "IV_multi_same")
  single_strategy <- strategy %in% c("IV_single_same", "IV_single_diff")
  multi_threshold <- as.integer(config_value(
    selection, "multi_iv_threshold", 5L
  ))
  max_iv <- as.numeric(config_value(selection, "max_iv", Inf))

  reduce_variables <- function(variables) {
    if (!length(variables)) return(character())
    if (single_strategy) return(variables[1L])
    if (length(variables) <= multi_threshold) return(variables[1L])
    if (is.finite(max_iv)) variables <- utils::head(variables, as.integer(max_iv))
    variables
  }

  if (shared_strategy) {
    sizes <- table(inputs$observational$.center)
    largest_center <- names(sizes)[which.max(sizes)]
    shared <- reduce_variables(screened[[largest_center]]$variables)
    iv_lists <- stats::setNames(rep(list(shared), length(centers)), centers)
  } else {
    largest_center <- NA_character_
    iv_lists <- stats::setNames(lapply(
      screened[centers], function(item) reduce_variables(item$variables)
    ), centers)
  }

  diagnostics <- do.call(rbind, lapply(centers, function(center_id) {
    item <- screened[[center_id]]$diagnostics
    item$strategy <- strategy
    item$center <- center_id
    item$selected <- item$variable %in% iv_lists[[center_id]]
    item$selection_mode <- "screen"
    if (shared_strategy && center_id != largest_center) {
      item$reason[item$selected] <- "selected_from_largest_center"
    } else {
      item$reason[item$selected] <- "selected"
    }
    item[, c(
      "strategy", "center", "variable", "selected", "selection_mode",
      "reason", "rank", "pi", "F_statistic", "p_x", "p_y"
    )]
  }))

  list(
    iv_lists = iv_lists,
    diagnostics = diagnostics,
    largest_center = largest_center
  )
}

select_iv_lists <- function(config, inputs, strategy) {
  selection <- config$selection
  if (!is.list(selection) || is.null(selection$mode)) {
    coniv_abort("config$selection must define mode = 'provided' or 'screen'.")
  }
  if (identical(selection$mode, "provided")) {
    return(provided_iv_lists(config, inputs$centers, strategy))
  }
  if (identical(selection$mode, "screen")) {
    return(screen_iv_lists(config, inputs, strategy))
  }
  coniv_abort("selection$mode must be 'provided' or 'screen'.")
}

