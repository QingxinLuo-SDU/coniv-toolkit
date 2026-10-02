#!/usr/bin/env Rscript

parse_args <- function(args) {
  out <- list(config = NULL, output = NULL, help = FALSE)
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (arg %in% c("-h", "--help")) {
      out$help <- TRUE
      i <- i + 1L
    } else if (arg %in% c("-c", "--config", "-o", "--output")) {
      if (i == length(args)) stop(sprintf("Missing value after %s", arg))
      key <- if (arg %in% c("-c", "--config")) "config" else "output"
      out[[key]] <- args[[i + 1L]]
      i <- i + 2L
    } else {
      stop(sprintf("Unknown argument: %s", arg))
    }
  }
  out
}

usage <- function() {
  cat(paste(
    "Usage: Rscript inst/cli/coniv.R --config FILE [--output DIRECTORY]",
    "",
    "Runs the coniv R package using a JSON configuration file.",
    "--output overrides output_dir from the configuration.",
    sep = "\n"
  ))
}

resolve_output <- function(result, override) {
  path <- if (!is.null(override)) override else result$config$output_dir
  if (is.null(path) || !is.character(path) || length(path) != 1L || !nzchar(path)) {
    stop("Provide --output or output_dir in the configuration.")
  }
  config_dir <- attr(result$config, "config_dir")
  is_absolute <- grepl("^(?:[A-Za-z]:[/\\\\]|/)", path)
  if (!is_absolute && is.null(override) && !is.null(config_dir)) {
    path <- file.path(config_dir, path)
  }
  path
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  if (args$help) {
    usage()
    return(invisible(0L))
  }
  if (is.null(args$config)) stop("--config is required.")
  if (!requireNamespace("coniv", quietly = TRUE)) {
    stop("The coniv package is not installed. Install the repository first.")
  }

  result <- coniv::run_coniv(args$config)
  output_dir <- resolve_output(result, args$output)
  written <- coniv::write_coniv_results(result, output_dir)
  cat(sprintf("MCM-CONIV analysis complete: %s\n", written))
  invisible(0L)
}

status <- tryCatch(
  main(),
  error = function(error) {
    message(sprintf("MCM-CONIV analysis failed: %s", conditionMessage(error)))
    1L
  }
)
quit(save = "no", status = status, runLast = FALSE)

