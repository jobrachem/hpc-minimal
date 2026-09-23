#!/bin/bash
#SBATCH --job-name=minimal-r
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

module load gcc/14.2.0
module load r/4.5.2
export R_LIBS_USER="$HOME/R/library-4.5.2-gcc-14.2.0"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1

Rscript run.R "$SLURM_ARRAY_TASK_ID" "results/$SLURM_ARRAY_JOB_ID"
