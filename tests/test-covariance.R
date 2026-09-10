library(coniv)

assert_close <- function(actual, expected, tolerance = 1e-10, label = "value") {
  if (length(actual) != length(expected) ||
      any(!is.finite(actual)) ||
      max(abs(actual - expected)) > tolerance) {
    stop(sprintf("%s mismatch: got %s, expected %s",
                 label,
                 paste(actual, collapse = ", "),
                 paste(expected, collapse = ", ")))
  }
}

z <- c(-2, -1, 0, 1, 2)
reference <- data.frame(Y = c(0, 1, 1, 2, 4), Z1 = z)
observational <- rbind(
  data.frame(centre = "A", X = c(-2, 0, 1, 5, 6),
             Y = c(-4, 0, 2, 7, 9), Z1 = z),
  data.frame(centre = "B", X = c(-3, -1, 2, 4, 8),
             Y = c(-5, -1, 3, 6, 12), Z1 = z)
)

config <- list(
  outcome_type = "continuous",
  observational_data = observational,
  reference_data = reference,
  columns = list(center = "centre", exposure = "X", outcome = "Y"),
  candidate_variables = "Z1",
  strategies = "IV_single_same",
  selection = list(
    mode = "provided", shared = "Z1",
    center_specific = list(A = "Z1", B = "Z1")
  ),
  estimation = list(hc_type = "HC1", min_n = 5, min_abs_pi = 1e-8)
)

result <- run_coniv(config)
matrices <- result$covariance_matrices$IV_single_same

# Worked example: reference HC1 slope variance is 97/3000 and the two
# outcome-gradient terms are 10/21 and 10/27, so cov(A,B) = 97/17010.
assert_close(matrices$V_raw["A", "B"], 97 / 17010,
             label = "shared-reference cross-center covariance")
stopifnot(
  nrow(result$gls_weights) == 2L,
  identical(as.character(result$gls_weights$center), c("A", "B"))
)
assert_close(sum(result$gls_weights$weight), 1, label = "GLS weight sum")

center <- result$center_estimates[result$center_estimates$valid, ]
diagonal_weights <- (1 / center$se^2) / sum(1 / center$se^2)
diagonal_estimate <- sum(diagonal_weights * center$estimate)
if (abs(result$estimates$estimate - diagonal_estimate) <= 1e-8) {
  stop("Full-covariance GLS unexpectedly equals diagonal-only pooling.")
}

weak <- config
weak$estimation$min_abs_pi <- 10
weak_result <- run_coniv(weak)
stopifnot(!weak_result$estimates$valid)

