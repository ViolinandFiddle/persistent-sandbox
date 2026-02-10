# ==============================================================================
# PERSISTENT AGENT SANDBOX - Windows Setup Script
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
# USAGE: Right-click → Run with PowerShell
#        Or: .\setup.ps1 [-Help] [-Version] [-Force] [-Auto]
# ==============================================================================

param(
    [switch]$Force,
    [switch]$Help,
    [switch]$Version,
    [switch]$Auto,
    [switch]$ResetVolume
)

$ScriptVersion = "2.0.0"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.json"
$DevContainerDir = Join-Path $ScriptDir ".devcontainer"
$DevContainerFile = Join-Path $DevContainerDir "devcontainer.json"
$ParentDir = Split-Path -Parent $ScriptDir
$SandboxName = Split-Path -Leaf $ScriptDir

# Named volume for environment persistence (unique per sandbox folder)
$CondaVolumeName = "sandbox-conda-$SandboxName"

# ------------------------------------------------------------------------------
# HELP & VERSION
# ------------------------------------------------------------------------------

if ($Help) {
    Write-Host "Persistent Agent Sandbox Setup Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\setup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help       Show this help message"
    Write-Host "  -Version    Show version information"
    Write-Host "  -Force      Overwrite existing configuration without prompting"
    Write-Host "  -Auto       Non-interactive mode with defaults"
    Write-Host "  -ResetVolume Destroys and re-creates the persistent package volume"
    Write-Host ""
    Write-Host "This script configures the development container."
    exit 0
}

if ($Version) {
    Write-Host "Persistent Agent Sandbox v$ScriptVersion"
    exit 0
}

# ------------------------------------------------------------------------------
# PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------

# Check if running inside container
if ((Test-Path "/.dockerenv") -or ($env:SANDBOX_ACTIVE -eq "true")) {
    Write-Host "Already inside container, skipping setup." -ForegroundColor Yellow
    exit 0
}

# Check Docker is installed and running
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "Docker is running." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: Docker is not running." -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Red
    Write-Host "Download: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# ------------------------------------------------------------------------------
# CHECK EXISTING CONFIG
# ------------------------------------------------------------------------------

if ((Test-Path $ConfigFile) -and (-not $Force)) {
    if ($Auto) {
        Write-Host "Using existing configuration." -ForegroundColor Cyan
        exit 0
    }
    Write-Host ""
    Write-Host "An existing configuration was found." -ForegroundColor Yellow
    $Reconfigure = Read-Host "Would you like to reconfigure? (y/N)"
    if ($Reconfigure -ne "y" -and $Reconfigure -ne "Y") {
        Write-Host "Using existing configuration." -ForegroundColor Cyan
        exit 0
    }
}

# ------------------------------------------------------------------------------
# SETUP WIZARD
# ------------------------------------------------------------------------------

Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PERSISTENT AGENT SANDBOX - Setup Wizard v$ScriptVersion      " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Python Version
if (-not $Auto) {
    Write-Host "Step 1: Python Version" -ForegroundColor Cyan
    Write-Host "[1] Python 3.11 (Recommended - best ML compatibility)"
    Write-Host "[2] Python 3.12"
    Write-Host "[3] Python 3.13"
    $PythonChoice = Read-Host "Enter choice [1]"
    switch ($PythonChoice) {
        "2" { $PythonVersion = "3.12" }
        "3" { $PythonVersion = "3.13" }
        default { $PythonVersion = "3.11" }
    }
}
else { $PythonVersion = "3.11" }

# Step 2: Package Tier (cumulative hierarchy)
if (-not $Auto) {
    Write-Host ""
    Write-Host "Step 2: Package Tier (each tier includes all packages from previous tiers)" -ForegroundColor Cyan
    Write-Host "[1] Core       - NumPy, Pandas, Jupyter, Matplotlib (Default)"
    Write-Host "[2] ML         - + scikit-learn, XGBoost, statsmodels"
    Write-Host "[3] AI         - + PyTorch, JAX, Transformers (CUDA 12.4)"
    Write-Host "[4] Full       - + Dask, Polars, Numba, OpenCV"
    Write-Host "[5] Barebones  - Python only, no packages"
    $BuildChoice = Read-Host "Enter choice [1]"
    switch ($BuildChoice) {
        "2" { $BuildType = "ml" }
        "3" { $BuildType = "ai" }
        "4" { $BuildType = "full" }
        "5" { $BuildType = "barebones" }
        default { $BuildType = "core" }
    }
}
else { $BuildType = "core" }

# Step 3: Optional Add-ons (multi-select)
$AddonR = "false"
$AddonViz = "false"
$AddonNLP = "false"
$AddonQuarto = "false"
$AddonChrome = "false"

