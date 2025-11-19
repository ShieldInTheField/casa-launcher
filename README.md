# casa-launcher

A lightweight command-line tool that helps you organize and launch CASA projects in a clean, consistent way.
It provides per-project workspaces, creates a standard directory layout, and keeps CASA log and parameter files contained within each project.
The goal is to improve clarity and reproducibility while keeping the familiar CASA workflow unchanged.
Designed to work on both Linux and macOS.

---

## Overview of Functionality

- Consistent directory layout per project:
`data/`, `plots/`, `images/`, `logs/`, `lasts/`, `scripts/`, `startup.py`
- Starts CASA within the selected project:
`casa-launcher <project>`
- Places CASA log (`*.log`) and task-parameter (`*.last`) files into their respective folders after each session
- Automatically generates a project-level startup.py and loads it at CASA startup when supported
- Project-management commands:
    - `--init` / `-i` — create a project
    - `--list` / `-l` — list projects
    - `--delete` / `-d` — remove a project
    - `--script` / `-s` — create a new CASA-ready script with path boilerplate
    - `--help` / `-h` — show help
    - `--version` / `-v` — show launcher and CASA version
- Works on both Linux and macOS, using either a system CASA installation or the macOS application bundle

#### Why use casa-launcher?

- Keeps CASA projects organized with consistent directory structure
- Simplifies launching CASA in the context of a specific project
- Encourages reproducible and maintainable projects

---

## Installation

### Supported environment
casa-launcher is intended for use in a typical CASA project setup:
- Linux or macOS
- CASA installed on the system
- POSIX shell (Bash, Zsh, etc.)

To test that CASA is accessible:
```bash
which casa
casa --version
```

The tool does not modify CASA itself; it simply provides a more organized project structure around it.

### Installation Steps

1. Clone the repo
```bash
git clone https://github.com/ShieldInTheField/casa-launcher.git
cd casa-launcher
```
Or download the script directly:
```bash
curl -O https://raw.githubusercontent.com/ShieldInTheField/casa-launcher/master/casa-launcher.sh
```

2. Make it executable
```bash
chmod +x casa-launcher.sh
```

3. Move it into your PATH
```bash
mkdir -p ~/.local/bin
mv casa-launcher.sh ~/.local/bin/casa-launcher
```
If ~/.local/bin is not already in your PATH, add it by appending the following line to your shell configuration:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

You can verify the installation with:
```bash
which casa-launcher
```


4. Set the base directory for all CASA projects (add to your shell config)
```bash
export CASA_WORKBASE="$HOME/casa-projects"
mkdir -p "$CASA_WORKBASE"
```

5. (Optional) Alias the launcher as `csl` (add to your shell config)
```bash
alias csl="casa-launcher"
# reload your shell
```

---

## Directory structure

Each project created by `casa-launcher` contains:
```
<Project>/
├─ data/
├─ plots/
├─ images/
├─ logs/
├─ lasts/
├─ scripts/
└─ startup.py
```

Folder purposes:
- `data/` — MeasurementSets(ms), caltables, FITS tables, intermediate products
- `plots/` — diagnostic plots and QA figures
- `images/` — tclean outputs, FITS images, derived imaging products
- `logs/` — CASA `.log` files (auto-moved at exit)
- `lasts/` — CASA `.last` parameter files (auto-moved at exit)
- `scripts/` — analysis scripts or helper modules

A startup.py file is automatically created by casa-launcher for every project. You may freely customize this file to add project-specific variables, helper functions, or default parameters.

---

## Quick start

Create a project:
```bash
casa-launcher --init MyProject
```

Launch CASA in the project:
```bash
casa-launcher MyProject
casa-launcher MyProject --nogui  # pass CASA args
```

List or delete projects:
```bash
casa-launcher --list
casa-launcher --delete OldProject
```

Help and version:
```bash
casa-launcher --help
casa-launcher --version
```

---

## How casa-launcher unifies project layout 

To guarantee consistent behavior between interactive CASA sessions and CASA scripts, casa-launcher sets up the same project-aware environment in two complementary ways:

- **startup.py** — loaded automatically at CASA startup (or manually on older CASA versions) to configure the interactive environment
- **Script boilerplate** — inserted by `--script` so scripts run with the same path logic and helper functions

Both mechanisms define identical `data()`, `plots()`, `images()`, and `scripts()` helpers and ensure that all CASA workflows, interactive or scripted, operate consistently inside each project.

You can use these helpers identically in both interactive CASA sessions and scripts:

```python
tclean(vis=data("source.ms"), imagename=images("clean_image"))
plotms(vis=data("source.ms"), plotfile=plots("diagnostic.png"))
```

**A word of warning about interactive use**
Helper functions do not currently support tab completion.
In **interactive CASA sessions**, the current working directory is the project root, so CASA tasks see paths relative to the project root. For this reason, and because CASA’s tab completion only works inside literal strings, it is recommended to use:

```python
plotms(vis="data/<TAB>")
tclean(vis="data/<TAB>", imagename="images/<TAB>")
```
This maintains CASA’s normal interactive behavior and filename autocompletion. However, you can still use the helper functions in interactive mode; just remember that auto tab completion is not yet available, so it's best to use literal strings as shown in the example inside CASA sessions.

In scripts, the situation is different: scripts live under the `scripts/` directory, so hardcoding `"data/..."` or `"images/..."` will not be correct. For this reason, in scripts you should always use the helper functions.

In short:
- Helper functions (`data()`, `images()`, `plots()`, and `scripts()`) may be used in both interactive mode and scripts.
- **Interactive mode**: recommended to use literal `"data/..."`, `"images/..."` paths for convenience and tab completion.
- **Script**: must use helper functions for correct, portable, project-aware paths.

