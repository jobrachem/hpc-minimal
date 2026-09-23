# Minimal Example for an R Simulation Study on the GWDG HPC

This repository shows how to run a simulation study with R on the GWDG High Performance Cluster.

This guide covers the following topics:

1. Set up your basic workflow (which tools to use, how to log in, how to work on the server)
2. Set up your R environment on the server
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

## Set up your R environment on the server

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

