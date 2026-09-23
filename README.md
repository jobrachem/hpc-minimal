# Minimal HPC examples for R and Python

This repository introduces running simulation studies on the GWDG High Performance Cluster. The instructions assume a Windows computer and PowerShell for SSH and file transfers.

Follow the numbered steps below in order, choosing **R** or **Python** wherever the instructions branch. Keep this page open: each language-specific section tells you where to return. You only need to follow one language.

The [R guide](r/README.md) and [Python guide](py/README.md) contain the language-specific details. The Python guide covers Positron, VS Code, JupyterLab, and environment discovery settings.

```text
README.md              Shared cluster setup and commands
r/README.md            R walkthrough
r/job-001/             R simulation and submission script
py/README.md           Python/Jupyter walkthrough
py/job-001/            Notebook, submission script, and uv environment files
```

## Table of contents

- [1. Download the repository](#1-download-the-repository)
- [2. Set up SSH and connect](#2-set-up-ssh-and-connect)
- [3. Prepare and test locally](#3-prepare-and-test-locally)
- [4. Upload your code and data](#4-upload-your-code-and-data)
- [5. Prepare the cluster environment](#5-prepare-the-cluster-environment)
- [6. Submit a test job](#6-submit-a-test-job)
- [7. Check the test job and run the full array](#7-check-the-test-job-and-run-the-full-array)
- [8. Download the results](#8-download-the-results)
- [Related documentation](#related-documentation)

## 1. Download the repository

Download a ZIP of [this repository](https://github.com/jobrachem/hpc-minimal) using **Code → Download ZIP**, then extract it on your computer. Rename the extracted folder to `minimal-hpc-r` to match the commands in this walkthrough. It should contain `README.md`, `r`, and `py` directly inside it.

If you already use Git, you can clone it from **local PowerShell** instead:

```powershell
git clone https://github.com/jobrachem/hpc-minimal.git minimal-hpc-r
```

If you already have a local copy, use it. Replace `C:\path\to\minimal-hpc-r` in later commands with its actual location. We use `~/minimal-hpc-r` as the separate destination on the cluster. Keep the `r` and `py` subfolders in both copies.

## 2. Set up SSH and connect

You will work in two places: **on your Windows computer**, where you edit and test your code, and **on the cluster**, where you run larger simulations. Files are separate: after editing locally, you upload the changed files; after a simulation, you download the results.

### Prepare your tools

Keep using your usual editor or notebook application. For connecting to the cluster, open **PowerShell** from the Windows Start menu. This is a terminal: you type a command and press Enter to run it. The commands below belong in the terminal, not an R console or notebook cell.

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

The machine you log into is a shared **login node**, used to prepare files and submit work. Run simulations as jobs through **Slurm**, the scheduler that assigns work to compute nodes. A submitted batch job continues after you disconnect. The [cluster overview](https://docs.hpc.gwdg.de/start_here/using_the_cluster/index.html) explains this division.

## 3. Prepare and test locally

Keep the SSH terminal open. Open a second **local PowerShell** window for commands on your own computer; use your usual editor or notebook application for the code.

Choose your language:

- **R:** follow [Prepare and test locally](r/README.md#prepare-and-test-locally) through the local console example.
- **Python:** follow [Prepare your local Python environment](py/README.md#prepare-your-local-python-environment) and [Try the notebook on your computer](py/README.md#try-the-notebook-on-your-computer), including the local parameter-passing check. Choose one editor; adding packages is optional.

Save your code after the local run succeeds. Both guides return you to **step 4** below.

## 4. Upload your code and data

Use `scp` to copy files over SSH, using the same login details as before. Use the **local PowerShell** window you opened in step 3 for uploads; keep your **SSH terminal** open too. The local window can access the files on your Windows computer.

> **Note:** This guide shows an easy way to get started, but manually copying files is error-prone and can quickly become cumbersome. I **highly recommend using a GitHub repository** to version your experiment code and synchronize it between your local computer and the server: commit and push your changes locally, then pull them on the server.

Choose the R example in `r/job-001` or the Python example in `py/job-001` below. Both use the same source-and-destination pattern. Copy code and input files; recreate Python environments on the server instead of uploading `.venv`.

### Prepare the folders

In the **SSH terminal**, ensure the destination folder exists:

```bash
# For R:
mkdir -p ~/minimal-hpc-r/r/job-001
# For Python:
mkdir -p ~/minimal-hpc-r/py/job-001
```

In **local PowerShell**, move into your local copy of this repository. Replace the example path with its location on your computer; if you downloaded a ZIP, extract it first.

```powershell
cd "C:\path\to\minimal-hpc-r"
Get-ChildItem
```

You should see `README.md` and the `r` and `py` folders. Save any edits in your editor before uploading. If your simulation needs small input files, you can put them in a `data` folder inside your job folder and copy that folder separately.

This example uses your cluster home directory for a small project. Before uploading large datasets, choose suitable storage using the [GWDG storage guide](https://docs.hpc.gwdg.de/how_to_use/storage_systems/index.html). Run `show-quota` in the SSH terminal to see your storage locations and limits.

### Copy the job files

In **local PowerShell**, replace `YOUR_HPC_USERNAME` and run the command for your language.

**R:**

```powershell
scp .\r\job-001\run.R .\r\job-001\submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

**Python:**

```powershell
scp .\py\job-001\run.ipynb .\py\job-001\submit.sh .\py\job-001\pyproject.toml .\py\job-001\uv.lock YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/
```

Use the same hostname as for your SSH login. The local file paths come first: they are the sources. The server and remote folder come last: they are the destination. The colon separates the server from its path; this relative path starts in your remote home directory. Here, `.` means the current local directory.

This copies the selected files into the matching job folder on the cluster. Enter your key's passphrase if requested and wait for the PowerShell prompt to return. Check for error messages before continuing. See [GWDG's transfer instructions](https://docs.hpc.gwdg.de/how_to_use/data_transfer/index.html) for more examples.

If you added a `data` folder, copy it separately (replace `r` with `py` for Python) with `scp -r`, which copies a folder and its contents:

```powershell
scp -r .\r\job-001\data YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

### Check the uploaded files

Switch back to the **SSH terminal** and enter the job folder for your language. For R:

```bash
cd ~/minimal-hpc-r/r/job-001
ls -lh
```

For Python:

```bash
cd ~/minimal-hpc-r/py/job-001
ls -lh
```

For R, expect `run.R` and `submit.sh`. For Python, expect `run.ipynb`, `submit.sh`, `pyproject.toml`, and `uv.lock`. Also check any input folders you added.

After changing a file locally, upload it again from **local PowerShell**, still in the repository folder. For example:

```powershell
scp .\r\job-001\run.R YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

`scp` replaces files with the same destination name without asking. Upload only the files you intend to update, and keep files used by queued or running jobs unchanged until those jobs finish. Uploading copies files; it does not run your code.

Continue with **step 5** below once the files are present.

## 5. Prepare the cluster environment

Switch to the **SSH terminal** and follow the section for your language:

- **R:** [Test your R environment on the server](r/README.md#test-your-r-environment-on-the-server), then [Install R packages on the server](r/README.md#install-r-packages-on-the-server) if your code needs extra packages. This example uses only base R, so package installation is optional.
- **Python:** [Prepare the environment on SCC](py/README.md#prepare-the-environment-on-scc).

Wait for setup to finish successfully. Both guides return you to **step 6** below.

## 6. Submit a test job

Follow your language's submission section to review `submit.sh`, upload any edits, and submit **only task 1**:

- **R:** [Submit an R job](r/README.md#submit-an-r-job-as-a-job-array), through **Submit one task first**.
- **Python:** [Submit the notebook as a job array](py/README.md#submit-the-notebook-as-a-job-array), through **Submit one task first**.

Record the job ID printed by `sbatch`, then return to **step 7** below. Wait for that test job to succeed before submitting the full array.

## 7. Check the test job and run the full array

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

Depending on the cluster's output format, the state column is called `STATE` or `ST`. It shows `PENDING` (or `PD`) for tasks waiting to start, `RUNNING` (or `R`) for running tasks, and `COMPLETING` (or `CG`) while a task finishes up. Long labels may be truncated. The `NODELIST(REASON)` column shows the compute node or why a task is waiting. `Resources` and `Priority` are normal waiting reasons; `JobArrayTaskLimit` means the array has reached its concurrency limit, set by the `%` limit in the submission script. Check again later rather than submitting another copy. See [Slurm's reason codes](https://slurm.schedmd.com/job_reason_codes.html).

### Read a task's log

In the job folder from which you submitted the job (`~/minimal-hpc-r/r/job-001` or `~/minimal-hpc-r/py/job-001`), inspect the last 20 lines of task 1's log:

```bash
tail -n 20 slurm-123456_1.out
```

For the full log, use `less slurm-123456_1.out` and press `q` to close it. Change `_1` to the task number you want to inspect. Logs normally appear after a task starts, so a pending task may not have one yet. The language guide explains what a successful run should produce.

### Confirm that every task finished successfully

Completed and failed jobs disappear from `squeue`. An empty queue therefore does **not** prove success. Look up the recorded outcome with `sacct`:

```bash
sacct --array -X -j 123456 --format=JobID%20,State%20,ExitCode,Elapsed
```

`-X` hides the extra records for internal job steps. Check every task you submitted: all five rows for either example's full array, or just task 1 for its initial test. Each should show `COMPLETED` and exit code `0:0`, meaning the job script exited successfully without a terminating signal. `Elapsed` is the runtime. Accounting records can take a little time to update; if a just-finished task is missing, check again shortly. See the [`sacct` reference](https://slurm.schedmd.com/sacct.html).

| Final state | What to do |
| --- | --- |
| `COMPLETED` | Check the expected result file and its contents |
| `FAILED` | Read the task's log for the error |
| `TIMEOUT` | Review the workload and requested `--time` |
| `OUT_OF_MEMORY` | Review memory use and requested `--mem` |
| `CANCELLED` | The task was stopped before normal completion |

These are [Slurm job states](https://slurm.schedmd.com/job_state_codes.html).

Also check the expected output files listed in your language guide. For a submission that writes to `results/123456/`:

```bash
ls -lh results/123456/
```

### Continue after a successful run

For the **single-task test**, expect `task-001.rds` for R or `task-001.csv` for Python, containing 1,000 rows. The Slurm log should report a successful run. If you enabled executed Python notebooks, expect `task-001.ipynb` too.

Once task 1 is `COMPLETED` with exit code `0:0` and its output is correct, follow **Submit the full array** in the [R guide](r/README.md#submit-the-full-array) or [Python guide](py/README.md#submit-the-full-array). Record the **new job ID**, then return to the [start of step 7](#7-check-the-test-job-and-run-the-full-array) and repeat the checks for all five tasks.

Once the **full array** succeeds, expect five result files, `task-001` through `task-005`, with the extension for your language. Continue to [step 8](#8-download-the-results). Use the troubleshooting section below only if you need to stop or retry a job.

### Cancel or retry a task

If you need to stop an entire submission, cancel its pending and running tasks with:

```bash
scancel 123456
```

To cancel only task 3, use `scancel 123456_3`. Check `squeue` again to confirm it has stopped. Cancellation does not remove existing logs or results. See [GWDG's job-control commands](https://docs.hpc.gwdg.de/how_to_use/slurm/index.html#important-slurm-commands).

After fixing an error and uploading any changes, you can resubmit only task 3 from the same job folder with `sbatch --array=3 submit.sh`. This creates a **new job ID and results folder**; keep track of both submissions when collecting results. Wait for other tasks using the same files to finish before changing the code.

## 8. Download the results

Once all submitted tasks have completed successfully, copy their results to your Windows computer. The commands below use `123456` as the **full array's job ID**, not the earlier single-task test. Replace it, `YOUR_HPC_USERNAME`, and the example local path with your own values.

Choose the command block for your language below. Both download into the matching local job folder.

### Copy results and logs to Windows

Open **local PowerShell**, outside the SSH session, and move into your local repository folder. For **R**:

```powershell
cd "C:\path\to\minimal-hpc-r"
New-Item -ItemType Directory -Force .\r\job-001\results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/results/123456 .\r\job-001\results\
```

`New-Item` ensures the local results folder exists. `scp` downloads the files. This time the remote path comes first: it is the source, and the local folder is the destination. The download creates `r\job-001\results\123456` on your computer. Use the same hostname as for your SSH login, enter your key's passphrase if requested, and wait for the prompt to return. Check for transfer errors. See [GWDG's download examples](https://docs.hpc.gwdg.de/how_to_use/data_transfer/index.html#data-transfers-connecting-from-the-outside-world).

After the result download succeeds, copy the matching logs into that folder too:

```powershell
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/slurm-123456_*.out" .\r\job-001\results\123456\
Get-ChildItem .\r\job-001\results\123456
```

For **Python**, use these paths for the result folder and logs instead:

```powershell
cd "C:\path\to\minimal-hpc-r"
New-Item -ItemType Directory -Force .\py\job-001\results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/results/123456 .\py\job-001\results\
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/slurm-123456_*.out" .\py\job-001\results\123456\
Get-ChildItem .\py\job-001\results\123456
```

Wait for the result download to succeed before copying its logs.

The `*` matches all task numbers for this submission. You should now have the result files and matching logs; the R example produces five `.rds` files, and Python produces five `.csv` files, plus executed `.ipynb` notebooks only if you enabled saving. Repeating a download replaces local files with matching names, so keep your downloaded originals separate from edited or processed data. The cluster copies remain in place.

Keep the results, logs, and the code version used for the run together in your research records. This repository ignores generated results and logs in Git, so pushing your code to GitHub does **not** back them up.

## Related documentation

- Official documentation: https://docs.hpc.gwdg.de/
- Basic tutorials: https://github.com/jonaden94/hpc_guide
- Opinionated experimentation workflow: https://github.com/jobrachem/hpc
- Cheat sheet for Linux commands: https://github.com/RehanSaeed/Bash-Cheat-Sheet
