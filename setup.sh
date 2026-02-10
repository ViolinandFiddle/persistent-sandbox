#!/bin/bash
# ==============================================================================
# PERSISTENT AGENT SANDBOX - Mac/Linux Setup Script
# ==============================================================================
# PURPOSE: Configures the sandbox with your preferences and discovers sibling folders.
#
# FEATURES:
#   - Python version selection (3.11, 3.12, 3.13)
#   - Package tier selection (Barebones → Core → ML → AI → Full)
#   - Optional add-ons: R, Visualization, NLP (multi-select)
#   - LaTeX support for Jupyter PDF export
#   - Auto-discovery of ALL sibling folders
#   - Named volume for persistent packages
#
# USAGE: ./setup.sh [-h|--help] [-v|--version] [-f|--force] [--auto]
# ==============================================================================

set -e

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.json"
DEVCONTAINER_DIR="${SCRIPT_DIR}/.devcontainer"
DEVCONTAINER_FILE="${DEVCONTAINER_DIR}/devcontainer.json"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SANDBOX_NAME="$(basename "$SCRIPT_DIR")"

# Named volume for environment persistence (unique per sandbox folder)
CONDA_VOLUME_NAME="sandbox-conda-${SANDBOX_NAME}"

# Parse flags
FORCE=false
AUTO=false
RESET_VOLUME=false

# ------------------------------------------------------------------------------
# HELP & VERSION
# ------------------------------------------------------------------------------

show_help() {
    echo "Persistent Agent Sandbox Setup Script"
    echo ""
    echo "Usage: ./setup.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --version   Show version information"
    echo "  -f, --force     Overwrite existing configuration without prompting"
    echo "  --auto          Non-interactive mode with defaults"
    echo "  --reset-volume  Destroys and re-creates the persistent package volume"
    echo ""
    echo "This script configures the development container."
    exit 0
}

show_version() {
    echo "Persistent Agent Sandbox v${VERSION}"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help ;;
        -v|--version) show_version ;;
        -f|--force) FORCE=true; shift ;;
        --auto) AUTO=true; shift ;;
        --reset-volume) RESET_VOLUME=true; shift ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
done

# ------------------------------------------------------------------------------
# PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------

# Check if running inside container
if [ -f "/.dockerenv" ] || [ "$SANDBOX_ACTIVE" = "true" ]; then
    echo "Already inside container, skipping setup."
    exit 0
fi

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo ""
    echo "ERROR: Docker is not running."
    echo "Please start Docker Desktop and try again."
    echo "Download: https://www.docker.com/products/docker-desktop/"
    exit 1
fi
echo "✓ Docker is running."

# ------------------------------------------------------------------------------
# CHECK EXISTING CONFIG
# ------------------------------------------------------------------------------

if [ -f "$CONFIG_FILE" ] && [ "$FORCE" != "true" ]; then
    if [ "$AUTO" = "true" ]; then
        echo "Using existing configuration."
        exit 0
    fi
    echo ""
    echo "An existing configuration was found."
    read -p "Would you like to reconfigure? (y/N): " RECONFIGURE
    if [ "$RECONFIGURE" != "y" ] && [ "$RECONFIGURE" != "Y" ]; then
        echo "Using existing configuration."
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# SETUP WIZARD
# ------------------------------------------------------------------------------

clear
echo "================================================================"
echo "  PERSISTENT AGENT SANDBOX - Setup Wizard v${VERSION}"
echo "================================================================"
echo ""

# Step 1: Python Version
if [ "$AUTO" != "true" ]; then
    echo "Step 1: Python Version"
    echo "[1] Python 3.11 (Recommended - best ML compatibility)"
    echo "[2] Python 3.12"
    echo "[3] Python 3.13"
    read -p "Enter choice [1]: " PYTHON_CHOICE
    case $PYTHON_CHOICE in
        2) PYTHON_VERSION="3.12" ;;
        3) PYTHON_VERSION="3.13" ;;
        *) PYTHON_VERSION="3.11" ;;
    esac
