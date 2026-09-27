# Run Python notebooks on the GWDG HPC

First download the examples and set up SSH using your [macOS](../guides/macos.md), [Linux](../guides/linux.md), or [Windows](../guides/windows.md) guide. Then follow this page to completion.

- [Prepare and test locally](#prepare-and-test-locally)
- [Prepare the cluster environment](#prepare-the-cluster-environment)
- [Submit a job array](#submit-a-job-array)

## Prepare and test locally

### Understand the example

[`run.ipynb`](job-001/run.ipynb) simulates sample means. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000; each task saves 1,000 repetitions. Its first cell sets `task_id` and `output_dir` for local runs. Keep that cell's `parameters` tag and put simulation code in later cells: the cluster script uses Papermill to supply these values for each task.

### Prepare your local Python environment

The example uses **uv** to manage Python and its packages.

In your **local terminal**, run `uv --version`. If it is missing, install it using the block for your OS. Then enter the job folder, replacing the example path:

<details>
<summary>macOS</summary>

Install uv if needed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installation, open a new terminal. Enter the job folder:

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r/py/job-001"
```

</details>

<details>
<summary>Linux</summary>

Install uv if needed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installation, open a new terminal. Enter the job folder:

```bash
cd "/home/YOUR_NAME/path/to/minimal-hpc-r/py/job-001"
```

</details>

<details>
<summary>Windows</summary>

Install uv if needed:

```powershell
winget install --id=astral-sh.uv -e
```

After installation, open a new terminal. Enter the job folder:

```powershell
cd "C:\path\to\minimal-hpc-r\py\job-001"
```

</details>

Create the environment in that **local terminal**:

```sh
uv sync --locked
```

This installs the locked packages into `py/job-001/.venv` and downloads Python 3.13 if needed. Wait for it to finish without errors. See [uv installation help](https://docs.astral.sh/uv/getting-started/installation/) if needed.

### Keep the whole repository open

In your editor, open **`minimal-hpc-r`**, keeping all jobs visible. Local terminal commands still run from `py/job-001`; in a new terminal at the repository root, first run `cd py/job-001`.

Choose **one** editor below. The notebook's kernel is the Python environment that runs its cells.

#### Positron

1. Open the Command Palette (**Cmd+Shift+P** on macOS, **Ctrl+Shift+P** on Windows/Linux) and run **Preferences: Open Workspace Settings (JSON)**.
2. Add the setting for your OS below, using your actual repository path. Preserve other settings, separating them with commas.

<details>
<summary>macOS</summary>

```json
{
    "python.interpreters.include": ["/Users/YOUR_NAME/path/to/minimal-hpc-r/py/job-001/.venv"]
}
```

</details>

<details>
<summary>Linux</summary>

```json
{
    "python.interpreters.include": ["/home/YOUR_NAME/path/to/minimal-hpc-r/py/job-001/.venv"]
}
```

</details>

<details>
<summary>Windows</summary>

```json
{
    "python.interpreters.include": ["C:/path/to/minimal-hpc-r/py/job-001/.venv"]
}
```

</details>

3. Save, then run **Interpreter: Discover All Interpreters** from the Command Palette.
4. Open `py/job-001/run.ipynb`. Use its kernel picker to select **Python 3.13… (uv: minimal-hpc-python)** from this job's `.venv`.

For another job, run `uv sync --locked` there and add its absolute `.venv` path to the list. Keep `.vscode/settings.json` local; the repository ignores it.

<details>
<summary>If Positron cannot find the environment</summary>

- Confirm `uv sync --locked` completed in `py/job-001`.
- Check that the path in `python.interpreters.include` points to the existing `.venv` folder. Use an absolute path with forward slashes; wildcards and `${workspaceFolder}` do not work here.
- Run **Interpreter: Discover All Interpreters** again. If it is still missing, run **Developer: Reload Window**, reopen the notebook, and select its kernel again.

See [Posit's interpreter settings](https://docs.posit.co/ide/server-pro/admin/positron_sessions/interpreter_settings.html) for more help.

</details>

#### VS Code

Install Microsoft's **Python**, **Jupyter**, and **Python Environments** extensions. Open `py/job-001/run.ipynb`, choose **Select Kernel → Python Environments** (via **Select Another Kernel…** if shown), and select this job's `.venv`. Default discovery searches the repository; no custom search paths are needed.

If it is missing, run **Python Environments: Refresh All Environment Managers** from the Command Palette. For further help, see [kernel selection](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management); you can also use JupyterLab below with the same environment.

#### JupyterLab

In your **local terminal**, still in `py/job-001`:

```sh
uv run --locked jupyter lab --notebook-dir=../..
```

This opens the whole repository in your browser. Keep the terminal open, open `py/job-001/run.ipynb`, and select **Python 3 (ipykernel)** if prompted. If no browser opens, use the URL printed in the terminal.

### Run the example locally

Check the selected environment once in a temporary notebook cell:

```python
import sys
print(sys.executable)
```

It should point inside `py/job-001/.venv` (`bin/python` on macOS/Linux, `Scripts/python.exe` on Windows). Remove the temporary cell.

Restart the kernel and **Run All** cells, then save the notebook. Expected: `py/job-001/results/local-test/task-001.csv` with 1,000 rows. To repeat the run, change `output_dir` in the first cell to a fresh folder: existing CSVs are never overwritten. When finished with JupyterLab, stop it with **Ctrl+C** in its terminal and confirm shutdown if prompted.

### Add packages when you need them

The supplied example needs no extra packages. For your own notebook, run `uv add PACKAGE_NAME` in the **local terminal**, inside `py/job-001`. Restart the notebook kernel afterward. Keep the updated `pyproject.toml` and `uv.lock` with your code and upload both before the next run.

## Prepare the cluster environment

### Upload code and data

Save your edits and use the **Python** upload commands for [macOS](../guides/macos.md#upload-code-and-data), [Linux](../guides/linux.md#upload-code-and-data), or [Windows](../guides/windows.md#upload-code-and-data). That section also shows how to include your own input data. Then continue here.

### Create the cluster environment

In the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/py/job-001
ls
module load uv
uv sync --locked
```

Expect `run.ipynb`, `submit.sh`, `pyproject.toml`, and `uv.lock`. Wait for setup to finish without errors. Load `uv` again in new SSH sessions. The submission script also loads it and syncs the environment before running the notebook.

Keep the notebook, dependency files, and environment unchanged while queued or running jobs use them.

## Submit a job array

A **job array** runs the same code for several task numbers, with each task saving its own result.

### Check the submission script

Open [`submit.sh`](job-001/submit.sh) locally. It requests one CPU, 1 GiB of memory, and five minutes per task. `--array=1-5%2` runs five tasks, at most two at a time. Adjust these settings for your own workload.

The script uses `scc-cpu`; other accounts/islands may need a different [partition](https://docs.hpc.gwdg.de/how_to_use/compute_partitions/cpu_partitions/index.html). For **email notifications**, replace `YOUR_EMAIL@example.com` and uncomment the two mail directives. They notify you when the array starts, ends, or fails.

To **save executed notebooks** beside the CSVs, uncomment the existing line below `notebook_output=/dev/null`:

```bash
notebook_output="$output_dir/$(printf 'task-%03d.ipynb' "$SLURM_ARRAY_TASK_ID")"
```

Leave it commented when you only need CSVs and logs; notebook outputs can take substantial space.

Upload any edits using the same [macOS](../guides/macos.md#upload-code-and-data), [Linux](../guides/linux.md#upload-code-and-data), or [Windows](../guides/windows.md#upload-code-and-data) commands before submitting.

### Submit one task first

In the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/py/job-001
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

The log should report 1,000 saved repetitions, and `results/123456/task-001.csv` should exist. For a failed job, read its log before retrying; `TIMEOUT` or `OUT_OF_MEMORY` may require a higher `--time` or `--mem` in `submit.sh`.

### Submit the full array

After the test succeeds, run in the same **SSH terminal**:

```bash
sbatch submit.sh
```

Record the **new job ID** and repeat the checks above with it. All five tasks should be `COMPLETED` with exit code `0:0`. Expect `task-001.csv` through `task-005.csv` in `results/NEW_JOB_ID/`, plus matching Slurm logs. Leave uploaded files unchanged until all tasks finish.

### Download and open results

Use your **full array's job ID** and the **Python** download commands for [macOS](../guides/macos.md#download-results), [Linux](../guides/linux.md#download-results), or [Windows](../guides/windows.md#download-results). Keep the results, logs, and code version together.

In your **local notebook**, working in `py/job-001`, replace `123456` and read a result:

```python
import pandas as pd

result = pd.read_csv("results/123456/task-001.csv")
assert len(result) == 1000
result.head()
```

If you enabled notebook saving, each task's executed `.ipynb` is beside its CSV.

### Cancel or retry a task

In the **SSH terminal**, `scancel 123456` stops a submission; `scancel 123456_3` stops only task 3. Check `squeue --me --array` to confirm it stopped. Existing results and logs remain.

Wait for other tasks using the same files to finish before editing them. After fixing the error and uploading changes, resubmit task 3 from the job folder with `sbatch --array=3 submit.sh`. This creates a **new job ID and results folder**.

More detail: [GWDG job arrays](https://docs.hpc.gwdg.de/how_to_use/slurm/job_array/index.html) · [Slurm commands](https://docs.hpc.gwdg.de/how_to_use/slurm/index.html).
