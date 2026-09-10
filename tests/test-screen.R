library(coniv)

n <- 30L
z1 <- seq(-2, 2, length.out = n)
z2 <- rep(c(-1, 1, 0), length.out = n)
noise_x <- rep(c(-0.3, 0.1, 0.2, -0.1, 0.05), length.out = n)
noise_y <- rep(c(0.2, -0.2, 0.1, -0.05, 0), length.out = n)

observational <- rbind(
  data.frame(centre = "A", X = 0.9 * z1 + noise_x,
             Y = 1.1 * (0.9 * z1 + noise_x) + 0.8 * z1 + noise_y,
             Z1 = z1, Z2 = z2),
  data.frame(centre = "B", X = 0.8 * z1 + rev(noise_x),
             Y = 1.1 * (0.8 * z1 + rev(noise_x)) + 0.7 * z1 + rev(noise_y),
             Z1 = z1, Z2 = rev(z2))
)
reference <- data.frame(
  Y = 0.35 * z1 + noise_y,
  Z1 = z1,
  Z2 = z2
)

config <- list(
  outcome_type = "continuous",
  observational_data = observational,
  reference_data = reference,
  columns = list(center = "centre", exposure = "X", outcome = "Y"),
  candidate_variables = c("Z1", "Z2"),
  strategies = c("IV_single_same", "IV_multi_diff"),
  selection = list(
    mode = "screen",
    correlation_threshold = 0.9,
    pi_min = 0.05,
    F_min = 5,
    p_y_cutoff = 0.05,
    y_adjust_x = FALSE,
    multi_iv_threshold = 1,
    max_iv = 5
  ),
  estimation = list(hc_type = "HC1", min_n = 20, min_abs_pi = 1e-8)
)

result <- run_coniv(config)
z1_rows <- result$selected_variables[
  result$selected_variables$variable == "Z1", , drop = FALSE
]

stopifnot(
  nrow(z1_rows) >= 2L,
  all(z1_rows$selected),
  all(result$estimates$valid)
)

