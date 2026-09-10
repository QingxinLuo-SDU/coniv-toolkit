library(coniv)

z <- c(-2, -1, 0, 1, 2)
config <- list(
  outcome_type = "continuous",
  observational_data = rbind(
    data.frame(centre = "A", X = c(-2, 0, 1, 5, 6),
               Y = c(-4, 0, 2, 7, 9), Z1 = z),
    data.frame(centre = "B", X = c(-3, -1, 2, 4, 8),
               Y = c(-5, -1, 3, 6, 12), Z1 = z)
  ),
  reference_data = data.frame(Y = c(0, 1, 1, 2, 4), Z1 = z),
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
output_dir <- tempfile("coniv-output-")
write_coniv_results(result, output_dir)

required <- c(
  "estimates.csv", "center_estimates.csv", "selected_variables.csv",
  "gls_weights.csv", "diagnostics.json", "run_manifest.json",
  "paper_table.csv", "paper_table.md", "run.log",
  "matrices/IV_single_same-V_raw.csv",
  "matrices/IV_single_same-V_sym.csv",
  "matrices/IV_single_same-V_used.csv"
)
missing <- required[!file.exists(file.path(output_dir, required))]
if (length(missing)) {
  stop(sprintf("Missing output files: %s", paste(missing, collapse = ", ")))
}

manifest_text <- paste(readLines(file.path(output_dir, "run_manifest.json")),
                       collapse = "\n")
if (grepl("observational_data|reference_data", manifest_text, fixed = FALSE)) {
  stop("Run manifest contains input-level data fields.")
}