else
    PYTHON_VERSION="3.11"
fi

# Step 2: Package Tier (cumulative hierarchy)
if [ "$AUTO" != "true" ]; then
    echo ""
    echo "Step 2: Package Tier (each tier includes all packages from previous tiers)"
    echo "[1] Core       - NumPy, Pandas, Jupyter, Matplotlib (Default)"
    echo "[2] ML         - + scikit-learn, XGBoost, statsmodels"
    echo "[3] AI         - + PyTorch, JAX, Transformers (CUDA 12.4)"
    echo "[4] Full       - + Dask, Polars, Numba, OpenCV"
    echo "[5] Barebones  - Python only, no packages"
    read -p "Enter choice [1]: " BUILD_CHOICE
    case $BUILD_CHOICE in
        2) BUILD_TYPE="ml" ;;
        3) BUILD_TYPE="ai" ;;
        4) BUILD_TYPE="full" ;;
        5) BUILD_TYPE="barebones" ;;
        *) BUILD_TYPE="core" ;;
    esac
else
    BUILD_TYPE="core"
fi

# Step 3: Optional Add-ons (multi-select)
ADDON_R="false"
ADDON_VIZ="false"
ADDON_NLP="false"
ADDON_QUARTO="false"
ADDON_CHROME="false"

if [ "$AUTO" != "true" ]; then
    echo ""
    echo "Step 3: Optional Add-ons (select multiple, space-separated)"
    echo "  [R]   R Language    - R + IRkernel + tidyverse + ggplot2 (~500MB)"
    echo "  [V]   Visualization - Plotly, Bokeh, Altair, Streamlit (~200MB)"
    echo "  [N]   NLP Tools     - spaCy, NLTK, sentence-transformers (~400MB)"
    echo "  [Q]   Quarto        - Quarto CLI + TinyTeX + PDF Reader (~1GB)"
    echo "  [C]   Chrome        - Google Chrome for automation (~300MB)"
    echo ""
    echo "  Examples: 'R Q' or 'R V N Q C' or press Enter for none"
    read -p "Enter add-ons [none]: " ADDON_CHOICE

    # Parse space-separated choices
    for choice in $ADDON_CHOICE; do
        case "$choice" in
            R|r) ADDON_R="true" ;;
            V|v) ADDON_VIZ="true" ;;
            N|n) ADDON_NLP="true" ;;
            Q|q) ADDON_QUARTO="true" ;;
            C|c) ADDON_CHROME="true" ;;
        esac
    done

    # Confirm selections
    SELECTED_ADDONS=""
    [ "$ADDON_R" = "true" ] && SELECTED_ADDONS+="R "
    [ "$ADDON_VIZ" = "true" ] && SELECTED_ADDONS+="Viz "
    [ "$ADDON_NLP" = "true" ] && SELECTED_ADDONS+="NLP "
    [ "$ADDON_QUARTO" = "true" ] && SELECTED_ADDONS+="Quarto "
    [ "$ADDON_CHROME" = "true" ] && SELECTED_ADDONS+="Chrome "
    if [ -n "$SELECTED_ADDONS" ]; then
        echo "  Selected: $SELECTED_ADDONS"
    else
        echo "  Selected: None"
    fi
fi

# Step 4: LaTeX
if [ "$AUTO" != "true" ]; then
    echo ""
    echo "Step 4: LaTeX Support (adds ~1GB, enables PDF export from Jupyter)"
    read -p "Install LaTeX? (y/N) [N]: " LATEX_CHOICE
    if [ "$LATEX_CHOICE" = "y" ] || [ "$LATEX_CHOICE" = "Y" ]; then
        INSTALL_LATEX="true"
    else
        INSTALL_LATEX="false"
    fi
else
    INSTALL_LATEX="false"
