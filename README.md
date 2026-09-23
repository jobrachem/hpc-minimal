# Minimal Example for an R Simulation Study on the GWDG HPC

This repository shows how to run a simulation study with R on the GWDG High Performance Cluster.

This guide covers the following topics:

1. Set up your basic workflow (which tools to use, how to log in, how to work on the server)
2. Test your R environment on the server
3. Upload your code and data to the server
4. Install R packages on the server
5. Submit an R job (as a job array)
6. Check the status of your job
7. Download the data saved by your job.

## Related documentation

- Official documentation: https://docs.hpc.gwdg.de/
- Basic tutorials: https://github.com/jonaden94/hpc_guide
- Opinionated experimentation workflow: https://github.com/jobrachem/hpc
- Cheat sheet for Linux commands: https://github.com/RehanSaeed/Bash-Cheat-Sheet


## Set up your basic workflow

You will work in two places: **on your Windows computer**, where you edit and test your R code, and **on the cluster**, where you run larger simulations. Files are separate: after editing locally, you upload the changed files; after a simulation, you download the results.

### Prepare your tools

Keep using your usual editor, such as RStudio. For connecting to the cluster, open **PowerShell** from the Windows Start menu. This is a terminal: you type a command and press Enter to run it. The commands below belong in the terminal, not the R console.

In PowerShell, check that SSH is available:

```powershell
ssh -V
```

