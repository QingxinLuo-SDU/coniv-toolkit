slope_if_matrix <- function(response, variables, hc_type = "HC1", min_n = 5L) {
  variables <- as.data.frame(variables, check.names = FALSE)
  response <- as.numeric(response)
  n <- length(response)

  if (nrow(variables) != n || n < min_n) {
    coniv_abort(sprintf("At least %d aligned observations are required.", min_n))
  }
  if (!ncol(variables)) {
    coniv_abort("At least one slope variable is required.")
  }
  if (anyNA(response) || anyNA(variables)) {
    coniv_abort("Slope inputs must be complete.")
  }

  betas <- stats::setNames(rep(NA_real_, ncol(variables)), names(variables))
  contributions <- matrix(
    NA_real_, nrow = n, ncol = ncol(variables),
    dimnames = list(NULL, names(variables))
  )

  for (j in seq_along(variables)) {
    z <- as.numeric(variables[[j]])
    design <- cbind(`(Intercept)` = 1, Z = z)
    if (qr(design)$rank < 2L) {
      coniv_abort(sprintf("Variable '%s' is constant or singular.", names(variables)[j]))
    }
    fit <- stats::lm.fit(design, response)
    inverse <- solve(crossprod(design))
    coefficient_contributions <- sweep(
      design %*% inverse,
      1L,
      fit$residuals,
      `*`
    )
    if (identical(hc_type, "HC1")) {
      coefficient_contributions <- coefficient_contributions * sqrt(n / (n - 2))
    } else if (!identical(hc_type, "HC0")) {
      coniv_abort("hc_type must be 'HC0' or 'HC1'.")
    }
    betas[j] <- unname(fit$coefficients[2L])
    contributions[, j] <- coefficient_contributions[, 2L]
  }

  list(
    beta = betas,
    IF = contributions,
    vcov = crossprod(contributions),
    n = n,
    hc_type = hc_type
  )
}

make_reference_info <- function(reference, iv_names, hc_type, min_n) {
  iv_names <- unique(iv_names)
  fit <- slope_if_matrix(
    reference$.y,
    reference[iv_names],
    hc_type = hc_type,
    min_n = min_n
  )
  fit$variables <- iv_names
  fit
}

