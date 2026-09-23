args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript run.R TASK_ID OUTPUT_DIR")

sample_sizes <- c(10, 30, 100, 300, 1000)
task_id <- suppressWarnings(as.numeric(args[1]))
if (is.na(task_id) || !task_id %in% seq_along(sample_sizes)) {
  stop("TASK_ID must be an integer from 1 to 5")
}

dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
output <- file.path(args[2], sprintf("task-%03d.rds", task_id))
if (file.exists(output)) stop("Refusing to overwrite: ", output)

set.seed(task_id)
results <- data.frame(
  task_id = task_id,
  repetition = seq_len(1000),
  sample_size = sample_sizes[task_id],
  sample_mean = replicate(1000, mean(rnorm(sample_sizes[task_id])))
)
saveRDS(results, output)
message("Saved ", nrow(results), " repetitions to ", output)
