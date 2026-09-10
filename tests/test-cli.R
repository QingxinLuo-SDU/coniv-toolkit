library(coniv)

local({
  rscript <- file.path(R.home("bin"), "Rscript.exe")
  if (!file.exists(rscript)) rscript <- file.path(R.home("bin"), "Rscript")
  library_paths <- gsub("\\\\", "/", utils::shortPathName(.libPaths()))
  old_r_libs_user <- Sys.getenv("R_LIBS_USER", unset = NA_character_)
  Sys.setenv(R_LIBS_USER = paste(library_paths, collapse = .Platform$path.sep))
  on.exit({
    if (is.na(old_r_libs_user)) {
      Sys.unsetenv("R_LIBS_USER")
    } else {
      Sys.setenv(R_LIBS_USER = old_r_libs_user)
    }
  })

  for (outcome in c("continuous", "binary")) {
    output_dir <- tempfile(paste0("coniv-cli-", outcome, "-"))
    repeat_dir <- tempfile(paste0("coniv-cli-repeat-", outcome, "-"))
    cli <- system.file("cli", "coniv.R", package = "coniv")
    config <- system.file(
      "config", paste0("example-", outcome, ".json"), package = "coniv"
    )
    stopifnot(nzchar(cli), nzchar(config))
    command_output <- system2(
      rscript,
      c(
        "--vanilla", shQuote(cli), "--config", shQuote(config),
        "--output", shQuote(output_dir)
      ),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- attr(command_output, "status")
    if (!is.null(status) && status != 0L) {
      stop(sprintf("%s CLI failed:\n%s", outcome,
                   paste(command_output, collapse = "\n")))
    }
    if (!file.exists(file.path(output_dir, "estimates.csv"))) {
      stop(sprintf("%s CLI did not write estimates.csv", outcome))
    }
    estimates <- utils::read.csv(file.path(output_dir, "estimates.csv"))
    stopifnot(nrow(estimates) == 4L, all(estimates$valid))

    repeat_output <- system2(
      rscript,
      c(
        "--vanilla", shQuote(cli), "--config", shQuote(config),
        "--output", shQuote(repeat_dir)
      ),
      stdout = TRUE,
      stderr = TRUE
    )
    repeat_status <- attr(repeat_output, "status")
    if (!is.null(repeat_status) && repeat_status != 0L) {
      stop(sprintf("%s repeated CLI run failed:\n%s", outcome,
                   paste(repeat_output, collapse = "\n")))
    }
    repeated <- utils::read.csv(file.path(repeat_dir, "estimates.csv"))
    stopifnot(isTRUE(all.equal(estimates, repeated, tolerance = 0)))
  }
})
