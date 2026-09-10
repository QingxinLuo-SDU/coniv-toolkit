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

reference <- data.frame(
  Y = c(0, 1, 1, 2, 4),
  Z1 = c(-2, -1, 0, 1, 2)
)

observational <- data.frame(
  centre = rep("A", 5),
  X = c(-2, 0, 1, 5, 6),
  Y = c(-4, 0, 2, 7, 9),
  Z1 = c(-2, -1, 0, 1, 2)
)

config <- list(
  outcome_type = "continuous",
  observational_data = observational,
  reference_data = reference,
  columns = list(center = "centre", exposure = "X", outcome = "Y"),
  candidate_variables = "Z1",
  strategies = "IV_single_same",
  selection = list(
    mode = "provided",
    shared = "Z1",
    center_specific = list(A = "Z1")
  ),
  estimation = list(hc_type = "HC1", min_n = 5, min_abs_pi = 1e-8)
)

result <- run_coniv(config)
row <- result$estimates[result$estimates$strategy == "IV_single_same", ]

stopifnot(nrow(row) == 1L, isTRUE(row$valid))
assert_close(row$estimate, 8 / 7, label = "single-variable estimate")

config$strategies <- c(
  "IV_single_same", "IV_single_diff", "IV_multi_same", "IV_multi_diff"
)
all_methods <- run_coniv(config)
stopifnot(
  identical(as.character(all_methods$estimates$strategy), config$strategies),
  all(all_methods$estimates$valid)
)
assert_close(
  all_methods$estimates$estimate,
  rep(8 / 7, 4),
  label = "single-variable degeneration across four strategies"
)