If this prints a version number, you are ready. If Windows cannot find the command, install **OpenSSH Client** through Windows Optional Features; see [GWDG's Windows instructions](https://docs.hpc.gwdg.de/start_here/connecting/install_ssh/index.html#windows). SSH opens a terminal on the cluster. The accompanying `scp` tool copies files between your computer and the cluster; we will use it later.

### Set up your login once

If SSH access already works from this computer, skip to the next step. Otherwise, create an SSH key in **local PowerShell**:

```powershell
ssh-keygen -t ed25519
```

Press Enter to accept the default file location, then choose a passphrase to protect the key. If asked to overwrite an existing key, answer `n` and check your existing setup first. The default files are in `C:\Users\YOUR_WINDOWS_NAME\.ssh\`: `id_ed25519` is private and stays on your computer; `id_ed25519.pub` is public and can be uploaded. See [GWDG's key-generation guide](https://docs.hpc.gwdg.de/start_here/connecting/generate_ssh_key/index.html).

Display the public key in PowerShell:

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

Copy the entire output line. Sign in to [Academic Cloud](https://academiccloud.de/) with the account linked to your HPC project, then go to **Profile → Security → SSH Public Keys → Add** and paste it. Synchronization can take a few minutes. The [illustrated upload guide](https://docs.hpc.gwdg.de/start_here/connecting/upload_ssh_key/index.html) shows the steps.

### Connect to the cluster

In **local PowerShell**, run the following, replacing `YOUR_HPC_USERNAME` with your cluster username (often a project-specific name such as `u12345`, not your email address or Windows username):

```powershell
ssh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de
```

This is the recommended login for SCC CPU jobs. If your project uses another cluster island, choose its hostname from the [GWDG login guide](https://docs.hpc.gwdg.de/start_here/connecting/login_nodes_and_example_commands/index.html). Legacy SCC access from outside the campus network requires VPN or a jump host; the same guide explains this.

On your first connection, compare the displayed host fingerprint with the guide's **SSH key fingerprints** table before accepting it with `yes`. Enter your key's passphrase if prompted; nothing appears while you type it.

Once the welcome message appears, this terminal runs commands **on the cluster**. Your local editor still works on your Windows files.

### Find your way around

The cluster uses Linux. Run these commands **in the connected SSH terminal**, one line at a time:

```bash
pwd
ls
mkdir -p ~/minimal-hpc-r
cd ~/minimal-hpc-r
```

`pwd` shows your current directory (folder); `ls` lists its contents. `mkdir -p` creates a directory if needed, and `cd` moves into it. Here, `~` means your home directory on the cluster.

| Command | Purpose |
| --- | --- |
| `cd ..` | Move up one directory |
| `cd ~` | Return to your home directory |
| `ls -lh` | List files with readable sizes |
| `less filename` | Read a text file; press `q` to close it |
| `exit` | Disconnect and return to local PowerShell |

Linux paths use `/`, and names are case-sensitive: `run.R` and `run.r` are different files. Tab completes names; the up arrow recalls previous commands. Save shell scripts (`.sh`) with **LF / Unix line endings** in your editor so they run correctly on Linux.

The machine you log into is a shared **login node**, used to prepare files and submit work. Run simulations as jobs through **Slurm**, the scheduler that assigns work to compute nodes. A submitted batch job continues after you disconnect. The [cluster overview](https://docs.hpc.gwdg.de/start_here/using_the_cluster/index.html) explains this division; the following sections cover the R environment, file transfers, and job submission.

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

For example, the [GWDG R documentation](https://docs.hpc.gwdg.de/software_stacks/compilers_interpreters/r/index.html) currently lists R 4.5.2 with GCC 14.2.0 for Emmy CPU nodes. On the Emmy Phase 3 login used above, load them in this order:

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

You should see `[1] 2`; `q()` then returns you to the Linux terminal. Use compute jobs for simulations, as described above.

### Reuse the same setup

Load the same compiler and R modules each time you open a new SSH session. We will also put those two `module load` lines in the submission script so each job selects its R environment explicitly. Specifying versions keeps the choice stable if the cluster's defaults change. GWDG recommends loading modules in your session or batch script, rather than automatically in `.bashrc`; see [Module Basics](https://docs.hpc.gwdg.de/software_stacks/module_basics/index.html).

R is now available on the server. After uploading the project files, we will install any additional R packages there.

## Upload your code and data to the server

Use `scp` to copy files over SSH, using the same login details as before. Keep your **SSH terminal** open and open a second, **local PowerShell** window for uploads. The local window can access the files on your Windows computer.

> **Note:** This guide shows an easy way to get started, but manually copying files is error-prone and can quickly become cumbersome. I **highly recommend using a GitHub repository** to version your experiment code and synchronize it between your local computer and the server: commit and push your changes locally, then pull them on the server.

### Prepare the folders

In the **SSH terminal**, ensure the destination folder exists:

```bash
mkdir -p ~/minimal-hpc-r
```

In **local PowerShell**, move into your local copy of this repository. Replace the example path with its location on your computer; if you downloaded a ZIP, extract it first.

```powershell
cd "C:\path\to\minimal-hpc-r"
Get-ChildItem
```

You should see `README.md` and the `job-001` folder. Save any edits in your editor before uploading. If your simulation needs small input files, you can put them in a `data` folder inside `job-001` so they travel with the code.

This example uses your cluster home directory for a small project. Before uploading large datasets, choose suitable storage using the [GWDG storage guide](https://docs.hpc.gwdg.de/how_to_use/storage_systems/index.html). Run `show-quota` in the SSH terminal to see your storage locations and limits.

### Copy the job folder

In **local PowerShell**, replace `YOUR_HPC_USERNAME` and run:

```powershell
scp -r .\job-001 YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/
```

Use the same hostname as for your SSH login. The command has three parts:

- `-r` copies a folder and everything inside it.
- `.\job-001` is the source folder on your Windows computer; `.` means the current directory.
- `YOUR_HPC_USERNAME@…:minimal-hpc-r/` is the destination on the cluster. The colon separates the server from its path; this relative path starts in your remote home directory.

This creates `~/minimal-hpc-r/job-001` on the cluster. Enter your key's passphrase if requested and wait for the PowerShell prompt to return. Check for error messages before continuing. See [GWDG's transfer instructions](https://docs.hpc.gwdg.de/how_to_use/data_transfer/index.html) for more examples.

### Check the uploaded files

Switch back to the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/job-001
ls -lh
```

You should see `run.R`, `submit.sh`, and `download.sh`, plus any input folders you added. 

After changing a file locally, upload it again from **local PowerShell**, still in the repository folder. For example:

```powershell
scp .\job-001\run.R YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/job-001/
```

`scp` replaces files with the same destination name without asking. Upload only the files you intend to update, and keep files used by queued or running jobs unchanged until those jobs finish. Uploading copies files; it does not run your code.

## Install R packages on the server

Install the packages your experiment needs on the cluster, even if they are already installed on your Windows computer. If your code uses only base R, you can skip this section. The commands below use `digest` as an example; replace it with a package your experiment actually uses.

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

## Submit an R job (as a job array)

A **job array** runs the same script several times, giving each run a different task number. This works well for simulations where each task can calculate its results independently. You submit the array once, and Slurm schedules its tasks on compute nodes. See [GWDG's job-array guide](https://docs.hpc.gwdg.de/how_to_use/slurm/job_array/index.html).

### Understand the example

[`job-001/run.R`](job-001/run.R) simulates sample means from a normal distribution with mean 0 and standard deviation 1. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000, respectively. Each task performs 1,000 repetitions and saves a data frame containing the task number, repetition, sample size, and sample mean.

The script uses only base R, so you do not need to install the example packages from the previous section. Each task uses its number as a random seed, making repeat runs reproducible with the same R environment. This is deliberately a tiny teaching example; for a real study, give each task enough work to justify the scheduling overhead.

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
scp .\job-001\run.R .\job-001\submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/job-001/
```

Then, in the **SSH terminal**, submit only task 1:

```bash
cd ~/minimal-hpc-r/job-001
sbatch --array=1 submit.sh
```

The command-line option overrides the array range in the file. Slurm returns a message such as `Submitted batch job 123456`. This means the job was accepted, not that it has finished. Keep that number.

Once the task finishes, inspect `slurm-123456_1.out` using `less`, replacing `123456` with your job ID. It should report that 1,000 repetitions were saved, and `results/123456/task-001.rds` should exist. Resolve any errors before submitting the full array.

### Submit the full array

From the same **SSH terminal and directory**, run:

```bash
sbatch submit.sh
```

Use `sbatch`, rather than `bash submit.sh`: it requests compute resources and supplies the array variables. Always submit from `job-001/`, because the script uses the submission directory to find `run.R` and write outputs. You can disconnect after submission; leave the uploaded code unchanged until all tasks finish.

## Check the status of your job

Run these commands **in the SSH terminal on the cluster**. Replace `123456` with the job ID returned by `sbatch`; your single-task test and full array have different IDs.

### Check the queue

To see your queued and running tasks:

```bash
squeue --me --array
```

`--array` displays each array task on its own line. For just one submission, use:

```bash
squeue --array --jobs=123456
```

In the `ST` column, `PD` means pending (waiting to start), `R` means running, and `CG` means completing. The `NODELIST(REASON)` column shows the compute node or why a task is waiting. `Resources` and `Priority` are normal waiting reasons; `JobArrayTaskLimit` means the array has reached its concurrency limit, which our script sets to two. Check again later rather than submitting another copy. See [Slurm's reason codes](https://slurm.schedmd.com/job_reason_codes.html).

### Read a task's log

From the job folder, inspect the last 20 lines of task 1's log:

```bash
cd ~/minimal-hpc-r/job-001
tail -n 20 slurm-123456_1.out
```

For the full log, use `less slurm-123456_1.out` and press `q` to close it. Change `_1` to the task number you want to inspect. Logs normally appear after a task starts, so a pending task may not have one yet. Our R script prints a `Saved 1000 repetitions to ...` message after writing its result file.

### Confirm that every task finished successfully

Completed and failed jobs disappear from `squeue`. An empty queue therefore does **not** prove success. Look up the recorded outcome with `sacct`:

```bash
sacct --array -X -j 123456 --format=JobID%20,State%20,ExitCode,Elapsed
```

`-X` hides the extra records for internal job steps. Check all five task rows for the full array, or just task 1 for the initial test. Each should show `COMPLETED` and exit code `0:0`, meaning the job script exited successfully without a terminating signal. `Elapsed` is the runtime. Accounting records can take a little time to update; if a just-finished task is missing, check again shortly. See the [`sacct` reference](https://slurm.schedmd.com/sacct.html).

| Final state | What to do |
| --- | --- |
| `COMPLETED` | Check the expected result file and its contents |
| `FAILED` | Read the task's log for the error |
| `TIMEOUT` | Review the workload and requested `--time` |
| `OUT_OF_MEMORY` | Review memory use and requested `--mem` |
| `CANCELLED` | The task was stopped before normal completion |

These are [Slurm job states](https://slurm.schedmd.com/job_state_codes.html). Successful execution does not establish that the scientific results are correct; inspect the downloaded data too.

For the full array, confirm that its output folder contains `task-001.rds` through `task-005.rds`:

```bash
ls -lh results/123456/
```

### Cancel or retry a task

If you need to stop an entire submission, cancel its pending and running tasks with:

```bash
scancel 123456
```

To cancel only task 3, use `scancel 123456_3`. Check `squeue` again to confirm it has stopped. Cancellation does not remove existing logs or results. See [GWDG's job-control commands](https://docs.hpc.gwdg.de/how_to_use/slurm/index.html#important-slurm-commands).

After fixing an error and uploading any changes, you can resubmit only task 3 from `job-001/` with `sbatch --array=3 submit.sh`. This creates a **new job ID and results folder**; keep track of both submissions when collecting results. Wait for other tasks using the same files to finish before changing the code.
