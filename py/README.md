# Run Python notebooks on the GWDG HPC

Use the numbered walkthrough for [macOS](../guides/macos.md), [Linux](../guides/linux.md), or [Windows](../guides/windows.md) to download the files and set up SSH first. This guide supplies the Python steps in that walkthrough; keep the main page open and use the return links at the end of each stage. You will test a notebook locally, then submit it to Slurm.

The example uses **uv** to manage Python and its packages. Keep [`pyproject.toml`](job-001/pyproject.toml) and [`uv.lock`](job-001/uv.lock) with your notebook in Git; each computer gets its own `.venv` environment.

## Table of contents

- [Prepare and test locally](#prepare-and-test-locally)
  - [Understand the example](#understand-the-example)
  - [Prepare your local Python environment](#prepare-your-local-python-environment)
  - [Keep the whole repository open](#keep-the-whole-repository-open)
  - [Run the example locally](#run-the-example-locally)
    - [In Positron](#in-positron)
    - [In VS Code](#in-vs-code)
    - [Check the notebook's Python](#check-the-notebooks-python)
    - [In JupyterLab](#in-jupyterlab)
    - [Run all cells](#run-all-cells)
    - [Try parameter passing locally](#try-parameter-passing-locally)
  - [Add packages when you need them](#add-packages-when-you-need-them)
- [Prepare the cluster environment](#prepare-the-cluster-environment)
- [Submit a job array](#submit-a-job-array)
  - [Check the submission script](#check-the-submission-script)
  - [Optionally save executed notebooks](#optionally-save-executed-notebooks)
  - [Submit one task first](#submit-one-task-first)
  - [Submit the full array](#submit-the-full-array)

## Prepare and test locally

This is the Python part of **step 3** in the main walkthrough. Continue through the local notebook and parameter-passing checks before uploading.

### Understand the example

[`run.ipynb`](job-001/run.ipynb) simulates means of samples from a normal distribution with mean 0 and standard deviation 1. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000. Each task performs 1,000 repetitions, matching the design of the R example.

The first code cell is tagged `parameters` and contains two editable defaults:

```python
task_id = 1
output_dir = "results/local-test"
```

Papermill inserts an `injected-parameters` cell immediately after the tagged cell when running a batch job. Keep derived values, imports, and simulation code in later cells so they use the supplied values. The source notebook already has the tag; keep it when editing. See [parameterizing a notebook](https://papermill.readthedocs.io/en/latest/usage-parameterize.html).

The `results` data frame stays available in the notebook. The final cell saves it to `results/local-test/task-001.csv`. Change the task number to try a different sample size. Choose a fresh output folder when repeating a task: the notebook refuses to replace an existing CSV, including if you rerun just the save cell.

Each task uses its number as a random seed. Repeating it with the same Python environment and settings produces the same results. R uses a different random-number generator, so the two examples' numerical results will differ.

### Prepare your local Python environment

In your **local terminal** (Terminal on macOS/Linux, PowerShell on Windows), check whether uv is installed:

```sh
uv --version
```

Expand your operating system below. Install uv only if the check above failed, then move into the Python example. Replace the example path with your repository location.

<details>
<summary>macOS</summary>

If uv is missing, install it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installation, open a new terminal and run `uv --version` again. Then move into the example:

```bash
cd "/Users/YOUR_NAME/path/to/minimal-hpc-r/py/job-001"
```

</details>

<details>
<summary>Linux</summary>

If uv is missing, install it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installation, open a new terminal and run `uv --version` again. Then move into the example:

```bash
cd "/home/YOUR_NAME/path/to/minimal-hpc-r/py/job-001"
```

</details>

<details>
<summary>Windows</summary>

If uv is missing, install it:

```powershell
winget install --id=astral-sh.uv -e
```

After installation, open a new PowerShell window and run `uv --version` again. Then move into the example:

```powershell
cd "C:\path\to\minimal-hpc-r\py\job-001"
```

</details>

See the [uv installation guide](https://docs.astral.sh/uv/getting-started/installation/) for other installation methods, including a `wget` command if `curl` is unavailable.

Then create the environment (the same commands work on all three systems):

```sh
uv sync --locked
uv run --locked python --version
```

`uv sync --locked` installs the package versions recorded in `uv.lock` into `.venv`. It reports an error if the dependency declarations and lockfile disagree, instead of updating the lockfile. This example requires Python 3.13; uv can download a compatible interpreter if needed. The first setup needs internet access. See [locking and syncing](https://docs.astral.sh/uv/concepts/projects/sync/) and [installing Python](https://docs.astral.sh/uv/guides/install-python/).

The dependencies include NumPy and pandas for the simulation, JupyterLab for interactive work, and Papermill for passing parameters and running notebooks as batch jobs.

### Keep the whole repository open

In Positron or VS Code, choose **File → Open Folder…** and select `minimal-hpc-r`. The Explorer should show `README.md`, `guides`, `r`, and `py` at the top level. Keep this folder open throughout the walkthrough. JupyterLab users can go directly to [In JupyterLab](#in-jupyterlab), which also opens the whole repository.

Expand your operating system for the interpreter path and Command Palette shortcut used in the editor instructions below:

<details>
<summary>macOS</summary>

- **Interpreter:** `py/job-001/.venv/bin/python` inside your repository.
- **Command Palette:** **Cmd+Shift+P**.

</details>

<details>
<summary>Linux</summary>

- **Interpreter:** `py/job-001/.venv/bin/python` inside your repository.
- **Command Palette:** **Ctrl+Shift+P**.

</details>

<details>
<summary>Windows</summary>

- **Interpreter:** `py\job-001\.venv\Scripts\python.exe` inside your repository.
- **Command Palette:** **Ctrl+Shift+P**.

</details>

The editor's open folder and the terminal's working directory are separate. Run local `uv` and Papermill commands from `py/job-001`, where that job's `pyproject.toml` lives. If you open a new terminal at the repository root, run `cd py/job-001` first.

For Positron or VS Code, run **Preferences: Open Workspace Settings (JSON)** from the Command Palette. This opens or creates `minimal-hpc-r/.vscode/settings.json`.

Add the setting for your editor inside the existing outer `{ ... }`, separating settings with commas. Preserve any other settings already there. The examples below are complete files if yours is empty. Settings help the editor find environments; run `uv sync --locked` inside each job folder to create them first.

**Positron: list the environments explicitly.** Expand your operating system for an example, replacing the path with the actual location on your computer:

<details>
<summary>macOS</summary>

```json
{
    "python.interpreters.include": [
        "/Users/YOUR_NAME/path/to/minimal-hpc-r/py/job-001/.venv"
    ]
}
```

</details>

<details>
<summary>Linux</summary>

```json
{
    "python.interpreters.include": [
        "/home/YOUR_NAME/path/to/minimal-hpc-r/py/job-001/.venv"
    ]
}
```

</details>

<details>
<summary>Windows</summary>

```json
{
    "python.interpreters.include": [
        "C:/path/to/minimal-hpc-r/py/job-001/.venv"
    ]
}
```

</details>

Use forward slashes in these JSON paths. After creating another job’s environment, add its full `.venv` path as another comma-separated entry in the list. Include only paths that exist.

Positron's setting accepts absolute paths, not wildcard patterns or `${workspaceFolder}`. A single `py/job-*/.venv` entry therefore does not work, and pointing it at the parent `py` folder is not a recursive search for all nested environments. See [Posit's interpreter settings reference](https://docs.posit.co/ide/server-pro/admin/positron_sessions/interpreter_settings.html).

Save the settings, then follow [In Positron](#in-positron) to discover the environment and select the notebook's kernel.

**VS Code: discover all job environments with a pattern.** Install Microsoft's **Python**, **Jupyter**, and **Python Environments** extensions, then use:

```json
{
    "python-envs.workspaceSearchPaths": [
        "./.venv",
        "./py/job-*/.venv"
    ]
}
```

The second pattern matches every `job-*` folder directly inside `py`; it is relative to the open repository folder. The first also allows a root-level `.venv`. Save, then follow [In VS Code](#in-vs-code) to refresh environments and select the notebook's kernel. Newly created job environments match without editing this list. See [VS Code's search path settings](https://code.visualstudio.com/docs/python/environments#_configure-search-paths).

These two settings are editor-specific; there is no single wildcard setting that configures both editors. This repository ignores `.vscode/settings.json` because the Positron paths are specific to each computer. Keep these local editor settings out of the cluster upload.

### Run the example locally

Keep `minimal-hpc-r` open as your workspace so you can browse all jobs together. Choose [Positron](#in-positron), [VS Code](#in-vs-code), or [JupyterLab](#in-jupyterlab) below; you only need one. A notebook's **kernel** is the Python process that executes its cells. Select the environment created by `uv sync --locked` so the notebook has the project's packages.

#### In Positron

With `minimal-hpc-r` open and the Positron workspace setting above saved:

1. Run **Interpreter: Discover All Interpreters** from the Command Palette.
2. Open `py/job-001/run.ipynb` from the Explorer and click the kernel name (or **Select Kernel**) at the top of the notebook. If offered, choose **Select Environment…**.
3. Select **Python 3.13… (uv: minimal-hpc-python)**. Check that its path matches the interpreter in your platform's details above, inside this job's `.venv`. The patch version may vary.

If the environment is missing, confirm that `uv sync --locked` completed in `py/job-001` and that `python.interpreters.include` contains the absolute path to its `.venv`. Run **Interpreter: Discover All Interpreters** again. If the setting has not taken effect, run **Developer: Reload Window** and reopen the kernel picker.

Continue with [Check the notebook's Python](#check-the-notebooks-python).

#### In VS Code

With `minimal-hpc-r` open, the extensions installed, and the VS Code workspace setting above saved:

1. Run **Python Environments: Refresh All Environment Managers** from the Command Palette.
2. Open `py/job-001/run.ipynb` from the Explorer and click **Select Kernel** (or the current kernel name) at the top right. Choose **Select Another Kernel…**, if shown, then **Python Environments**.
3. Select the Python 3.13 environment whose path matches the interpreter in your platform's details above, inside this job's `.venv`. Check the path, since several environments may have the same name or Python version.

The notebook's kernel selection is separate from **Python: Select Interpreter** for Python scripts. See [VS Code's kernel selection guide](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management).

If the environment is missing, confirm that `uv sync --locked` completed in `py/job-001`, refresh environments, and reopen the kernel picker. The notebook picker uses a different discovery API from the environment manager, so the search-path setting alone may not make every environment appear there; see [Microsoft's documented notebook limitation](https://code.visualstudio.com/docs/python/environments#_jupyter-notebooks). If it remains missing, use [JupyterLab](#in-jupyterlab) below with the same repository and job environment.

Continue with [Check the notebook's Python](#check-the-notebooks-python).

#### Check the notebook's Python

In either editor, run this in a temporary notebook cell:

```python
import sys
print(sys.executable)
```

The printed path should end with the interpreter path in your platform’s details under [Keep the whole repository open](#keep-the-whole-repository-open). Remove the temporary cell afterward, then continue with [Run all cells](#run-all-cells).

#### In JupyterLab

From the same **local terminal** window, still in `py/job-001`, start JupyterLab with the repository root as its file browser directory:

```sh
uv run --locked jupyter lab --notebook-dir=../..
```

`../..` points from `py/job-001` to `minimal-hpc-r`, so the file browser shows the whole repository; see [JupyterLab's directory option](https://jupyterlab.readthedocs.io/en/stable/getting_started/starting.html). Keep this terminal open. JupyterLab opens in your browser; if it does not, open the local URL printed in the terminal. Open `py/job-001/run.ipynb` and select **Python 3 (ipykernel)** if asked for a kernel. Starting Jupyter through uv makes the project's environment available; see [uv's Jupyter guide](https://docs.astral.sh/uv/guides/integration/jupyter/).

Continue with [Run all cells](#run-all-cells).

#### Run all cells

Before uploading, choose a fresh output folder, restart the notebook's kernel, and run all cells from top to bottom. In Positron or VS Code, use the notebook's restart control, then **Run All**. In JupyterLab, use **Kernel → Restart Kernel and Run All Cells**. This catches dependencies on variables left over from earlier interactive work. Save the notebook afterward. If using JupyterLab, stop it with **Ctrl+C** in its terminal when finished, confirming shutdown if prompted.

#### Try parameter passing locally

In your **local terminal**, still in `py/job-001`, expand your operating system and run task 3 through Papermill:

<details>
<summary>macOS</summary>

```bash
mkdir -p ./results/local-batch
uv run --locked papermill run.ipynb /dev/null -p task_id 3 -p output_dir results/local-batch --execution-timeout 120
```

`/dev/null` discards the executed notebook. To keep one for inspection, replace it with `results/local-batch/task-003.ipynb`.

</details>

<details>
<summary>Linux</summary>

```bash
mkdir -p ./results/local-batch
uv run --locked papermill run.ipynb /dev/null -p task_id 3 -p output_dir results/local-batch --execution-timeout 120
```

`/dev/null` discards the executed notebook. To keep one for inspection, replace it with `results/local-batch/task-003.ipynb`.

</details>

<details>
<summary>Windows</summary>

```powershell
New-Item -ItemType Directory -Force .\results\local-batch
uv run --locked papermill run.ipynb NUL -p task_id 3 -p output_dir results/local-batch --execution-timeout 120
```

`NUL` discards the executed notebook. To keep one for inspection, replace it with `results/local-batch/task-003.ipynb`.

</details>

This runs without a browser and saves `task-003.csv`. Choose a fresh output folder to repeat the check. The local command has a two-minute per-cell timeout because it runs outside Slurm; increase it for longer cells.

### Add packages when you need them

This is optional; the example already declares its dependencies. If you do not need extra packages, return to step 4: Upload your code and data ([macOS](../guides/macos.md#4-upload-your-code-and-data), [Linux](../guides/linux.md#4-upload-your-code-and-data), [Windows](../guides/windows.md#4-upload-your-code-and-data)).

In your **local terminal**, in `py/job-001`, use `uv add PACKAGE_NAME` to add a dependency. This updates `pyproject.toml`, `uv.lock`, and the environment. Restart the notebook kernel after changing packages, and commit both dependency files with the code. See [uv's dependency guide](https://docs.astral.sh/uv/concepts/projects/dependencies/).

Upload the updated dependency files before your next submission. The submission script runs `uv sync --locked` automatically; running it manually first catches installation problems before the job starts. Keep the dependency files, environment, and notebook unchanged while queued or running jobs use them.

**Next:** return to step 4: Upload your code and data ([macOS](../guides/macos.md#4-upload-your-code-and-data), [Linux](../guides/linux.md#4-upload-your-code-and-data), [Windows](../guides/windows.md#4-upload-your-code-and-data)), using the **Python** commands. Upload `run.ipynb`, `submit.sh`, `pyproject.toml`, and `uv.lock`; recreate `.venv` on the server. After checking the upload, step 5 sends you to the server setup below.

## Prepare the cluster environment

In the **connected SSH terminal**, run:

```bash
cd ~/minimal-hpc-r/py/job-001
module load uv
uv --version
uv sync --locked
uv run --locked python -c 'import sys, numpy, pandas; print(sys.version); print(numpy.__version__, pandas.__version__)'
```

Wait for installation to finish and check for errors. These commands prepare the environment and check imports; the simulation itself runs as a compute job. Load `uv` again in each new SSH session. The submission script also loads it explicitly.

The submission script also runs `uv sync --locked` at startup, creating `.venv` if needed. Every array task checks the same environment; uv serializes installations with a lock. An initial sync before submission is still useful, especially for a large array: installation and waiting count toward the job's time limit, and missing packages need network access or cached files. See [uv's concurrency guarantees](https://docs.astral.sh/uv/concepts/cache/#cache-safety).

After syncing, the script uses `uv run --no-sync --offline` to execute the notebook with that environment, without another installation check.

**Next:** return to step 6: Submit a test job ([macOS](../guides/macos.md#6-submit-a-test-job), [Linux](../guides/linux.md#6-submit-a-test-job), [Windows](../guides/windows.md#6-submit-a-test-job)).

## Submit a job array

A job array runs the same notebook several times with different task numbers.

### Check the submission script

Open [`submit.sh`](job-001/submit.sh) in your **local editor**. Lines beginning with `#SBATCH` tell Slurm what to request:

| Setting | Meaning |
| --- | --- |
| `--partition=scc-cpu` | Use the SCC CPU partition on Emmy Phase 3 |
| `--nodes=1`, `--ntasks=1`, `--cpus-per-task=1` | Run one Python kernel with one CPU per array task |
| `--mem=1G` | Request 1 GiB of memory per array task |
| `--time=00:05:00` | Allow up to five minutes per array task |
| `--array=1-5%2` | Run tasks 1–5, with at most two running at once |
| `--output=slurm-%A_%a.out` | Give each task its own log, containing printed output and errors |

These resources are for a small teaching example; adjust them for your own work. The partition must match your access; consult the [CPU partition table](https://docs.hpc.gwdg.de/how_to_use/compute_partitions/cpu_partitions/index.html) if you are not using SCC on Emmy Phase 3.

The script calls **Papermill**, passing the task number and results folder as notebook parameters:

```bash
uv run --no-sync --offline papermill run.ipynb "$notebook_output" \
    -p task_id "$SLURM_ARRAY_TASK_ID" -p output_dir "$output_dir" \
    --log-output --no-progress-bar
```

The first path is the source notebook; the second is the notebook output destination, set to `/dev/null` by default to discard it. Each `-p` supplies a parameter name and value. Papermill starts a fresh Python kernel and executes cells in order, with these values overriding the tagged defaults. No browser or JupyterLab server is needed on the cluster. A cell error fails the job; inspect the Slurm log for its traceback. See the [Papermill command-line reference](https://papermill.readthedocs.io/en/latest/usage-cli.html).

Slurm's `#SBATCH --time=00:05:00` limits the whole job. There is no separate per-cell timeout in the batch command; increase the Slurm limit for longer computations. `--log-output` also writes printed cell output to the Slurm log. The numerical-library thread settings match the single requested CPU; configure Python worker counts separately if you later add parallelism.

### Optionally save executed notebooks

The default keeps CSV results and Slurm logs. Saving a notebook for every task can use substantial disk space, especially when its outputs contain figures.

To retain executed notebooks, uncomment this line in `submit.sh`, below `notebook_output=/dev/null`:

```bash
notebook_output="$output_dir/$(printf 'task-%03d.ipynb' "$SLURM_ARRAY_TASK_ID")"
```

Each task then saves an executed notebook beside its CSV. This can help when inspecting a small test run. Comment the line again to return to discarding notebooks. Your source `run.ipynb` is unchanged in either mode.

### Submit one task first

Save any edits to `submit.sh` or the notebook and repeat the Python upload command in step 4 ([macOS](../guides/macos.md#copy-the-job-files), [Linux](../guides/linux.md#copy-the-job-files), [Windows](../guides/windows.md#copy-the-job-files)). Then, in the **SSH terminal**, run:

```bash
cd ~/minimal-hpc-r/py/job-001
sbatch --array=1 submit.sh
```

Slurm returns a job ID. **Next:** record it and return to step 7: Check the test job ([macOS](../guides/macos.md#7-check-the-test-job-and-run-the-full-array), [Linux](../guides/linux.md#7-check-the-test-job-and-run-the-full-array), [Windows](../guides/windows.md#7-check-the-test-job-and-run-the-full-array)). Expect `results/JOB_ID/task-001.csv` with 1,000 rows, plus `task-001.ipynb` if you enabled notebook saving. Step 7 sends you back to **Submit the full array** below once this test succeeds.

### Submit the full array

After step 7 confirms that the single-task test succeeded, submit all five tasks in the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/py/job-001
sbatch submit.sh
```

Use `sbatch`, not `bash submit.sh`: Slurm supplies the task and job IDs and assigns compute resources. The new submission gets its own job ID and results folder. You can disconnect while it runs.

**Next:** record the new job ID and return to step 7 ([macOS](../guides/macos.md#7-check-the-test-job-and-run-the-full-array), [Linux](../guides/linux.md#7-check-the-test-job-and-run-the-full-array), [Windows](../guides/windows.md#7-check-the-test-job-and-run-the-full-array)) to check all five tasks. Expect five CSVs under `results/JOB_ID/` (plus five executed notebooks if enabled). Once they succeed, continue to step 8: Download the results ([macOS](../guides/macos.md#8-download-the-results), [Linux](../guides/linux.md#8-download-the-results), [Windows](../guides/windows.md#8-download-the-results)), using the **Python** paths and your full array's job ID.
