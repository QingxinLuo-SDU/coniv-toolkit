combine_coniv_gls <- function(center_results, reference_info,
                              ridge_relative = 0) {
  valid <- vapply(center_results, function(x) isTRUE(x$valid), logical(1))
  valid_results <- center_results[valid]
  if (!length(valid_results)) {
    return(list(valid = FALSE, reason = "No valid center estimates."))
  }

  center_order <- names(valid_results)
  theta <- vapply(valid_results, `[[`, numeric(1), "theta")
  count <- length(valid_results)
  v_raw <- matrix(0, count, count, dimnames = list(center_order, center_order))
  diag(v_raw) <- vapply(valid_results, `[[`, numeric(1), "var")

  if (count > 1L) {
    for (i in seq_len(count - 1L)) {
      for (j in seq.int(i + 1L, count)) {
        left <- valid_results[[i]]
        right <- valid_results[[j]]
        if (!all(left$IV_names %in% rownames(reference_info$vcov)) ||
            !all(right$IV_names %in% colnames(reference_info$vcov))) {
          coniv_abort("Reference covariance names do not match center variable order.")
        }
        block <- reference_info$vcov[
          left$IV_names, right$IV_names, drop = FALSE
        ]
        covariance <- as.numeric(t(left$a_vec) %*% block %*% right$a_vec)
        v_raw[i, j] <- v_raw[j, i] <- covariance
      }
    }
  }

  symmetry_error <- max(abs(v_raw - t(v_raw)))
  v_sym <- (v_raw + t(v_raw)) / 2
  eigenvalues <- eigen(v_sym, symmetric = TRUE, only.values = TRUE)$values
  scale <- max(diag(v_sym))
  ridge_added <- 0
  v_used <- v_sym
  method <- "FGLS_raw"
  if (min(eigenvalues) <= .Machine$double.eps * max(1, scale)) {
    if (!is.numeric(ridge_relative) || length(ridge_relative) != 1L ||
        !is.finite(ridge_relative) || ridge_relative <= 0) {
      return(list(
        valid = FALSE,
        reason = "The raw center covariance matrix is not positive definite.",
        V_raw = v_raw,
        V_sym = v_sym,
        eigenvalues_raw = eigenvalues
      ))
    }
    ridge_added <- ridge_relative * scale
    v_used <- v_sym + diag(ridge_added, count)
    method <- "FGLS_ridge_finite_sample"
  }

  inverse <- try(solve(v_used), silent = TRUE)
  if (inherits(inverse, "try-error")) {
    return(list(valid = FALSE, reason = "The covariance matrix cannot be inverted.",
                V_raw = v_raw, V_sym = v_sym, V_used = v_used))
  }
  ones <- rep(1, count)
  denominator <- as.numeric(t(ones) %*% inverse %*% ones)
  if (!is.finite(denominator) || denominator <= 0) {
    return(list(valid = FALSE, reason = "The GLS denominator is invalid.",
                V_raw = v_raw, V_sym = v_sym, V_used = v_used))
  }
  weights <- as.numeric(inverse %*% ones / denominator)
  names(weights) <- center_order
  estimate <- sum(weights * theta)
  variance <- 1 / denominator

  list(
    valid = TRUE,
    reason = NA_character_,
    estimate = estimate,
    variance = variance,
    se = sqrt(variance),
    ci_lower = estimate - stats::qnorm(0.975) * sqrt(variance),
    ci_upper = estimate + stats::qnorm(0.975) * sqrt(variance),
    p_value = 2 * stats::pnorm(abs(estimate / sqrt(variance)), lower.tail = FALSE),
    theta_centers = theta,
    weights = weights,
    method = method,
    V_raw = v_raw,
    V_sym = v_sym,
    V_used = v_used,
    symmetry_error_raw = symmetry_error,
    eigen_min_raw = min(eigenvalues),
    eigen_max_raw = max(eigenvalues),
    condition_number_raw = if (min(eigenvalues) > 0) {
      max(eigenvalues) / min(eigenvalues)
    } else {
      NA_real_
    },
    ridge_added = ridge_added,
    stabilization_norm = sqrt(sum((v_used - v_raw)^2)),
    center_order = center_order
  )
}
