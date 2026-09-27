# Connect to the GWDG HPC from macOS

You need an HPC project account and its cluster username. See [GWDG account setup](https://docs.hpc.gwdg.de/start_here/getting_an_account/index.html) if you do not have access yet.

- [Download the examples](#1-download-the-examples)
- [Connect to the cluster](#2-connect-to-the-cluster)
- [Choose your language](#3-choose-your-language)
- Transfer reference: [upload](#upload-code-and-data) · [download](#download-results)

## 1. Download the examples

Download [this repository](https://github.com/jobrachem/hpc-minimal) with **Code → Download ZIP** and extract it. Rename the folder to `minimal-hpc-r`; it should contain `README.md`, `guides`, `r`, and `py`.

Replace `/Users/YOUR_NAME/path/to/minimal-hpc-r` in the commands below with its location on your computer. The separate cluster copy will live at `~/minimal-hpc-r`.

## 2. Connect to the cluster

Open **Terminal** from Applications → Utilities. macOS includes SSH; these commands work in its default zsh shell and in Bash. For help, see [GWDG's SSH client instructions](https://docs.hpc.gwdg.de/start_here/connecting/install_ssh/index.html).

Run commands labelled **local terminal** on your own computer, outside SSH. Commands labelled **SSH terminal** run on the cluster. Neither belongs in an R console or notebook cell.

### Set up your key once

Skip this subsection if SSH access already works. In your **local terminal**:

```bash
ssh-keygen -t ed25519
```

Accept the default location and choose a passphrase. If asked to overwrite an existing key, answer `n` and check your existing setup. In `~/.ssh/`, `id_ed25519` is private: keep it on your computer. Display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire line. Sign in to [Academic Cloud](https://academiccloud.de/) with the account linked to your HPC project. Go to **Profile → Security → SSH Public Keys → Add** and paste it. Synchronization can take a few minutes; see the [illustrated instructions](https://docs.hpc.gwdg.de/start_here/connecting/upload_ssh_key/index.html).

### Log in

In your **local terminal**, replace `YOUR_HPC_USERNAME` with your cluster username, such as `u12345`:

```bash
ssh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de
```

Before accepting a new host with `yes`, compare its fingerprint with [GWDG's fingerprint table](https://docs.hpc.gwdg.de/start_here/connecting/login_nodes_and_example_commands/index.html#ssh-key-fingerprints). Enter your key's passphrase if prompted.

This guide uses **SCC CPU jobs on Emmy Phase 3**. For other islands or legacy access requiring VPN/a jump host, follow the [GWDG login guide](https://docs.hpc.gwdg.de/start_here/connecting/login_nodes_and_example_commands/index.html) and use the same chosen host for file transfers.

After login, this is your **SSH terminal**. A few useful commands:

| Command | Purpose |
| --- | --- |
| `pwd` | Show the current folder |
| `ls` | List files |
| `cd folder` | Move into a folder; `cd ..` moves up |
| `exit` | Disconnect |

The login node is for setup and submission. Run simulations through **Slurm**, which assigns compute resources. Submitted jobs continue after you disconnect.

## 3. Choose your language

Keep the SSH terminal open and open a second **local Terminal** window. Follow one walkthrough to completion:

- [R: local test → cluster setup → jobs and results](../r/README.md)
- [Python: local test → cluster setup → jobs and results](../py/README.md)

The sections below are transfer references. Your language walkthrough links to them when needed.

## Upload code and data

Save your local edits first. **SSH terminal:** create the destination for your language:

```bash
# R:
mkdir -p ~/minimal-hpc-r/r/job-001
# Python:
mkdir -p ~/minimal-hpc-r/py/job-001
```

**Local terminal:** enter the repository folder:

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r"
```

Replace `YOUR_HPC_USERNAME` and copy the files for your language.

**R:**

```bash
scp ./r/job-001/run.R ./r/job-001/submit.sh YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

**Python:**

```bash
scp ./py/job-001/run.ipynb ./py/job-001/submit.sh ./py/job-001/pyproject.toml ./py/job-001/uv.lock YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/
```

Wait for the command to finish and check for transfer errors. Recreate Python's `.venv` on the cluster; do not upload it. Save `.sh` files with **LF / Unix line endings**.

### Include your own data

Put small input files in a `data` folder inside the job folder. Copy it with `scp -r` (replace `r` with `py` for Python):

```bash
scp -r ./r/job-001/data YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/
```

For large datasets, choose storage using the [GWDG storage guide](https://docs.hpc.gwdg.de/how_to_use/storage_systems/index.html). Run `show-quota` in SSH to check your limits.

`scp` replaces matching destination files. Repeat the upload after editing, but leave files used by queued or running jobs unchanged until they finish.

Continue in your language walkthrough: [R](../r/README.md#load-r) · [Python](../py/README.md#create-the-cluster-environment).

## Download results

Use the completed submission's job ID in place of `123456`. In your **local terminal**, enter the repository folder:

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r"
```

Run the block for your language. Wait for the result download to succeed before copying its logs.

**R:**

```bash
mkdir -p ./r/job-001/results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/results/123456 ./r/job-001/results/
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/r/job-001/slurm-123456_*.out" ./r/job-001/results/123456/
ls ./r/job-001/results/123456
```

**Python:**

```bash
mkdir -p ./py/job-001/results
scp -r YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/results/123456 ./py/job-001/results/
scp "YOUR_HPC_USERNAME@glogin-p3.hpc.gwdg.de:minimal-hpc-r/py/job-001/slurm-123456_*.out" ./py/job-001/results/123456/
ls ./py/job-001/results/123456
```

The local `results/123456` folder now holds results and matching logs. Repeated downloads replace matching local files, so keep edited data separately. Results and logs are ignored by Git: back them up with the code version used for the run.

Continue with [R results](../r/README.md#download-and-open-results) or [Python results](../py/README.md#download-and-open-results).
