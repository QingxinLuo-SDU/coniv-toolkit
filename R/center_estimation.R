make_weight_matrix <- function(sigma_delta, weight_type) {
  k <- nrow(sigma_delta)
  if (weight_type == "identity") {
    return(diag(k))
  }
  if (weight_type == "diag_delta") {
    diagonal <- diag(sigma_delta)
    if (any(!is.finite(diagonal)) || any(diagonal <= 0)) {
      coniv_abort("diag_delta weights require positive finite variances.")
    }
    return(diag(1 / diagonal, nrow = k))
  }
  if (weight_type == "inv_delta") {
    return(solve(sigma_delta))
  }
  coniv_abort("weight_type must be identity, diag_delta, or inv_delta.")
}

estimate_coniv_center <- function(observed, reference_info, iv_names,
                                  weight_type, hc_type, min_n, min_abs_pi,
                                  center_id) {
  iv_names <- unique(as.character(iv_names))
  if (!length(iv_names)) {
    return(list(valid = FALSE, reason = "No CON-IV variables.",
                center = center_id, IV_names = character()))
  }
  if (!all(iv_names %in% names(observed)) ||
      !all(iv_names %in% names(reference_info$beta))) {
    return(list(valid = FALSE,
                reason = "CON-IV variables are absent or misordered in the reference information.",
                center = center_id, IV_names = iv_names))
  }

  fit_x <- slope_if_matrix(
    observed$.x, observed[iv_names], hc_type = hc_type, min_n = min_n
  )
  fit_y <- slope_if_matrix(
    observed$.y, observed[iv_names], hc_type = hc_type, min_n = min_n
  )
  pi <- fit_x$beta[iv_names]
  gamma_observed <- fit_y$beta[iv_names]
  gamma_reference <- reference_info$beta[iv_names]
  delta <- gamma_observed - gamma_reference

  if (any(abs(pi) < min_abs_pi)) {
    return(list(valid = FALSE, reason = "At least one treatment slope is below min_abs_pi.",
                center = center_id, IV_names = iv_names, pi = pi))
  }

  sigma_pi <- fit_x$vcov[iv_names, iv_names, drop = FALSE]
  sigma_gamma_observed <- fit_y$vcov[iv_names, iv_names, drop = FALSE]
  sigma_gamma_reference <- reference_info$vcov[
    iv_names, iv_names, drop = FALSE
  ]
  sigma_delta_pi <- crossprod(
    fit_y$IF[, iv_names, drop = FALSE],
    fit_x$IF[, iv_names, drop = FALSE]
  )
  sigma_delta <- sigma_gamma_observed + sigma_gamma_reference
  weight <- make_weight_matrix(sigma_delta, weight_type)
  denominator <- as.numeric(t(pi) %*% weight %*% pi)
  if (!is.finite(denominator) || denominator <= 0) {
    return(list(valid = FALSE, reason = "The weighted treatment-slope denominator is invalid.",
                center = center_id, IV_names = iv_names, pi = pi))
  }

  theta <- as.numeric(t(pi) %*% weight %*% delta / denominator)
  a <- as.numeric(weight %*% pi / denominator)
  b <- as.numeric(weight %*% (delta - 2 * theta * pi) / denominator)
  names(a) <- names(b) <- iv_names

  variance <- as.numeric(
    t(a) %*% sigma_delta %*% a +
      t(b) %*% sigma_pi %*% b +
      2 * t(a) %*% sigma_delta_pi %*% b
  )
  if (!is.finite(variance) || variance <= 0) {
    return(list(valid = FALSE, reason = "The center influence-function variance is not positive.",
                center = center_id, IV_names = iv_names, theta = theta))
  }

  list(
    valid = TRUE,
    reason = NA_character_,
    center = center_id,
    n = nrow(observed),
    IV_names = iv_names,
    theta = theta,
    var = variance,
    se = sqrt(variance),
    pi = pi,
    gamma_observed = gamma_observed,
    gamma_reference = gamma_reference,
    delta = delta,
    denominator = denominator,
    a_vec = a,
    b_vec = b,
    weight_type = weight_type,
    sigma_pi = sigma_pi,
    sigma_delta = sigma_delta,
    sigma_delta_pi = sigma_delta_pi
  )
}