if (-not $Auto) {
    Write-Host ""
    Write-Host "Step 3: Optional Add-ons (select multiple, space-separated)" -ForegroundColor Cyan
    Write-Host "  [R]   R Language    - R + IRkernel + tidyverse + ggplot2 (~500MB)"
    Write-Host "  [V]   Visualization - Plotly, Bokeh, Altair, Streamlit (~200MB)"
    Write-Host "  [N]   NLP Tools     - spaCy, NLTK, sentence-transformers (~400MB)"
    Write-Host "  [Q]   Quarto        - Quarto CLI + TinyTeX + PDF Reader (~1GB)"
    Write-Host "  [C]   Chrome        - Google Chrome for automation (~300MB)"
    Write-Host ""
    Write-Host "  Examples: 'R Q' or 'R V N Q C' or press Enter for none" -ForegroundColor DarkGray
    $AddonChoice = Read-Host "Enter add-ons [none]"
    
    # Parse space-separated choices
    $AddonChoice.Split(' ') | ForEach-Object {
        switch ($_.ToUpper()) {
            "R" { $AddonR = "true" }
            "V" { $AddonViz = "true" }
            "N" { $AddonNLP = "true" }
            "Q" { $AddonQuarto = "true" }
            "C" { $AddonChrome = "true" }
        }
    }
    
    # Confirm selections
    $SelectedAddons = @()
    if ($AddonR -eq "true") { $SelectedAddons += "R" }
    if ($AddonViz -eq "true") { $SelectedAddons += "Viz" }
    if ($AddonNLP -eq "true") { $SelectedAddons += "NLP" }
    if ($AddonQuarto -eq "true") { $SelectedAddons += "Quarto" }
    if ($AddonChrome -eq "true") { $SelectedAddons += "Chrome" }
    if ($SelectedAddons.Count -gt 0) {
        Write-Host "  Selected: $($SelectedAddons -join ', ')" -ForegroundColor Green
    }
    else {
        Write-Host "  Selected: None" -ForegroundColor DarkGray
    }
}

# Step 4: LaTeX
if (-not $Auto) {
    Write-Host ""
    Write-Host "Step 4: LaTeX Support (adds ~1GB, enables PDF export from Jupyter)" -ForegroundColor Cyan
    $LatexChoice = Read-Host "Install LaTeX? (y/N) [N]"
    $InstallLatex = if ($LatexChoice -match "^[Yy]$") { "true" } else { "false" }
}
else { $InstallLatex = "false" }

