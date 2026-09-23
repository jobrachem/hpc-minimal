# ..............................................................................
# ---- Set parameters ----
# ..............................................................................

if (interactive()) {
  # Edit these when sourcing the script or running it section by section.
  task_id <- 1
  output_dir <- "job-001/results/local-test"
} else {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) {
    stop("Usage: Rscript run.R TASK_ID OUTPUT_DIR")
  }
  task_id <- as.numeric(args[1])
  output_dir <- args[2]
}

if (length(task_id) != 1L || is.na(task_id) || !task_id %in% 1:5) {
  stop("TASK_ID must be an integer from 1 to 5")
}

# ..............................................................................
# ---- Create output directory and check output file existence ----
# ..............................................................................

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output <- file.path(output_dir, sprintf("task-%03d.rds", task_id))
if (file.exists(output)) {
  stop("Refusing to overwrite: ", output)
}


# ..............................................................................
# ---- Run simulation code ----
# ..............................................................................

set.seed(task_id)

sample_sizes <- c(10, 30, 100, 300, 1000)

results <- data.frame(
  task_id = task_id,
  repetition = seq_len(1000),
  sample_size = sample_sizes[task_id],
  sample_mean = replicate(1000, mean(rnorm(sample_sizes[task_id])))
)

# ..............................................................................
# ---- Save results ----
# ..............................................................................
saveRDS(results, output)
message("Saved ", nrow(results), " repetitions to ", output)
