# Run Python notebooks on the GWDG HPC

Use the [numbered main walkthrough](../README.md) to download the files and set up SSH first. This guide supplies the Python steps in that walkthrough; keep the main page open and use the return links at the end of each stage. You will test a notebook locally, then submit it to Slurm.

The example uses **uv** to manage Python and its packages. Keep [`pyproject.toml`](job-001/pyproject.toml) and [`uv.lock`](job-001/uv.lock) with your notebook in Git; each computer gets its own `.venv` environment.

## Table of contents

- [Prepare your local Python environment](#prepare-your-local-python-environment)
- [Try the notebook on your computer](#try-the-notebook-on-your-computer)
  - [In Positron](#in-positron)
  - [In VS Code](#in-vs-code)
  - [Keep the whole repository open](#keep-the-whole-repository-open)
  - [Check the notebook's Python](#check-the-notebooks-python)
  - [In JupyterLab](#in-jupyterlab)
  - [Understand the example](#understand-the-example)
  - [Try parameter passing locally](#try-parameter-passing-locally)
  - [Add packages when you need them](#add-packages-when-you-need-them)
- [Prepare the environment on SCC](#prepare-the-environment-on-scc)
- [Submit the notebook as a job array](#submit-the-notebook-as-a-job-array)
  - [Optionally save executed notebooks](#optionally-save-executed-notebooks)
  - [Submit one task first](#submit-one-task-first)
  - [Submit the full array](#submit-the-full-array)

## Prepare your local Python environment

This begins the Python part of **step 3** in the main walkthrough. Continue through the local notebook and parameter-passing checks before uploading.

In **local PowerShell**, check whether uv is installed:

```powershell
uv --version
```

If Windows cannot find it, install it with WinGet, then open a new PowerShell window:

```powershell
winget install --id=astral-sh.uv -e
```

See the [uv installation guide](https://docs.astral.sh/uv/getting-started/installation/) for other installation methods.

Move into the Python example and create its environment:

```powershell
cd "C:\path\to\minimal-hpc-r\py\job-001"
uv sync --locked
uv run --locked python --version
```

`uv sync --locked` installs the package versions recorded in `uv.lock` into `.venv`. It reports an error if the dependency declarations and lockfile disagree, instead of updating the lockfile. This example requires Python 3.13; uv can download a compatible interpreter if needed. The first setup needs internet access. See [locking and syncing](https://docs.astral.sh/uv/concepts/projects/sync/) and [installing Python](https://docs.astral.sh/uv/guides/install-python/).

The dependencies include NumPy and pandas for the simulation, JupyterLab for interactive work, and Papermill for passing parameters and running notebooks as batch jobs.

## Try the notebook on your computer

Choose [Positron](#in-positron), [VS Code](#in-vs-code), or [JupyterLab](#in-jupyterlab) below; you only need one. A notebook's **kernel** is the Python process that executes its cells. Select the environment created by `uv sync --locked` so the notebook has the project's packages.

### In Positron

After `uv sync --locked` finishes, open the job folder as your project:

1. In Positron, choose **File → Open Folder…** and select `minimal-hpc-r/py/job-001`. The Explorer should show `run.ipynb`, `pyproject.toml`, and `uv.lock` directly inside the open folder.
2. Open `run.ipynb` and click the kernel name (or **Select Kernel**) at the top of the notebook. If offered, choose **Select Environment…** to see the available environments.
3. Select **Python 3.13… (uv: minimal-hpc-python)**. Check that its path is inside this job's `.venv`: `.venv\Scripts\python.exe` on Windows, or `.venv/bin/python` on macOS/Linux. The patch version may vary.

**Open the `job-001` folder itself.** Opening the entire `minimal-hpc-r` repository, the `py` folder, or only the notebook can leave the environment out of the picker. Positron discovers `.venv` at the root of the open project; see [Python environment discovery](https://positron.posit.co/python-installations.html#discovery-locations). To keep the whole repository open instead, use the [workspace settings below](#keep-the-whole-repository-open).

If the environment is still missing, confirm that `uv sync --locked` completed in `py/job-001`, then open the Command Palette (**Ctrl+Shift+P** on Windows, **Cmd+Shift+P** on macOS) and run **Interpreter: Discover All Interpreters**. Reopen the notebook's kernel picker.

Continue with [Check the notebook's Python](#check-the-notebooks-python).

### In VS Code

Install Microsoft's **Python** and **Jupyter** extensions in VS Code. After `uv sync --locked` finishes:

1. Choose **File → Open Folder…** and select `minimal-hpc-r/py/job-001`. The Explorer should show `run.ipynb`, `pyproject.toml`, and `uv.lock` directly inside the open folder.
2. Open `run.ipynb` and click **Select Kernel** (or the current kernel name) at the top right. Choose **Select Another Kernel…**, if shown, then **Python Environments**.
3. Select the Python 3.13 environment whose path is this job's `.venv\Scripts\python.exe` on Windows, or `.venv/bin/python` on macOS/Linux. Check the path, since several environments may have the same name or Python version.

The notebook's kernel selection is separate from **Python: Select Interpreter** for Python scripts. See [VS Code's kernel selection guide](https://code.visualstudio.com/docs/datascience/jupyter-kernel-management).

If the environment is missing, confirm that `uv sync --locked` completed and that you opened the job folder. With Microsoft's **Python Environments** extension installed, run **Python Environments: Refresh All Environment Managers** from the Command Palette (**Ctrl+Shift+P** on Windows, **Cmd+Shift+P** on macOS), then reopen the notebook's kernel picker. To keep the whole repository open, use the [workspace settings below](#keep-the-whole-repository-open).

Continue with [Check the notebook's Python](#check-the-notebooks-python).

### Keep the whole repository open

Use this option if you want to browse several jobs in one editor window. Open `minimal-hpc-r` with **File → Open Folder…**, then run **Preferences: Open Workspace Settings (JSON)** from the Command Palette. This opens or creates `minimal-hpc-r/.vscode/settings.json`.

Add the setting for your editor inside the existing outer `{ ... }`, separating settings with commas. Preserve any other settings already there. The examples below are complete files if yours is empty. Settings help the editor find environments; run `uv sync --locked` inside each job folder to create them first.

**Positron: list the environments explicitly.** Replace `C:/path/to/minimal-hpc-r` with the actual location on your computer:

```json
{
    "python.interpreters.include": [
        "C:/path/to/minimal-hpc-r/py/job-001/.venv"
    ]
}
```

Use forward slashes in these JSON paths, including on Windows. On macOS/Linux, use an absolute path such as `/Users/YOUR_NAME/projects/minimal-hpc-r/py/job-001/.venv`. After creating another job's environment, add its full `.venv` path as another comma-separated entry in the list. Include only paths that exist.

Positron's setting accepts absolute paths, not wildcard patterns or `${workspaceFolder}`. A single `py/job-*/.venv` entry therefore does not work, and pointing it at the parent `py` folder is not a recursive search for all nested environments. See [Posit's interpreter settings reference](https://docs.posit.co/ide/server-pro/admin/positron_sessions/interpreter_settings.html).

Save the settings, run **Interpreter: Discover All Interpreters**, and reopen the notebook's kernel picker. If the change has not taken effect, run **Developer: Reload Window**, then select the job's environment as described above.

**VS Code: discover all job environments with a pattern.** With Microsoft's **Python Environments** extension installed, use:

```json
{
    "python-envs.workspaceSearchPaths": [
        "./.venv",
        "./py/job-*/.venv"
    ]
}
```

The second pattern matches every `job-*` folder directly inside `py`; it is relative to the open repository folder. The first also allows a root-level `.venv`. Save, run **Python Environments: Refresh All Environment Managers**, then select the notebook's kernel. Newly created job environments match without editing this list. See [VS Code's search path settings](https://code.visualstudio.com/docs/python/environments#_configure-search-paths).

**VS Code notebook caveat:** the notebook picker uses a different discovery API from the environment manager, so this setting alone may not make every environment appear there. If a job's environment remains missing from the notebook picker, open that job folder in its own VS Code window and select its kernel there. See [Microsoft's documented notebook limitation](https://code.visualstudio.com/docs/python/environments#_jupyter-notebooks).

These two settings are editor-specific; there is no single wildcard setting that configures both editors. This repository ignores `.vscode/settings.json` because the Positron paths are specific to each computer. Keep these local editor settings out of the cluster upload.

### Check the notebook's Python

In either editor, run this in a temporary notebook cell:

```python
import sys
print(sys.executable)
```

The printed path should end in `py\job-001\.venv\Scripts\python.exe` on Windows, or `py/job-001/.venv/bin/python` on macOS/Linux. Remove the temporary cell afterward, then continue with [Understand the example](#understand-the-example).

### In JupyterLab

From the same **local PowerShell** window, start JupyterLab:

```powershell
uv run --locked jupyter lab
```

Keep this terminal open. JupyterLab opens in your browser; if it does not, open the local URL printed in the terminal. Open `run.ipynb` and select **Python 3 (ipykernel)** if asked for a kernel. Starting Jupyter through uv makes the project's environment available; see [uv's Jupyter guide](https://docs.astral.sh/uv/guides/integration/jupyter/).

### Understand the example

[`run.ipynb`](job-001/run.ipynb) simulates means of samples from a normal distribution with mean 0 and standard deviation 1. Tasks 1–5 use sample sizes 10, 30, 100, 300, and 1,000. Each task performs 1,000 repetitions, matching the design of the R example.

Run the cells from top to bottom. The first code cell is tagged `parameters` and contains two editable defaults:

```python
task_id = 1
output_dir = "results/local-test"
```

Papermill inserts an `injected-parameters` cell immediately after the tagged cell when running a batch job. Keep derived values, imports, and simulation code in later cells so they use the supplied values. The source notebook already has the tag; keep it when editing. See [parameterizing a notebook](https://papermill.readthedocs.io/en/latest/usage-parameterize.html).

The `results` data frame stays available in the notebook. The final cell saves it to `results/local-test/task-001.csv`. Change the task number to try a different sample size. Choose a fresh output folder when repeating a task: the notebook refuses to replace an existing CSV, including if you rerun just the save cell.

Each task uses its number as a random seed. Repeating it with the same Python environment and settings produces the same results. R uses a different random-number generator, so the two examples' numerical results will differ.

Before uploading, choose a fresh output folder, restart the notebook's kernel, and run all cells from top to bottom. In Positron or VS Code, use the notebook's restart control, then **Run All**. In JupyterLab, use **Kernel → Restart Kernel and Run All Cells**. This catches dependencies on variables left over from earlier interactive work. Save the notebook afterward. If using JupyterLab, stop it with **Ctrl+C** in its terminal when finished, confirming shutdown if prompted.

### Try parameter passing locally

In **local PowerShell**, still in `py/job-001`, run task 3 through Papermill:

```powershell
New-Item -ItemType Directory -Force .\results\local-batch
uv run --locked papermill run.ipynb NUL -p task_id 3 -p output_dir results/local-batch --execution-timeout 120
```

This runs without a browser and saves `task-003.csv`. `NUL` is the Windows discard destination, so no executed notebook is saved (on macOS or Linux, use `/dev/null`). To keep one for inspection, replace `NUL` with `results/local-batch/task-003.ipynb`. Choose a fresh output folder to repeat the check. The local command has a two-minute per-cell timeout because it runs outside Slurm; increase it for longer cells.

### Add packages when you need them

This is optional; the example already declares its dependencies. If you do not need extra packages, return to [step 4: Upload your code and data](../README.md#4-upload-your-code-and-data).

In **local PowerShell**, in `py/job-001`, use `uv add PACKAGE_NAME` to add a dependency. This updates `pyproject.toml`, `uv.lock`, and the environment. Restart the notebook kernel after changing packages, and commit both dependency files with the code. See [uv's dependency guide](https://docs.astral.sh/uv/concepts/projects/dependencies/).

Upload the updated dependency files before your next submission. The submission script runs `uv sync --locked` automatically; running it manually first catches installation problems before the job starts. Keep the dependency files, environment, and notebook unchanged while queued or running jobs use them.

**Next:** return to [step 4: Upload your code and data](../README.md#4-upload-your-code-and-data), using the **Python** commands. Upload `run.ipynb`, `submit.sh`, `pyproject.toml`, and `uv.lock`; recreate `.venv` on the server. After checking the upload, step 5 sends you to the server setup below.

## Prepare the environment on SCC

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

**Next:** return to [step 6: Submit a test job](../README.md#6-submit-a-test-job).

## Submit the notebook as a job array

A job array runs the same notebook several times with different task numbers. Open [`submit.sh`](job-001/submit.sh) in your local editor. It requests one CPU and 1 GiB of memory per task, with a five-minute time limit. `--array=1-5%2` submits five tasks and allows at most two to run at once. These resources are for a small teaching example; adjust them for your own work.

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

Save any edits to `submit.sh` or the notebook and repeat the [Python upload command in step 4](../README.md#copy-the-job-files). Then, in the **SSH terminal**, run:

```bash
cd ~/minimal-hpc-r/py/job-001
sbatch --array=1 submit.sh
```

Slurm returns a job ID. **Next:** record it and return to [step 7: Check the test job](../README.md#7-check-the-test-job-and-run-the-full-array). Expect `results/JOB_ID/task-001.csv` with 1,000 rows, plus `task-001.ipynb` if you enabled notebook saving. Step 7 sends you back to **Submit the full array** below once this test succeeds.

### Submit the full array

After step 7 confirms that the single-task test succeeded, submit all five tasks in the **SSH terminal**:

```bash
cd ~/minimal-hpc-r/py/job-001
sbatch submit.sh
```

Use `sbatch`, not `bash submit.sh`: Slurm supplies the task and job IDs and assigns compute resources. The new submission gets its own job ID and results folder. You can disconnect while it runs.

**Next:** record the new job ID and return to [step 7](../README.md#7-check-the-test-job-and-run-the-full-array) to check all five tasks. Expect five CSVs under `results/JOB_ID/` (plus five executed notebooks if enabled). Once they succeed, continue to [step 8: Download the results](../README.md#8-download-the-results), using the **Python** paths and your full array's job ID.
