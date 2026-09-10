#!/usr/bin/env Rscript

required <- c("jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

cat(sprintf("R: %s\n", R.version.string))
cat(sprintf("Platform: %s\n", R.version$platform))
if (length(missing)) {
  cat(sprintf("Missing packages: %s\n", paste(missing, collapse = ", ")))
  quit(save = "no", status = 1L, runLast = FALSE)
}
cat("Runtime dependencies: OK\n")

