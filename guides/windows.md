# Connect to the GWDG HPC from Windows

You need an HPC project account and its cluster username. See [GWDG account setup](https://docs.hpc.gwdg.de/start_here/getting_an_account/index.html) if you do not have access yet.

- [Download the examples](#1-download-the-examples)
- [Connect to the cluster](#2-connect-to-the-cluster)
- [Choose your language](#3-choose-your-language)

## 1. Download the examples

Download [this repository](https://github.com/jobrachem/hpc-minimal) with **Code → Download ZIP** and extract it. Rename the folder to `minimal-hpc-r`; it should contain `README.md`, `guides`, `r`, and `py`.

## 2. Connect to the cluster

Open **PowerShell** from the Start menu. If `ssh -V` is not found, install **OpenSSH Client** through Windows Optional Features. For help, see [GWDG's SSH client instructions](https://docs.hpc.gwdg.de/start_here/connecting/install_ssh/index.html).

Run commands labelled **local terminal** on your own computer, outside SSH. Commands labelled **SSH terminal** run on the cluster. Neither belongs in an R console or notebook cell.

### Set up your key once

Skip this subsection if SSH access already works. In your **local terminal**:

```powershell
ssh-keygen -t ed25519
```

Accept the default location and choose a passphrase. If asked to overwrite an existing key, answer `n` and check your existing setup. In `C:\Users\YOUR_NAME\.ssh\`, `id_ed25519` is private: keep it on your computer. Display the public key:

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

Copy the entire line. Sign in to [Academic Cloud](https://academiccloud.de/) with the account linked to your HPC project. Go to **Profile → Security → SSH Public Keys → Add** and paste it. Synchronization can take a few minutes; see the [illustrated instructions](https://docs.hpc.gwdg.de/start_here/connecting/upload_ssh_key/index.html).

### Log in

In your **local terminal**, replace `YOUR_HPC_USERNAME` with your cluster username, such as `u12345`:

```powershell
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

Keep the SSH terminal open and open a second **local PowerShell** window. Follow one walkthrough to completion:

- [R: local test → cluster setup → jobs and results](../r/README.md)
- [Python: local test → cluster setup → jobs and results](../py/README.md)
