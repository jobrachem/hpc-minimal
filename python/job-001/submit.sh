#!/bin/bash
#SBATCH --job-name=minimal-python
#SBATCH --partition=scc-cpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --array=1-5%2
#SBATCH --output=slurm-%A_%a.out

set -euo pipefail
cd "$SLURM_SUBMIT_DIR"

module load uv
# Create or update .venv from the lockfile; installation counts toward job time.
uv sync --locked

# One numerical-library thread per process matches our one-CPU request.
export OMP_NUM_THREADS=1       # OpenMP
export OPENBLAS_NUM_THREADS=1  # OpenBLAS
export MKL_NUM_THREADS=1       # Intel Math Kernel Library

# Each submission gets a folder for its CSV results.
output_dir="results/$SLURM_ARRAY_JOB_ID"
mkdir -p "$output_dir"

# Discard executed notebooks by default. Uncomment to save one per task.
notebook_output=/dev/null
# notebook_output="$output_dir/$(printf 'task-%03d.ipynb' "$SLURM_ARRAY_TASK_ID")"

# Use the environment synced above without another installation check.
# Slurm's --time limits the whole job; no separate per-cell timeout is needed.
uv run --no-sync --offline papermill run.ipynb "$notebook_output" \
    -p task_id "$SLURM_ARRAY_TASK_ID" -p output_dir "$output_dir" \
    --log-output --no-progress-bar
