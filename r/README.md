# Run an R simulation on the GWDG HPC

Use the [numbered main walkthrough](../README.md) to download the files and set up SSH first. This guide supplies the R steps in that walkthrough; keep the main page open and use the return links at the end of each stage.

Local PowerShell commands use the repository root unless stated otherwise. The interactive R example uses the `r` folder; batch jobs run from `r/job-001` on the cluster.

## Table of contents

- [Prepare and test locally](#prepare-and-test-locally)
  - [Understand the example](#understand-the-example)
  - [Try the script in your local R console](#try-the-script-in-your-local-r-console)
- [Test your R environment on the server](#test-your-r-environment-on-the-server)
  - [Choose and load an R version](#choose-and-load-an-r-version)
  - [Check that R works](#check-that-r-works)
  - [Reuse the same setup](#reuse-the-same-setup)
- [Install R packages on the server](#install-r-packages-on-the-server)
  - [Prepare a personal package library](#prepare-a-personal-package-library)
  - [Install and check a package](#install-and-check-a-package)
  - [Make packages available to your jobs](#make-packages-available-to-your-jobs)
- [Submit an R job (as a job array)](#submit-an-r-job-as-a-job-array)
  - [Check the submission script](#check-the-submission-script)
  - [Submit one task first](#submit-one-task-first)
  - [Submit the full array](#submit-the-full-array)

## Prepare and test locally

This is the R part of **step 3** in the main walkthrough. Use your usual R console on your own computer.

### Understand the example

[`job-001/run.R`](job-001/run.R) simulates sample means from a normal distribution with mean 0 and standard deviation 1. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000, respectively. Each task performs 1,000 repetitions and saves a data frame containing the task number, repetition, sample size, and sample mean.

The script uses only base R, so you do not need to install additional packages on the cluster. Each task uses its number as a random seed, making repeat runs reproducible with the same R environment. This is deliberately a tiny teaching example; for a real study, give each task enough work to justify the scheduling overhead.

### Try the script in your local R console

In **R on your own computer**, set the working directory to the local `r` folder and source the script:

```r
setwd("C:/path/to/minimal-hpc-r/r")
source("job-001/run.R")
stopifnot(nrow(results) == 1000L)
head(results)
```

You can also run the script section by section in your editor. Its first block detects an interactive R session and sets `task_id <- 1` and `output_dir <- "job-001/results/local-test"`. Edit those defaults to try another task or output folder. The resulting `results` data frame stays in your R session for inspection, and a copy is saved to disk.

The script refuses to overwrite an existing result, so choose a fresh output folder when repeating a task. Under `Rscript` or Slurm, the script reads the task number and output folder from command-line arguments instead.

**Next:** return to [step 4: Upload your code and data](../README.md#4-upload-your-code-and-data). After checking the upload, step 5 sends you to the server setup below.

## Test your R environment on the server

GWDG provides ready-to-use R installations through **modules**. Loading a module makes a particular software version available in your terminal. Your Windows R installation and its packages are separate from the cluster installation.

Run all commands in this section **in the connected SSH terminal on the cluster**, unless marked as R commands.

### Choose and load an R version

First, find the available R versions:

```bash
module spider r
```

For details about one version, include its version number:

```bash
module spider r/4.5.2
```

The output tells you which other modules must be loaded first. R may require a **compiler**, which is also used to build some R packages when you install them later.

For example, the [GWDG R documentation](https://docs.hpc.gwdg.de/software_stacks/compilers_interpreters/r/index.html) currently lists R 4.5.2 with GCC 14.2.0 for Emmy CPU nodes. On the Emmy Phase 3 login described in the shared setup, load them in this order:

```bash
module load gcc/14.2.0
module load r/4.5.2
```

If that version is unavailable, choose one listed by `module spider r` and follow its prerequisite instructions. Keep the exact compiler and R module names you use: you will need the same pair for package installation and job submission.

### Check that R works

Still in the **SSH terminal**, run:

```bash
module list
Rscript --version
Rscript -e 'sessionInfo()'
```

`module list` shows the loaded modules. `Rscript --version` should report the R version you selected. The last command starts R, prints details about its version, platform, and loaded packages, then exits automatically. These small checks should finish within seconds.

[`Rscript`](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/Rscript.html) runs R code without an interactive console; `-e` supplies the code directly. Later, your batch script will use it to run an `.R` file. The module name is lowercase `r`, but the programs are named `R` and `Rscript`.

For a brief interactive check, start R from the SSH terminal:

```bash
R --no-save --no-restore
```

When the `>` prompt appears, you are **inside R**. Try these R commands:

```r
1 + 1
q(save = "no")
```

You should see `[1] 2`; `q()` then returns you to the Linux terminal. Use compute jobs for simulations, as described in the shared setup.

### Reuse the same setup

Load the same compiler and R modules each time you open a new SSH session. We will also put those two `module load` lines in the submission script so each job selects its R environment explicitly. Specifying versions keeps the choice stable if the cluster's defaults change. GWDG recommends loading modules in your session or batch script, rather than automatically in `.bashrc`; see [Module Basics](https://docs.hpc.gwdg.de/software_stacks/module_basics/index.html).

R is now available on the server. This example needs no extra packages: return to [step 6: Submit a test job](../README.md#6-submit-a-test-job). If your own code needs packages, complete the optional section below first.

## Install R packages on the server

Install the packages your experiment needs on the cluster, even if they are already installed on your Windows computer. If your code uses only base R, continue with [step 6: Submit a test job](../README.md#6-submit-a-test-job). The commands below use `digest` as an example; replace it with a package your experiment actually uses.

Run all commands below **in the SSH terminal on the cluster**.

### Prepare a personal package library

A **library** is a folder containing installed R packages. You can create one in your home directory without administrator permissions. First, load the same compiler and R modules you selected earlier:

```bash
module load gcc/14.2.0
module load r/4.5.2
```

GWDG requires packages with compiled code to use the same compiler as R itself; see its [R package instructions](https://docs.hpc.gwdg.de/software_stacks/compilers_interpreters/r/index.html#building-r-packages).

Choose a library folder and create it:

```bash
export R_LIBS_USER="$HOME/R/library-4.5.2-gcc-14.2.0"
mkdir -p "$R_LIBS_USER"
Rscript -e '.libPaths()'
```

`$HOME` is your home directory on the cluster. `export` makes the `R_LIBS_USER` setting available to R processes started from this terminal. The last command lists the folders R searches for packages; your new folder should appear there. The folder must exist **before R starts** to be included, as explained in the [R library documentation](https://stat.ethz.ch/R-manual/R-devel/library/base/html/libPaths.html).

If you selected different module versions, adjust the folder name to match. Keeping separate libraries avoids mixing packages built with different R or compiler versions.

### Install and check a package

In the **SSH terminal**, run:

```bash
Rscript -e 'install.packages("digest", lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org")'
```

This downloads the package and its required dependencies from CRAN into your personal library. Specifying `repos` avoids an interactive mirror-selection prompt. To install several packages, replace `"digest"` with a vector such as `c("digest", "withr")`. See [`install.packages()`](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/install.packages.html) for details.

Keep the terminal open and wait for installation to finish. Compilation can take several minutes. A warning about a **non-zero exit status** means an installation failed; inspect the preceding error message before proceeding. Missing system libraries may require additional modules or help from GWDG support.

Check the result in a fresh R process:

```bash
Rscript -e 'library(digest); packageVersion("digest")'
```

This should load the package and print its version without an error. If R cannot find it, check that you loaded the same modules and set `R_LIBS_USER` to the installation folder.

### Make packages available to your jobs

The installed files remain after you disconnect, but the `export` setting belongs to your current terminal session. Repeat it in each new session after loading the modules. We will include the same module commands and `export R_LIBS_USER=...` line in the submission script.

Install packages once before submitting jobs; inside your R script, load them with `library()`. Avoid installing or updating packages while jobs are using that library, especially when many job-array tasks run at once.

**Next:** return to [step 6: Submit a test job](../README.md#6-submit-a-test-job).

## Submit an R job (as a job array)

A **job array** runs the same script several times, giving each run a different task number. This works well for simulations where each task can calculate its results independently. You submit the array once, and Slurm schedules its tasks on compute nodes. See [GWDG's job-array guide](https://docs.hpc.gwdg.de/how_to_use/slurm/job_array/index.html).

### Check the submission script

Open [`job-001/submit.sh`](job-001/submit.sh) in your **local editor**. Lines beginning with `#SBATCH` tell Slurm what to request:

| Setting | Meaning |
| --- | --- |
| `--partition=scc-cpu` | Use the SCC CPU partition on Emmy Phase 3 |
| `--nodes=1`, `--ntasks=1`, `--cpus-per-task=1` | Run one R process with one CPU per array task |
| `--mem=1G` | Request 1 GiB of memory per array task |
| `--time=00:05:00` | Allow up to five minutes per array task |
| `--array=1-5%2` | Run tasks 1–5, with at most two running at once |
| `--output=slurm-%A_%a.out` | Give each task its own log, containing printed output and errors |

The partition must match your access; consult the [CPU partition table](https://docs.hpc.gwdg.de/how_to_use/compute_partitions/cpu_partitions/index.html) if you are not using SCC on Emmy Phase 3. Adjust the R/compiler modules and personal library path if you chose different versions earlier.

The script loads that environment, limits common numerical libraries to one thread, and runs:

```bash
Rscript run.R "$SLURM_ARRAY_TASK_ID" "results/$SLURM_ARRAY_JOB_ID"
```

Slurm supplies both variables: the first selects the sample size, and the second identifies this submission. An array with job ID `123456` writes `results/123456/task-001.rds` through `task-005.rds`. Each new submission gets its own folder, and the R script refuses to replace an existing result file. In log names, `%A` and `%a` stand for the array job ID and task number. See the [Slurm array reference](https://slurm.schedmd.com/job_array.html).

### Submit one task first

Save your edits and upload the current `run.R` and `submit.sh`. From **local PowerShell**, in the repository folder:

```powershell
scp .\r\job-001\run.R .\r\job-001\submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

Then, in the **SSH terminal**, submit only task 1:

```bash
cd ~/minimal-hpc-r/r/job-001
sbatch --array=1 submit.sh
```

The command-line option overrides the array range in the file. Slurm returns a message such as `Submitted batch job 123456`. This means the job was accepted, not that it has finished. Keep that number.

**Next:** return to [step 7: Check the test job](../README.md#7-check-the-test-job-and-run-the-full-array). The log should report that 1,000 repetitions were saved, and `results/JOB_ID/task-001.rds` should exist. Step 7 sends you back to **Submit the full array** below once this test succeeds.

### Submit the full array

After step 7 confirms that the single-task test succeeded, submit all five tasks in the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/r/job-001
sbatch submit.sh
```

Use `sbatch`, rather than `bash submit.sh`: it requests compute resources and supplies the array variables. Always submit from `~/minimal-hpc-r/r/job-001/`, because the script uses the submission directory to find `run.R` and write outputs. You can disconnect after submission; leave the uploaded code unchanged until all tasks finish.

**Next:** record the new job ID and return to [step 7](../README.md#7-check-the-test-job-and-run-the-full-array) to check all five tasks. Once they succeed, continue to [step 8: Download the results](../README.md#8-download-the-results), using the **R** paths and your full array's job ID.
