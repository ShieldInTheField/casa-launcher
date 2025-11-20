#!/usr/bin/env bash

set -euo pipefail

# ----------------------------------------------------------------------
# 1. Configuration: base directory for all CASA projects
# ----------------------------------------------------------------------
if [[ -z "${CASA_WORKBASE:-}" ]]; then
    echo "Error: CASA_WORKBASE is not set."
    echo "Set it in your shell, for example:"
    echo "    export CASA_WORKBASE=\"\$HOME/casa-projects\""
    exit 1
fi

LAUNCHER_VERSION="0.1.1"

write_startup_py() {
    local proj_root="$1"
    local startup_file="$proj_root/startup.py"

    # Do not overwrite an existing startup.py
    if [[ -e "$startup_file" ]]; then
        return 0
    fi

    cat > "$startup_file" <<'EOF'
from pathlib import Path

project_dir = Path.cwd().resolve()

data_dir   = (project_dir / "data").resolve()
plots_dir  = (project_dir / "plots").resolve()
images_dir = (project_dir / "images").resolve()
scripts_dir = (project_dir / "scripts").resolve()

for d in (data_dir, plots_dir, images_dir, scripts_dir):
    d.mkdir(parents=True, exist_ok=True)

def data(name): return str(data_dir / name)
def plots(name): return str(plots_dir / name)
def images(name): return str(images_dir / name)
def scripts(name): return str(scripts_dir / name)

# ----------------------------------------------------------
# Your startup customizations goes below here
# ----------------------------------------------------------



# ----------------------------------------------------------
# End of startup customizations
# ----------------------------------------------------------
print("startup configurations loaded successfully.")
EOF
}

print_help() {
    echo "Usage: casa-launcher <project> [CASA args...]"
    echo "Options:"
    echo "  --init, -i <project>           Initialize a new CASA project"
    echo "  --list, -l                     List existing CASA projects"
    echo "  --delete, -d <project>         Delete a CASA project"
    echo "  --script, -s <name> <project>  Create a new CASA script in the given project"
    echo "  --help, -h                     Show this help message"
    echo "  --version, -v                  Show version information"
}