# Resource Check
Write-Host ""
Write-Host "Checking Resources..." -ForegroundColor Cyan
try {
    $DockerMem = docker info --format '{{.MemTotal}}'
    if ($DockerMem -lt 7516192768 -and ($BuildType -eq "ai" -or $BuildType -eq "full")) {
        Write-Host "WARNING: Low Docker Memory detected ($([math]::round($DockerMem / 1GB, 1)) GB)" -ForegroundColor Yellow
        Write-Host "   The AI and Full tiers require at least 8GB of RAM." -ForegroundColor Yellow
        if (-not $Auto) {
            $Continue = Read-Host "   Continue anyway? (y/N) [N]"
            if ($Continue -ne "y" -and $Continue -ne "Y") { exit 1 }
        }
    }
    else {
        Write-Host "  Docker Memory: $([math]::round($DockerMem / 1GB, 1)) GB - OK" -ForegroundColor Green
    }
}
catch {
    Write-Host "  Could not determine Docker memory limits." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# DISCOVER SIBLING DIRECTORIES (ALL - NOT JUST GIT REPOS)
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "Discovering Sibling Folders..." -ForegroundColor Cyan
$Folders = @()
Get-ChildItem -Path $ParentDir -Directory | ForEach-Object {
    $DirName = $_.Name
    # Exclude the sandbox folder itself
    if ($DirName -ne $SandboxName) {
        # Check if it's a git repo and store both name and git status
        $HasGit = Test-Path (Join-Path $_.FullName ".git")
        $Folders += @{ Name = $DirName; HasGit = $HasGit }
        $IsGitLabel = if ($HasGit) { " (git)" } else { "" }
        Write-Host "  Found: $DirName$IsGitLabel" -ForegroundColor Green
    }
}

if ($Folders.Count -eq 0) {
    Write-Host "  No sibling folders found." -ForegroundColor Yellow
}
else {
    Write-Host ""
    Write-Host "Discovered $($Folders.Count) folder(s) to mount." -ForegroundColor Cyan
}

# ------------------------------------------------------------------------------
# SAVE CONFIG.JSON
# ------------------------------------------------------------------------------

$Config = @{
    python_version     = $PythonVersion
    build_type         = $BuildType
    install_latex      = ($InstallLatex -eq "true")
    addon_r            = ($AddonR -eq "true")
    addon_viz          = ($AddonViz -eq "true")
    addon_nlp          = ($AddonNLP -eq "true")
    addon_quarto       = ($AddonQuarto -eq "true")
    addon_chrome       = ($AddonChrome -eq "true")
    discovered_folders = $Folders
    created_at         = (Get-Date -Format "o")
} | ConvertTo-Json -Depth 3
$Config | Out-File -FilePath $ConfigFile -Encoding UTF8
Write-Host ""
Write-Host "Saved: config.json" -ForegroundColor Green

# ------------------------------------------------------------------------------
# GENERATE DEVCONTAINER.JSON
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "Generating devcontainer.json..." -ForegroundColor Cyan

# Ensure .devcontainer directory exists
if (-not (Test-Path $DevContainerDir)) {
    New-Item -ItemType Directory -Path $DevContainerDir -Force | Out-Null
}

# Create empty directory for masking .git folders
$GitMaskDir = Join-Path $DevContainerDir "empty_git_mask"
if (-not (Test-Path $GitMaskDir)) {
    New-Item -ItemType Directory -Path $GitMaskDir -Force | Out-Null
}

# Build mounts array
$MountsList = @()

# Add Named Volume for Conda environment persistence
$MountsList += "        `"source=$CondaVolumeName,target=/opt/conda,type=volume`""

# Add bind mounts for each sibling folder + conditionally shadow their .git directories
foreach ($Folder in $Folders) {
    $FolderName = $Folder.Name
    # Convert any backslashes to forward slashes for Docker
    $EscapedFolder = $FolderName -replace '\\', '/' -replace '"', '\"'
    # Bind mount the folder
    $MountsList += "        `"source=`${localWorkspaceFolder}/../$EscapedFolder,target=/workspaces/$EscapedFolder,type=bind`""
    # Shadow .git with empty read-only bind mount ONLY if folder is a git repo
    if ($Folder.HasGit) {
        $MountsList += "        `"source=`${localWorkspaceFolder}/.devcontainer/empty_git_mask,target=/workspaces/$EscapedFolder/.git,type=bind,readonly`""
    }
}

# Join mounts
$MountsString = if ($MountsList.Count -gt 0) { $MountsList -join ",`n" } else { "" }

# Build extensions list - Python, Jupyter, but NO Git extensions
$ExtensionsList = @(
    "        `"ms-python.python`"",
    "        `"ms-python.vscode-pylance`"",
    "        `"ms-toolsai.jupyter`"",
    "        `"ms-toolsai.vscode-jupyter-cell-tags`"",
    "        `"ms-toolsai.vscode-jupyter-slideshow`""
)

# Add R extension if R add-on is selected
if ($AddonR -eq "true") {
    $ExtensionsList += "        `"REditorSupport.r`""
}

$ExtensionsString = $ExtensionsList -join ",`n"

# Build settings JSON - base settings for all configurations
$SettingsContent = @"
                "git.enabled": false,
                "git.autoRepositoryDetection": false,
                "git.autofetch": false,
                "python.defaultInterpreterPath": "/opt/conda/envs/sandbox/bin/python",
                "terminal.integrated.defaultProfile.linux": "bash"
"@

# Add R language server settings if R add-on is selected
if ($AddonR -eq "true") {
    $SettingsContent += @"
,
                "r.rpath.linux": "/opt/conda/envs/sandbox/bin/R",
                "r.lsp.enabled": true,
                "r.lsp.diagnostics": true,
                "r.lsp.path": "/opt/conda/envs/sandbox/bin/R"
"@
}