---

## Using startup.py

A `startup.py` file is automatically created in each project containing path logic and helper functions similar to those used in CASA scripts.
If `startup.py` is missing at launch time, casa-launcher will automatically recreate it.  
If it already exists, it will never be overwritten, ensuring that any customizations you add remain intact.

For CASA versions that support the `--startupfile` option, casa-launcher uses this feature automatically to load `startup.py` at CASA startup. This ensures that interactive sessions start with the same environment as CASA scripts generated via `--script`.

For CASA versions that do not support the `--startupfile` option, users need to manually run:
```python
execfile('startup.py')   # CASA/python 2-style
```
or
```python
run -i startup.py        # interactive execution
```
to load the startup environment. These methods load the same environment defined in `startup.py`, guaranteeing consistent behavior across CASA versions.
If manual loading is required, casa-launcher will notify the user.

You can freely add customizations to `startup.py` for additional per-project setup.  
For example, you may define project‑specific variables or helper shortcuts:

```python
raw_ms = data("visibilities.ms")
calibrated_ms = data("visibilities_calibrated.ms")
target_field = "ngc612"
```

Anything added to `startup.py` will be available automatically at CASA startup (for CASA versions supporting `--startupfile`), or after manually loading it in older CASA versions. This allows each project to maintain its own tailored environment without affecting others.

---


## Writing CASA scripts with reliable paths

Scripts created with `--script` include an equivalent boilerplate so that both interactive and scripted workflows share identical path behavior and helper functions across all projects.
Interactive CASA sessions receive the same environment automatically through `startup.py`. 


You can generate a CASA-ready script automatically using:

```bash
casa-launcher --script <script-name> <target-project>
```

This will create `scripts/<script-name>.py` in your project with a boilerplate path logic, ensuring that all outputs go into the expected directories. Your CASA code goes under that boilerplate.

If you prefer to create scripts manually instead of using `--script`, simply copy and paste the boilerplate path setup into your script. Make sure the script is placed under the `scripts/` directory for correct path resolution.

---

### Using casa-launcher with existing projects

If you use `casa-launcher` with existing CASA projects, it will automatically create the expected directory structure (`data/`, `plots/`, `images/`, `logs/`, `lasts/`, `scripts/`) inside the project if any of these are missing.
A `startup.py` file will also be created automatically if none exists.
If a `startup.py` already exists, it will **never** be overwritten by casa-launcher.

##### One-time manual steps for older projects

Except for `.log` and `.last` files, casa-launcher does not reorganize existing files automatically.
If your project contains data, plots, images, or scripts in arbitrary locations, you should perform a one-time cleanup:
- Move all scientific data products into `data/`
- Move diagnostic plots and figures into `plots/`
- Move imaging outputs and final images into `images/`
- Place all CASA-related scripts into `scripts/`
- Update older CASA scripts to include the casa-launcher boilerplate path logic for scripts
- Update any existing `startup.py` to include the casa-launcher boilerplate path logic for `startup.py` 
- Replace hardcoded paths with the helper functions (`data()`, `images()`, `plots()`)

The boilerplate logic for both scripts and startup.py can be found in the casa-launcher project files.

##### After the one-time migration
Once this cleanup is done, casa-launcher will manage the project fully:
- `.log` and `.last` files will be automatically moved into `logs/` and `lasts/` on exit.
- Script-based and interactive CASA sessions will use the same helper functions (`data()`, `plots()`, `images()`, `scripts()`)
- All outputs produced by scripts or by interactive use will land in the correct subdirectories
- The environment will remain consistent across all future sessions

A future `--autosort` mode is planned to help automate sorting and moving legacy data into proper locations.

---

### Staying in the project root during CASA sessions

When using `casa-launcher`, avoid changing the working directory *inside* CASA sessions.  
As long as you remain in the project root during a CASA session, all paths, outputs, logs, and saved task parameters are routed automatically to their correct project subdirectories.

This restriction applies **only inside CASA**.  
Outside of CASA, you are completely free to navigate the project directory tree in your shell, open files, edit scripts, or work with multiple terminals in parallel.

By launching CASA using casa-launcher and keeping the working directory fixed during each CASA session:
- You can launch CASA from *any* directory on your system using `casa-launcher <project>` and it will always start in the correct project root.
- All logs and `.last` files will end up in the correct `logs/` and `lasts/` directories automatically.
- All data, images, and plots produced by scripts or startup.py helpers will be saved in their proper locations.
- You never need to manually organize output files or worry about CASA leaving files in unexpected places.

As long as you do not manually `cd` *inside* CASA, the entire workflow remains clean, predictable, and fully managed by casa-launcher.

---

## Version information

```bash
casa-launcher --version
```
Example output:
```
casa-launcher version 0.1.0
CASA backend: CASA 6.6.1-15
```

---

## Troubleshooting

- CASA didn't start → check that CASA is installed and available in your PATH
- Logs didn't move → ensure you launched CASA through casa-launcher and did not change directories inside CASA sessions
- CASA crashed before cleanup → no issue. Any `.log` or `.last` files left in the project root will be automatically moved into `logs/` and `lasts/` during the next `casa-launcher` run.
- startup.py not applied → you may be using an older CASA version; run `execfile('startup.py')` manually.

---

## Roadmap

Planned improvements:
- Optional `--autosort` mode
- Additional subdirectories when useful
- Template-based project initialization
- Config file for defaults
- Enhanced help output
- Shell completions for Bash and Zsh

---

## Contributing

Contributions are most welcome.
If you’d like to improve casa-launcher or add new features, you can do so by opening an issue or submitting a pull request.

---

## License

casa-launcher is released under the MIT License.
See the LICENSE file for details.
