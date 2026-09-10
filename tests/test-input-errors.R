library(coniv)

expect_error_text <- function(expression, pattern) {
  message <- tryCatch(
    {
      force(expression)
      NA_character_
    },
    error = function(error) conditionMessage(error)
  )
  if (is.na(message) || !grepl(pattern, message, fixed = TRUE)) {
    stop(sprintf("Expected error containing '%s'; got '%s'.", pattern, message))
  }
}

z <- c(-2, -1, 0, 1, 2)
base_config <- list(
  outcome_type = "continuous",
  observational_data = data.frame(
    centre = "A", X = c(-2, 0, 1, 5, 6),
    Y = c(-4, 0, 2, 7, 9), Z1 = z
  ),
  reference_data = data.frame(Y = c(0, 1, 1, 2, 4), Z1 = z),
  columns = list(center = "centre", exposure = "X", outcome = "Y"),
  candidate_variables = "Z1",
  strategies = "IV_single_same",
  selection = list(
    mode = "provided", shared = "Z1", center_specific = list(A = "Z1")
  ),
  estimation = list(hc_type = "HC1", min_n = 5, min_abs_pi = 1e-8)
)

missing_reference <- base_config
missing_reference$reference_data$Z1 <- NULL
expect_error_text(
  run_coniv(missing_reference),
  "Candidate variables must occur in both datasets"
)

bad_binary <- base_config
bad_binary$outcome_type <- "binary"
bad_binary$observational_data$Y[1] <- 2
expect_error_text(
  run_coniv(bad_binary),
  "Binary outcomes must be coded 0/1"
)

missing_center_set <- base_config
missing_center_set$observational_data <- rbind(
  base_config$observational_data,
  transform(base_config$observational_data, centre = "B")
)
expect_error_text(
  run_coniv(missing_center_set),
  "center_specific is missing centers: B"
)

singular <- base_config
singular$observational_data <- rbind(
  data.frame(centre = "A", X = z, Y = 2 * z, Z1 = z),
  data.frame(centre = "B", X = z, Y = 2 * z, Z1 = z)
)
singular$selection$center_specific <- list(A = "Z1", B = "Z1")
singular$estimation$ridge_relative <- 0
singular_result <- run_coniv(singular)
stopifnot(
  !singular_result$estimates$valid,
  grepl("not positive definite", singular_result$estimates$reason, fixed = TRUE)
)