# Generate the devcontainer.json content
$DevContainerContent = @"
{
    "name": "Persistent Agent Sandbox",
    "build": {
        "context": "..",
        "dockerfile": "Dockerfile",
        "args": {
            "PYTHON_VERSION": "$PythonVersion",
            "BUILD_TYPE": "$BuildType",
            "INSTALL_LATEX": "$InstallLatex",
            "ADDON_R": "$AddonR",
            "ADDON_VIZ": "$AddonViz",
            "ADDON_NLP": "$AddonNLP",
            "ADDON_QUARTO": "$AddonQuarto",
            "ADDON_CHROME": "$AddonChrome"
        }
    },
    "mounts": [
$MountsString
    ],
    "workspaceFolder": "/workspaces/$SandboxName",
    "remoteUser": "root",
    "customizations": {
        "vscode": {
            "extensions": [
$ExtensionsString
            ],
            "settings": {
$SettingsContent
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
"@

# Write to file
$DevContainerContent | Out-File -FilePath $DevContainerFile -Encoding UTF8
Write-Host "Saved: .devcontainer/devcontainer.json" -ForegroundColor Green

# ------------------------------------------------------------------------------
# GENERATE WORKSPACE.CODE-WORKSPACE
# ------------------------------------------------------------------------------

$WorkspaceFile = Join-Path $ScriptDir "workspace.code-workspace"
Write-Host ""
Write-Host "Generating workspace.code-workspace..." -ForegroundColor Cyan

# Build folders array for workspace
$WorkspaceFolders = @()
$WorkspaceFolders += @{ name = "Sandbox"; path = "." }
foreach ($Folder in $Folders) {
    $FolderName = $Folder.Name
    $WorkspaceFolders += @{ name = $FolderName; path = "/workspaces/$FolderName" }
}

$WorkspaceContent = @{
    folders  = $WorkspaceFolders
    settings = @{
        "git.enabled"                   = $false
        "git.autoRepositoryDetection"   = $false
        "git.autofetch"                 = $false
        "python.defaultInterpreterPath" = "/opt/conda/envs/sandbox/bin/python"
        "files.autoSave"                = "afterDelay"
    }
} | ConvertTo-Json -Depth 3

$WorkspaceContent | Out-File -FilePath $WorkspaceFile -Encoding UTF8
Write-Host "Saved: workspace.code-workspace" -ForegroundColor Green

# ------------------------------------------------------------------------------
# CREATE DOCKER NAMED VOLUME (if not exists)
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "Checking Named Volume..." -ForegroundColor Cyan
try {
    $VolumeExists = docker volume ls --format "{{.Name}}" | Select-String -Pattern "^$CondaVolumeName$"
    
    # RESET FLOW
    if ($VolumeExists) {
        $DoReset = $ResetVolume

        # Interactive Wizard Prompt
        if (-not $DoReset -and -not $Auto) {
            Write-Host "  Found existing volume: $CondaVolumeName" -ForegroundColor Yellow
            $ResetChoice = Read-Host "  Reset (wipe) this volume? (y/N) [N]"
            if ($ResetChoice -match "^[Yy]$") { $DoReset = $true }
        }

        if ($DoReset) {
            # SAFETY GUARD
            Write-Host ""
            Write-Host "⚠️  WARNING: DESTRUCTIVE ACTION" -ForegroundColor Red
            Write-Host "   You are about to DELETE the persistent volume '$CondaVolumeName'." -ForegroundColor Red
            Write-Host "   ALL installed packages and environments in this volume will be LOST." -ForegroundColor Red
            Write-Host "   This cannot be undone." -ForegroundColor Red
            
            if (-not $Force) {
                Write-Host ""
                $Confirmation = Read-Host "   Type 'DELETE' to confirm"
                if ($Confirmation -ne "DELETE") {
                    Write-Host "   ❌ Action cancelled. Volume preserved." -ForegroundColor Green
                    $DoReset = $false
                }
            }
            
            if ($DoReset) {
                Write-Host "   Removing volume..." -ForegroundColor Cyan
                docker volume rm $CondaVolumeName | Out-Null
                Write-Host "   ✓ Volume removed." -ForegroundColor Green
                $VolumeExists = $null # Force checking/creation again
            }
        }
    }

    if (-not $VolumeExists) {
        # DO NOT manually create the volume. 
        # If we create it here, it starts empty.
        # We must let Docker create it during container startup so it copies 
        # the /opt/conda contents from the image into the volume.
        Write-Host "  Volume will be created by Docker on first run (preserving image packages)." -ForegroundColor Green
    }
    else {
        Write-Host "  Volume exists: $CondaVolumeName (packages preserved)" -ForegroundColor Green
    }
}
catch {
    Write-Host "  Volume check skipped." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Setup Complete!                                              " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Python Version:  $PythonVersion"
Write-Host "  Package Tier:    $BuildType"
Write-Host "  LaTeX Support:   $InstallLatex"
Write-Host "  Add-ons:         R=$AddonR, Viz=$AddonViz, NLP=$AddonNLP, Quarto=$AddonQuarto, Chrome=$AddonChrome"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Open this folder in VS Code or Antigravity"
Write-Host "  2. Click 'Reopen in Container' when prompted"
Write-Host "  3. Wait for the build (first time: 5-15 min)"
Write-Host ""
Write-Host "SECURITY: Git is blocked inside the container." -ForegroundColor Yellow
Write-Host "          Use git on your HOST machine only." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