fi

# Resource Check
echo ""
echo "Checking Resources..."
DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
if [ "$DOCKER_MEM" -lt 7516192768 ] && { [ "$BUILD_TYPE" = "ai" ] || [ "$BUILD_TYPE" = "full" ]; }; then
    # Pure bash arithmetic (no awk needed - works on Git Bash)
    MEM_GB=$((DOCKER_MEM / 1073741824))
    echo "⚠️  WARNING: Low Docker Memory detected (~${MEM_GB} GB)"
    echo "   The AI and Full tiers require at least 8GB of RAM."
    if [ "$AUTO" != "true" ]; then
        read -p "   Continue anyway? (y/N) [N]: " CONTINUE
        if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
            exit 1
        fi
    fi
elif [ "$DOCKER_MEM" -ne 0 ]; then
    # Pure bash arithmetic (no awk needed - works on Git Bash)
    MEM_GB=$((DOCKER_MEM / 1073741824))
    echo "  ✓ Docker Memory: ~${MEM_GB} GB"
fi

# ------------------------------------------------------------------------------
# DISCOVER SIBLING DIRECTORIES (ALL - NOT JUST GIT REPOS)
# ------------------------------------------------------------------------------

echo ""
echo "Discovering Sibling Folders..."
FOLDERS=()
declare -A FOLDER_HAS_GIT  # Associative array to track git status
for dir in "$PARENT_DIR"/*/; do
    dir_name=$(basename "$dir")
    # Exclude the sandbox folder itself
    if [ "$dir_name" != "$SANDBOX_NAME" ]; then
        FOLDERS+=("$dir_name")
        # Check if it's a git repo and store status
        if [ -d "$dir/.git" ]; then
            FOLDER_HAS_GIT["$dir_name"]="true"
            echo "  Found: $dir_name (git)"
        else
            FOLDER_HAS_GIT["$dir_name"]="false"
            echo "  Found: $dir_name"
        fi
    fi
done

if [ ${#FOLDERS[@]} -eq 0 ]; then
    echo "  No sibling folders found."
else
    echo ""
    echo "Discovered ${#FOLDERS[@]} folder(s) to mount."
fi

# ------------------------------------------------------------------------------
# SAVE CONFIG.JSON
# ------------------------------------------------------------------------------

FOLDERS_JSON=$(printf '"%s",' "${FOLDERS[@]}" | sed 's/,$//')
cat > "$CONFIG_FILE" << EOF
{
    "python_version": "$PYTHON_VERSION",
    "build_type": "$BUILD_TYPE",
    "install_latex": $INSTALL_LATEX,
    "addon_r": $ADDON_R,
    "addon_viz": $ADDON_VIZ,
    "addon_nlp": $ADDON_NLP,
    "addon_quarto": $ADDON_QUARTO,
    "addon_chrome": $ADDON_CHROME,
    "discovered_folders": [$FOLDERS_JSON],
    "created_at": "$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)"
}
EOF
echo ""
echo "✓ Saved: config.json"

# ------------------------------------------------------------------------------
# GENERATE DEVCONTAINER.JSON
# ------------------------------------------------------------------------------

echo ""
echo "Generating devcontainer.json..."

# Ensure .devcontainer directory exists
mkdir -p "$DEVCONTAINER_DIR"

# Create empty directory for masking .git folders
GIT_MASK_DIR="${DEVCONTAINER_DIR}/empty_git_mask"
mkdir -p "$GIT_MASK_DIR"

# Build mounts JSON array
MOUNTS_JSON=""

# Add Named Volume for Conda environment persistence
MOUNTS_JSON+="        \"source=${CONDA_VOLUME_NAME},target=/opt/conda,type=volume\""

# Add bind mounts for each sibling folder + conditionally shadow their .git directories
for folder in "${FOLDERS[@]}"; do
    escaped_folder=$(echo "$folder" | sed 's/\\/\\\\/g; s/"/\\"/g')
    MOUNTS_JSON+=","$'\n'
    MOUNTS_JSON+="        \"source=\${localWorkspaceFolder}/../${escaped_folder},target=/workspaces/${escaped_folder},type=bind\""
    # Shadow .git with empty read-only bind mount ONLY if folder is a git repo
    if [ "${FOLDER_HAS_GIT[$folder]}" = "true" ]; then
        MOUNTS_JSON+=","$'\n'
        MOUNTS_JSON+="        \"source=\${localWorkspaceFolder}/.devcontainer/empty_git_mask,target=/workspaces/${escaped_folder}/.git,type=bind,readonly\""
    fi
done

# Build extensions list (Empty by default per user request)
EXTENSIONS_JSON=""

# Build settings JSON - base settings for all configurations
SETTINGS_JSON='"git.enabled": false,
                "git.autoRepositoryDetection": false,
                "git.autofetch": false,
                "python.defaultInterpreterPath": "/opt/conda/envs/sandbox/bin/python",
                "terminal.integrated.defaultProfile.linux": "bash"'

# Add R language server settings if R add-on is selected
if [ "$ADDON_R" = "true" ]; then
    SETTINGS_JSON+=',
                "r.rpath.linux": "/opt/conda/envs/sandbox/bin/R",
                "r.lsp.enabled": true,
                "r.lsp.diagnostics": true,
                "r.lsp.path": "/opt/conda/envs/sandbox/bin/R"'
fi

# Generate the devcontainer.json content
cat > "$DEVCONTAINER_FILE" << DEVCONTAINER_EOF
{
    "name": "Persistent Agent Sandbox",
    "build": {
        "context": "..",
        "dockerfile": "Dockerfile",
        "args": {
            "PYTHON_VERSION": "${PYTHON_VERSION}",
            "BUILD_TYPE": "${BUILD_TYPE}",
            "INSTALL_LATEX": "${INSTALL_LATEX}",
            "ADDON_R": "${ADDON_R}",
            "ADDON_VIZ": "${ADDON_VIZ}",
            "ADDON_NLP": "${ADDON_NLP}",
            "ADDON_QUARTO": "${ADDON_QUARTO}",
            "ADDON_CHROME": "${ADDON_CHROME}"
        }
    },
    "mounts": [
${MOUNTS_JSON}
    ],
    "workspaceFolder": "/workspaces/${SANDBOX_NAME}",
    "remoteUser": "root",
    "customizations": {
        "vscode": {
            "extensions": [
${EXTENSIONS_JSON}
            ],
            "settings": {
                ${SETTINGS_JSON}
            }
        }
    },
    "containerEnv": {
        "SANDBOX_ACTIVE": "true",
        "GIT_AUTHOR_EMAIL": "sandbox@localhost",
        "GIT_COMMITTER_EMAIL": "sandbox@localhost"
    },
    "postCreateCommand": "echo '🛡️ Sandbox ready! Git is blocked for your protection.'"
}
DEVCONTAINER_EOF

echo "✓ Saved: .devcontainer/devcontainer.json"

# ------------------------------------------------------------------------------
# GENERATE WORKSPACE.CODE-WORKSPACE
# ------------------------------------------------------------------------------

WORKSPACE_FILE="${SCRIPT_DIR}/workspace.code-workspace"
echo ""
echo "Generating workspace.code-workspace..."

# Build folders array for workspace
FOLDERS_WORKSPACE_JSON='        { "name": "Sandbox", "path": "." }'
for folder in "${FOLDERS[@]}"; do
    escaped_folder=$(echo "$folder" | sed 's/\\/\\\\/g; s/"/\\"/g')
    FOLDERS_WORKSPACE_JSON+=","$'\n'"        { \"name\": \"${escaped_folder}\", \"path\": \"/workspaces/${escaped_folder}\" }"
done

cat > "$WORKSPACE_FILE" << WORKSPACE_EOF
{
    "folders": [
$FOLDERS_WORKSPACE_JSON
    ],
    "settings": {
        "git.enabled": false,
        "git.autoRepositoryDetection": false,
        "git.autofetch": false,
        "python.defaultInterpreterPath": "/opt/conda/envs/sandbox/bin/python",
        "files.autoSave": "afterDelay"
    }
}
WORKSPACE_EOF

echo "✓ Saved: workspace.code-workspace"

# ------------------------------------------------------------------------------
# CREATE DOCKER NAMED VOLUME (if not exists)
# ------------------------------------------------------------------------------

echo ""
echo ""
echo "Checking Named Volume..."
if docker volume ls --format "{{.Name}}" | grep -q "^${CONDA_VOLUME_NAME}$"; then
    VOLUME_EXISTS=true
else
    VOLUME_EXISTS=false
fi

# RESET FLOW
if [ "$VOLUME_EXISTS" = "true" ]; then
    DO_RESET=$RESET_VOLUME

    # Interactive Wizard Prompt
    if [ "$DO_RESET" != "true" ] && [ "$AUTO" != "true" ]; then
        echo "  Found existing volume: ${CONDA_VOLUME_NAME}"
        read -p "  Reset (wipe) this volume? (y/N) [N]: " RESET_CHOICE
        if [ "$RESET_CHOICE" = "y" ] || [ "$RESET_CHOICE" = "Y" ]; then
            DO_RESET=true
        fi
    fi

    if [ "$DO_RESET" = "true" ]; then
        # SAFETY GUARD
        echo ""
        echo "⚠️  WARNING: DESTRUCTIVE ACTION"
        echo "   You are about to DELETE the persistent volume '${CONDA_VOLUME_NAME}'."
        echo "   ALL installed packages and environments in this volume will be LOST."
        echo "   This cannot be undone."

        if [ "$FORCE" != "true" ]; then
            echo ""
            read -p "   Type 'DELETE' to confirm: " CONFIRMATION
            if [ "$CONFIRMATION" != "DELETE" ]; then
                echo "   ❌ Action cancelled. Volume preserved."
                DO_RESET=false
            fi
        fi

        if [ "$DO_RESET" = "true" ]; then
            echo "   Removing volume..."
            docker volume rm "${CONDA_VOLUME_NAME}" > /dev/null
            echo "   ✓ Volume removed."
            VOLUME_EXISTS=false # Force checking/creation again
        fi
    fi
fi

if [ "$VOLUME_EXISTS" != "true" ]; then
    # DO NOT manually create the volume.
    # If we create it here, it starts empty.
    # We must let Docker create it during container startup so it copies
    # the /opt/conda contents from the image into the volume.
    echo "  ✓ Volume will be created by Docker on first run (preserving image packages)"
else
    echo "  ✓ Volume exists: ${CONDA_VOLUME_NAME} (packages preserved)"
fi

# ------------------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------------------

echo ""
echo "================================================================"
echo "  Setup Complete!"
echo "================================================================"
echo ""
echo "Configuration:"
echo "  Python Version:  $PYTHON_VERSION"
echo "  Package Tier:    $BUILD_TYPE"
echo "  LaTeX Support:   $INSTALL_LATEX"
echo "  Add-ons:         R=$ADDON_R, Viz=$ADDON_VIZ, NLP=$ADDON_NLP, Quarto=$ADDON_QUARTO, Chrome=$ADDON_CHROME"
echo ""
echo "Next Steps:"
echo "  1. Open this folder in VS Code or Antigravity"
echo "  2. Click 'Reopen in Container' when prompted"
echo "  3. Wait for the build (first time: 5-15 min)"
echo ""
echo "🛡️ SECURITY: Git is blocked inside the container."
echo "             Use git on your HOST machine only."
echo ""
