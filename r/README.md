# Run an R simulation on the GWDG HPC

First download the examples and set up SSH using your [macOS](../guides/macos.md), [Linux](../guides/linux.md), or [Windows](../guides/windows.md) guide. Then follow this page to completion. You need R installed locally and your usual R editor or console.

- [Prepare and test locally](#prepare-and-test-locally)
- [Prepare the cluster environment](#prepare-the-cluster-environment)
- [Submit a job array](#submit-a-job-array)

## Prepare and test locally

### Understand the example

[`run.R`](job-001/run.R) simulates sample means. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000; each task saves 1,000 repetitions. It uses only base R and seeds each task by its number.

### Keep the whole repository open

Open `minimal-hpc-r` as your editor's workspace, then open `r/job-001/run.R`. Keep the repository open; set only the **local R console's working directory** to the `r` subfolder. Expand your OS and replace the example path:

<details>
<summary>macOS</summary>

```r
setwd("/Users/YOUR_NAME/path/to/minimal-hpc-r/r")
```

</details>

<details>
<summary>Linux</summary>

```r
setwd("/home/YOUR_NAME/path/to/minimal-hpc-r/r")
```

</details>

<details>
<summary>Windows</summary>

```r
setwd("C:/path/to/minimal-hpc-r/r")
```

</details>

### Run the example locally

In that **R console**:

```r
source("job-001/run.R")
stopifnot(nrow(results) == 1000L)
head(results)
```

Expected: 1,000 rows and `r/job-001/results/local-test/task-001.rds` in the repository. You can also run the script section by section. Edit its interactive `task_id` and `output_dir` defaults to try another task or folder; existing results are never overwritten.

## Prepare the cluster environment

### Upload code and data

Save your edits, then create the destination in the **SSH terminal**:

```bash
mkdir -p ~/minimal-hpc-r/r/job-001
```

In your **local terminal**, use your OS block below. Replace the example path and `YOUR_HPC_USERNAME`; if you connected to a different login host, use that host here too. Save `submit.sh` with **LF / Unix line endings**.

<details>
<summary>macOS</summary>

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r/r/job-001"
scp run.R submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

</details>

<details>
<summary>Linux</summary>

```bash
cd "/home/YOUR_NAME/path/to/minimal-hpc-r/r/job-001"
scp run.R submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

</details>

<details>
<summary>Windows</summary>

```powershell
cd "C:/path/to/minimal-hpc-r/r/job-001"
scp run.R submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

</details>

Wait for the transfer to finish without errors. `scp` replaces matching destination files; leave files used by queued or running jobs unchanged until they finish.

**For your own input data:** put small files in `r/job-001/data`. From the same **local terminal**, still in the job folder, copy it with:

```sh
scp -r data YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

This command works on all three systems. For large datasets, choose storage using the [GWDG storage guide](https://docs.hpc.gwdg.de/how_to_use/storage_systems/index.html). Run `show-quota` in SSH to check your limits.

### Load R

In the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/r/job-001
ls
module load gcc/14.2.0
module load r/4.5.2
Rscript --version
```

Expect `run.R`, `submit.sh`, and R version 4.5.2. If the modules are unavailable, use `module spider r` and `module spider r/VERSION` to find a version and its compiler requirement; update the matching lines in `submit.sh`. See [GWDG's R modules](https://docs.hpc.gwdg.de/software_stacks/compilers_interpreters/r/index.html).

Repeat the module loads in each new SSH session. The submission script already loads them for jobs.

### Install R packages on the server

**Skip this for the supplied example.** For your own code, install its packages on the cluster as well as locally. With the modules above loaded, run in the **SSH terminal**:

```bash
export R_LIBS_USER="$HOME/R/library-4.5.2-gcc-14.2.0"
mkdir -p "$R_LIBS_USER"
Rscript -e 'install.packages("digest", lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org")'
Rscript -e 'library(digest); packageVersion("digest")'
```

Replace `digest` with your package. To install several, pass `c("digest", "withr")` to `install.packages()`. Wait for installation to finish; a warning about a non-zero exit status means a package failed to install. The final command should print a version without an error.

Use the same compiler, R version, and `R_LIBS_USER` in your session and `submit.sh`. If you change module versions, change the library folder too. Repeat the `export` in new sessions; load packages with `library()` inside your script. Install before submitting jobs and avoid updates while jobs use the library. See [GWDG's package instructions](https://docs.hpc.gwdg.de/software_stacks/compilers_interpreters/r/index.html#building-r-packages).

## Submit a job array

A **job array** runs the same code for several task numbers, with each task saving its own result.

### Check the submission script

Open [`submit.sh`](job-001/submit.sh) locally. It requests one CPU, 1 GiB of memory, and five minutes per task. `--array=1-5%2` runs five tasks, at most two at a time. Adjust these settings for your own workload.

The script uses `scc-cpu`; other accounts/islands may need a different [partition](https://docs.hpc.gwdg.de/how_to_use/compute_partitions/cpu_partitions/index.html). For **email notifications**, replace `YOUR_EMAIL@example.com` and uncomment the two mail directives. They notify you when the array starts, ends, or fails.

Upload any edits using the [upload commands above](#upload-code-and-data) before submitting.

### Submit one task first

In the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/r/job-001
sbatch --array=1 submit.sh
```

Record the job ID printed by `sbatch`. Use `sbatch`, not `bash submit.sh`, so Slurm supplies the task IDs and compute resources. You can disconnect after submitting.

### Check the test job

In the **SSH terminal**, still in the job folder, replace `123456` with your job ID:

```bash
squeue --me --array
sacct --array -X -j 123456 --format=JobID%20,State%20,ExitCode,Elapsed
tail -n 20 slurm-123456_1.out
```

`PENDING` means waiting; `RUNNING` means executing. Wait for `COMPLETED` with exit code `0:0` in `sacct`. An empty queue alone does not prove success. Logs appear after a task starts, and accounting can take a moment to update.

The log should report 1,000 saved repetitions, and `results/123456/task-001.rds` should exist. For a failed job, read its log before retrying; `TIMEOUT` or `OUT_OF_MEMORY` may require a higher `--time` or `--mem` in `submit.sh`.

### Submit the full array

After the test succeeds, run in the same **SSH terminal**:

```bash
sbatch submit.sh
```

Record the **new job ID** and repeat the checks above with it. All five tasks should be `COMPLETED` with exit code `0:0`. Expect `task-001.rds` through `task-005.rds` in `results/NEW_JOB_ID/`, plus matching Slurm logs. Leave uploaded files unchanged until all tasks finish.

### Download and open results

In your **local terminal**, use your OS block below. Replace the example path and `YOUR_HPC_USERNAME`, and use your **full array's job ID** in place of `123456`. Use the same login host as for uploading. Wait for the result download to succeed before copying its logs.

<details>
<summary>macOS</summary>

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r/r/job-001"
mkdir -p results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/results/123456 ./results/
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/slurm-123456_*.out" ./results/123456/
ls ./results/123456
```

</details>

<details>
<summary>Linux</summary>

```bash
cd "/home/YOUR_NAME/path/to/minimal-hpc-r/r/job-001"
mkdir -p results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/results/123456 ./results/
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/slurm-123456_*.out" ./results/123456/
ls ./results/123456
```

</details>

<details>
<summary>Windows</summary>

```powershell
cd "C:/path/to/minimal-hpc-r/r/job-001"
New-Item -ItemType Directory -Force results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/results/123456 ./results/
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/slurm-123456_*.out" ./results/123456/
Get-ChildItem ./results/123456
```

</details>

The local `results/123456` folder now holds results and matching logs. Repeated downloads replace matching local files, so keep edited data separately. Results and logs are ignored by Git: back them up with the code version used for the run.

In your **local R console**, still working in the `r` folder, replace `123456` and read a result:

```r
result <- readRDS("job-001/results/123456/task-001.rds")
stopifnot(nrow(result) == 1000L)
head(result)
```

### Cancel or retry a task

In the **SSH terminal**, `scancel 123456` stops a submission; `scancel 123456_3` stops only task 3. Check `squeue --me --array` to confirm it stopped. Existing results and logs remain.

Wait for other tasks using the same files to finish before editing them. After fixing the error and uploading changes, resubmit task 3 from the job folder with `sbatch --array=3 submit.sh`. This creates a **new job ID and results folder**.

More detail: [GWDG job arrays](https://docs.hpc.gwdg.de/how_to_use/slurm/job_array/index.html) · [Slurm commands](https://docs.hpc.gwdg.de/how_to_use/slurm/index.html).
