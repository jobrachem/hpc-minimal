# Sync code with Git

Edit and test locally, save a version with Git, push it to GitHub, then pull that version on the cluster:

```text
Local computer -- commit + push --> GitHub -- pull --> Cluster
```

This replaces the code uploads in [step 4](README.md#4-upload-your-code-and-data) and the language guides. Continue using `scp` for input data and for [downloading results](README.md#8-download-the-results). GitLab works the same way if you substitute your repository's clone URL; no repository mirroring is needed.

## Set up once

Check `git --version` in both **local PowerShell** and the **SSH terminal**. If Git is missing locally, install [Git for Windows](https://gitforwindows.org/) and reopen PowerShell.

You need a repository you can push to. For this example, use **Fork** on [the GitHub repository](https://github.com/jobrachem/hpc-minimal) to create your own copy. Replace `YOUR_GITHUB_USERNAME` below with your GitHub username. A fork of this public repository is public too: use a separate private repository for private research code.

The clone commands need a missing or empty destination folder. If you already have files there, keep that folder as a backup under another name before cloning, then copy any edited source files into the new local clone. Wait for queued and running jobs to finish before moving the cluster folder. If you already cloned your own repository, reuse that clone instead; `git remote -v` shows which repository it uses.

In **local PowerShell**, from the parent folder where you want the project:

```powershell
git clone https://github.com/YOUR_GITHUB_USERNAME/hpc-minimal.git minimal-hpc-r
cd minimal-hpc-r
git config user.name "Your Name"
git config user.email "YOUR_GIT_EMAIL"
```

The name and email identify your commits; they are not login credentials. Use your GitHub-provided no-reply email if you prefer to keep your email private.

In the **SSH terminal**:

```bash
cd ~
git clone https://github.com/YOUR_GITHUB_USERNAME/hpc-minimal.git minimal-hpc-r
```

Public repositories can be cloned and pulled without signing in. Pushing, or reading a private repository, requires authentication on the machine running the command. For GitHub HTTPS authentication, follow the browser sign-in if offered; if Git asks for a password, enter a personal access token, not your account password. See [GitHub's authentication instructions](https://docs.github.com/en/get-started/git-basics/about-remote-repositories#cloning-with-https-urls). Keep tokens out of commands and repository files. Your cluster SSH login does not automatically authenticate you to GitHub.

## After editing locally

Save and test your changes, then run these commands in **local PowerShell**, from the repository root. This example stages the R code; for Python, replace the `git add` line with `git add py/job-001/run.ipynb py/job-001/submit.sh py/job-001/pyproject.toml py/job-001/uv.lock`.

```powershell
git status
git diff
git add r/job-001/run.R r/job-001/submit.sh
git diff --cached
git commit -m "Update simulation settings"
git push
git rev-parse --short HEAD
```

`git add` selects files for the next commit; `git diff --cached` lets you review that selection. A commit saves the version locally; a successful push makes it available on GitHub. Add any other intended source files explicitly. Keep credentials, large or sensitive datasets, and generated outputs out of commits; clear notebook outputs before staging. This repository already ignores job results, Slurm logs, and `.venv` folders.

## Before submitting on the cluster

Wait until jobs using this checkout have finished, then run in the **SSH terminal**:

```bash
cd ~/minimal-hpc-r
git status
git pull --ff-only
git rev-parse --short HEAD
```

Keep both clones on the same branch. After a successful pull, the printed commit ID should match the local one; record it with your job ID. Then continue with [step 5](README.md#5-prepare-the-cluster-environment) for the first run, or enter your job folder and submit as usual for later runs. Git transfers code and dependency files; environments still need to be prepared on the cluster.

Make source edits locally so the cluster copy stays clean. If `git status` shows unexpected changes, preserve and review them before pulling. If a push is rejected or a pull fails, stop and resolve the reported problem before submitting; do not force-push or discard files to bypass it. [`--ff-only`](https://git-scm.com/docs/git-pull) stops if the branches have diverged instead of creating a merge on the server.