# ----------------------------------------------------------------------
# Option handling
# ----------------------------------------------------------------------
if [[ "${1:-}" == -* ]]; then
    case "$1" in
        --help|-h)
            print_help
            exit 0
            ;;
        --version|-v)
            echo "casa-launcher version $LAUNCHER_VERSION"
            casa_bin_tmp="$(type -P casa || true)"
            if [[ -n "$casa_bin_tmp" && "$casa_bin_tmp" != "$0" ]]; then
                if "$casa_bin_tmp" --help 2>&1 | grep -q -- "--version"; then
                    echo "CASA backend: $("$casa_bin_tmp" --version 2>/dev/null || echo 'No version info')"
                else
                    echo "CASA backend: (version flag not supported)"
                fi
            elif [[ -x "/Applications/CASA.app/Contents/MacOS/casa" ]]; then
                if /Applications/CASA.app/Contents/MacOS/casa --help 2>&1 | grep -q -- "--version"; then
                    echo "CASA backend: $(/Applications/CASA.app/Contents/MacOS/casa --version 2>/dev/null || echo 'No version info')"
                else
                    echo "CASA backend: (version flag not supported)"
                fi
            else
                echo "CASA backend: not found"
            fi
            exit 0
            ;;
        --list|-l)
            echo -e "Existing CASA projects under $CASA_WORKBASE:\n"

            shopt -s nullglob
            found_any=false

            for dir in "$CASA_WORKBASE"/*; do
                if [[ -d "$dir" && -d "$dir/data" && -d "$dir/plots" && -d "$dir/images" ]]; then
                    echo "$(basename "$dir")"
                    found_any=true
                fi
            done

            shopt -u nullglob

            if [[ "$found_any" = false ]]; then
                echo "(no projects found)"
            fi

            exit 0
            ;;
        --delete|-d)
            if [[ -z "${2:-}" ]]; then
                echo "Error: Missing project name for --delete."
                exit 1
            fi
            delproj="$2"
            deldir="$CASA_WORKBASE/$delproj"
            if [[ ! -d "$deldir" ]]; then
                echo "Project '$delproj' does not exist."
                exit 1
            fi
            read -r -p "Are you sure you want to delete project '$delproj'? (y/n) " ans
            case "$ans" in
                [Yy]*)
                    rm -rf "$deldir"
                    echo "Project '$delproj' deleted."
                    ;;
                *)
                    echo "Delete aborted."
                    ;;
            esac
            exit 0
            ;;
        --init|-i)
            if [[ -z "${2:-}" ]]; then
                echo "Error: Missing project name for --init."
                exit 1
            fi
            newproj="$2"
            projdir="$CASA_WORKBASE/$newproj"
            if [[ -d "$projdir" ]]; then
                echo "Project '$newproj' already exists at $projdir"
                exit 0
            fi
            echo "Initializing new CASA project: $projdir"
            mkdir -p "$projdir"
            required_dirs=( "data" "plots" "images" "logs" "lasts" "scripts" )
            for d in "${required_dirs[@]}"; do
                mkdir -p "$projdir/$d"
            done
            write_startup_py "$projdir"
            echo "Project '$newproj' created."
            exit 0
            ;;
        --script|-s)
            if [[ -z "${2:-}" || -z "${3:-}" ]]; then
                echo "Usage: casa-launcher --script <script-name> <project>"
                exit 1
            fi
            script_name="$2"
            target_project="$3"
            projdir="$CASA_WORKBASE/$target_project"
            if [[ ! -d "$projdir" ]]; then
                echo "Error: Project '$target_project' does not exist."
                exit 1
            fi
            scripts_dir="$projdir/scripts"
            mkdir -p "$scripts_dir"
            script_path="$scripts_dir/${script_name}.py"
            if [[ -e "$script_path" ]]; then
                echo "Error: Script '$script_name.py' already exists in project '$target_project'."
                exit 1
            fi
            cat > "$script_path" <<'EOF'
from pathlib import Path

scripts_dir = Path(__file__).parent.resolve()
project_dir = (scripts_dir / "..").resolve()

data_dir   = (project_dir / "data").resolve()
plots_dir  = (project_dir / "plots").resolve()
images_dir = (project_dir / "images").resolve()

for d in (data_dir, plots_dir, images_dir, scripts_dir):
    d.mkdir(parents=True, exist_ok=True)

def data(name): return str(data_dir / name)
def plots(name): return str(plots_dir / name)
def images(name): return str(images_dir / name)
def scripts(name): return str(scripts_dir / name)

# ----------------------------------------------------------
# Your CASA code goes below here
# ----------------------------------------------------------
EOF
            echo "Created script: $script_path"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use --help for usage."
            exit 1
            ;;
    esac
fi

# ----------------------------------------------------------------------
# Require a subproject name
# ----------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Error: No subproject specified."
    echo "Usage: casa-launcher <subproject> [CASA arguments...]"
    exit 1
fi

subproject="$1"
shift 1  # Remaining arguments are passed directly to CASA

workdir="$CASA_WORKBASE/$subproject"

# ----------------------------------------------------------------------
# Check project directory and ask before creating new one
# ----------------------------------------------------------------------
if [[ ! -d "$workdir" ]]; then
    printf "Project '%s' does not exist under %s.\nDo you want to initialize a new CASA project with this name? (y/n)\n> " "$subproject" "$CASA_WORKBASE"
    read -r reply

    case "$reply" in
        [Yy]|[Yy][Ee][Ss])
            echo "Initializing new project: $workdir"
            mkdir -p "$workdir"
            required_dirs=( "data" "plots" "images" "logs" "lasts" "scripts" )
            for d in "${required_dirs[@]}"; do
                mkdir -p "$workdir/$d"
            done
            write_startup_py "$workdir"
            ;;
        *)
            echo "Aborted. Project was not created."
            exit 1
            ;;
    esac
fi

required_dirs=(
    "data"
    "plots"
    "images"
    "logs"
    "lasts"
    "scripts"
)

for d in "${required_dirs[@]}"; do
    mkdir -p "$workdir/$d"
done

# ----------------------------------------------------------------------
# Locate CASA executable (Linux or macOS)
# ----------------------------------------------------------------------
find_casa() {
    # Prefer whatever is in PATH but ignore aliases and the script itself
    if casa_path="$(type -P casa)"; then
        if [[ "$casa_path" != "$0" ]]; then
            echo "$casa_path"
            return 0
        fi
    fi

    # macOS default application bundle
    if [[ -x "/Applications/CASA.app/Contents/MacOS/casa" ]]; then
        echo "/Applications/CASA.app/Contents/MacOS/casa"
        return 0
    fi

    echo "Error: CASA executable not found." >&2
    echo "Either install CASA or ensure 'casa' is in your PATH." >&2
    exit 1
}

casa_bin="$(find_casa)"

# ----------------------------------------------------------------------
# Move into project workspace
# ----------------------------------------------------------------------
cd "$workdir" || { echo "Error: Cannot access $workdir"; exit 1; }

export DISPLAY="${DISPLAY:-:0}"

# ----------------------------------------------------------------------
# Ensure startup.py exists; if missing, recreate it
# ----------------------------------------------------------------------
if [[ ! -f "$workdir/startup.py" ]]; then
    echo "Warning: startup.py missing in project root; recreating boilerplate."
    write_startup_py "$workdir"
fi

# ----------------------------------------------------------------------
# Detect --startupfile support and launch CASA accordingly
# ----------------------------------------------------------------------
startup_flag=""
if "$casa_bin" --help 2>&1 | grep -q -- "--startupfile"; then
    if [[ -f "$workdir/startup.py" ]]; then
        startup_flag="--startupfile startup.py"
    fi
else
    echo
    echo "NOTE: Your CASA version does not support --startupfile."
    echo "To load your project environment inside CASA, run:"
    echo "    execfile('startup.py')"
    echo "or:"
    echo "    run -i startup.py"
    echo
fi

# Run CASA with or without startupfile
if [[ -n "$startup_flag" ]]; then
    "$casa_bin" $startup_flag "$@"
else
    "$casa_bin" "$@"
fi

# ----------------------------------------------------------------------
# After CASA exits: silently organize log and .last files
# ----------------------------------------------------------------------
shopt -s nullglob

log_files=("$workdir"/*.log)
if (( ${#log_files[@]} )); then
    mv "${log_files[@]}" "$workdir/logs/" 2>/dev/null || true
fi

last_files=("$workdir"/*.last)
if (( ${#last_files[@]} )); then
    mv -f "${last_files[@]}" "$workdir/lasts/" 2>/dev/null || true
fi

shopt -u nullglob
