# Run from the repository root: Rscript --vanilla tests/check.R
script <- normalizePath("job-001/run.R", mustWork = TRUE)
work <- tempfile("minimal-hpc-r-check-")
dir.create(work)

run <- function(task, folder, success = TRUE) {
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(script), shQuote(task), shQuote(file.path(work, folder))),
    stdout = TRUE, stderr = TRUE, timeout = 10
  )
  status <- attr(output, "status")
  stopifnot(if (success) is.null(status) else identical(status, 1L))
}

tryCatch({
  for (task in 1:5) run(as.character(task), "first")
  results <- lapply(list.files(file.path(work, "first"), full.names = TRUE), readRDS)
  stopifnot(length(results) == 5L)
  for (task in 1:5) {
    result <- results[[task]]
    stopifnot(nrow(result) == 1000L, all(result$task_id == task),
              identical(result$repetition, 1:1000),
              all(result$sample_size == c(10, 30, 100, 300, 1000)[task]),
              all(is.finite(result$sample_mean)))
  }
  run("1", "second")
  stopifnot(identical(results[[1]], readRDS(file.path(work, "second/task-001.rds"))))
  suppressWarnings(run("1", "first", success = FALSE))
  stopifnot(identical(results[[1]], readRDS(file.path(work, "first/task-001.rds"))))
  for (task in c("0", "6", "1.5", "invalid")) {
    suppressWarnings(run(task, "invalid", success = FALSE))
  }
  stopifnot(!dir.exists(file.path(work, "invalid")))
  message("Passed: array tasks, repeatable results, invalid IDs, overwrite protection.")
}, finally = unlink(work, recursive = TRUE))
