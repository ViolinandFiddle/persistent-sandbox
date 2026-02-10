# 🛡️ Persistent Agent Sandbox

[![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-green.svg)]()
[![Python: 3.11--3.13](https://img.shields.io/badge/Python-3.11--3.13-blue.svg)](https://python.org)
[![CUDA: 12.4](https://img.shields.io/badge/CUDA-12.4-76B900.svg)](https://developer.nvidia.com/cuda-toolkit)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

> **A secure, containerized development environment for AI coding assistants with persistent package storage.**

This sandbox provides an isolated environment where AI agents can safely read, write, and execute code **without any risk of accidental Git commits or pushes**. Git operations are blocked inside the container, protecting your remote repositories from unintended changes.

### 🛠️ Built-in Tools

#### **Robust Reference Fetcher** (`/robust_reference_fetcher`)
A high-reliability acquisition engine for scientific literature. It bypasses common scraping obstacles (bot detection, JS-rendering) to ensure AI agents have access to the latest research.
- **Zero-Failure Logic**: Sequential fallback from `urllib` to **True Headless Chrome** (`--print-to-pdf`) for bulletproof acquisition.
- **Smart Recovery**: Automatically scans local directories to recover existing papers before attempting new downloads.
- **Technical Summarization**: Integrated hooks for generating PhD-level summaries from downloaded PDFs.
- **Pure Python**: Standard library implementation with minimal dependencies (requires `google-chrome-stable`).

---

## ⚡ Quick Start

### Prerequisites

- **Docker Desktop** installed and running ([Download](https://www.docker.com/products/docker-desktop/))
- **IDE**: [Antigravity](https://antigravity.dev/) (Recommended) or VS Code with *Dev Containers* extension

### Setup (2 Minutes)

**1. Position Your Folders**

Place the sandbox alongside any project folders you want to access:

```
📁 my-projects/
├── 📁 persistent-sandbox/    ← This folder
├── 📁 project-alpha/         ← Auto-discovered & mounted
├── 📁 research-data/         ← Auto-discovered (non-Git folders work too!)
└── 📁 another-project/       ← Auto-discovered
```

**2. Run Setup**

| Platform | Command |
|----------|---------|
| **macOS / Linux** | `./setup.sh` |
| **Windows** (Git Bash or WSL) | `./setup.sh` |
| **Windows** (PowerShell) | `.\setup.ps1` |

The setup wizard guides you through:
- Python version (3.11, 3.12, or 3.13)
- Package tier (Barebones → Core → ML → AI → Full)
- Optional add-ons (R, Visualization, NLP)
- LaTeX support for PDF export

**3. Launch**

- Open the `persistent-sandbox` folder in your IDE
- Click **Reopen in Container** when prompted
- Wait for the build (first run: 5-15 minutes, rebuilds: ~30 seconds)

---

## 📦 Package Tiers

Each tier includes all packages from previous tiers:

| Tier | Key Packages | Use Case |
|------|--------------|----------|
| **Barebones** | Python only | Fresh start, manual installs |
| **Core** (Default) | NumPy, Pandas, Jupyter, Matplotlib, SciPy | General data analysis |
| **ML** | + scikit-learn, XGBoost, statsmodels, SHAP | Classical machine learning |
| **AI** | + PyTorch, JAX, Transformers (CUDA 12.4) | Deep learning, GPU compute |
| **Full** | + Dask, Polars, Numba, OpenCV | Big data, performance |

### Optional Add-ons

Select any combination during setup:

| Add-on | Key Packages | Size |
|--------|--------------|------|
| **R** | R language, IRkernel, tidyverse, ggplot2 | ~500MB |
| **Viz** | Plotly, Bokeh, Altair, Streamlit, Folium | ~200MB |
| **NLP** | spaCy, NLTK, sentence-transformers, Gensim | ~400MB |

---

## 🔒 Security Architecture

Git is **blocked at multiple layers** to prevent accidental commits or pushes:

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST MACHINE                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ project-a/  │  │ project-b/  │  │   persistent-sandbox/   │  │
│  │   .git/ ✓   │  │   .git/ ✓   │  │      (this repo)        │  │
│  └──────┬──────┘  └──────┬──────┘  └────────────┬────────────┘  │
│         │  Git works     │                      │               │
│         │  normally      │                      │               │
└─────────┼────────────────┼──────────────────────┼───────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CONTAINER (Sandbox)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ project-a/  │  │ project-b/  │  │   persistent-sandbox/   │  │
│  │  .git/ 🚫   │  │  .git/ 🚫   │  │    (workspace root)     │  │
│  │ (shadowed)  │  │ (shadowed)  │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                                                                 │
│  🛡️ git command → "Git is BLOCKED for your protection"         │
│  📁 Files are editable, changes persist to host                │
│  📚 Tools: Robust Reference Fetcher ready in `/robust...`      │
└─────────────────────────────────────────────────────────────────┘
```

### Protection Layers

| Layer | Mechanism |
|-------|-----------|
| **Binary Block** | The `git` command is replaced with a blocking script |
| **Shadow Mounts** | All `.git` directories are mounted as empty `tmpfs` volumes |
| **IDE Settings** | Git extensions and features are disabled in container settings |
| **Named Volume** | Conda environment persists in isolated storage |

---

##  Persistent Packages

Installed packages survive container rebuilds thanks to a **Docker Named Volume**:

| Build | Time | Packages |
|-------|------|----------|
| First | 5-15 min | Full installation |
| Rebuilds | ~30 sec | Reuses cached packages |

The volume `sandbox-conda-<folder-name>` (e.g., `sandbox-conda-persistent-sandbox`) stores `/opt/conda`, so your `pip install` and `conda install` commands persist across rebuilds. Each sandbox instance gets its own volume.

---

## 🚀 Working in the Sandbox

### Maximum Velocity Mode (Antigravity)

Since Git is blocked, you can safely enable full agent autonomy:

1. **Settings** (`Ctrl+,`) → Search **Agent Review Policy** → `Always Proceed`
2. **Settings** → Search **Terminal Execution Policy** → `Always Proceed`

> ⚠️ **Remember**: Reset these settings when returning to normal projects outside the sandbox.

### Using Git

Git operations must be performed on your **host machine**:

1. Exit the container (close IDE or use "Reopen Folder Locally")
2. Use your normal terminal to `git add`, `commit`, `push`
3. Reopen in container to continue working

---

## 🔧 Reconfiguration

To change settings or scan for new folders:

```bash
# Re-run setup (Bash - all platforms)
./setup.sh --force

# Or on Windows PowerShell
.\setup.ps1 -Force
```

Then rebuild the container: `Ctrl+Shift+P` → *Dev Containers: Rebuild Container*

---

## ❓ Troubleshooting

### Docker is not running
Ensure Docker Desktop is active before running setup scripts.

### Folders not appearing in container
Sibling folders must exist *before* running setup. Run setup again to discover new folders.

### Build fails with memory error
AI and Full tiers require 8GB+ RAM. Adjust in Docker Desktop: Settings → Resources → Memory.

### GPU not detected
Ensure you have:
- NVIDIA GPU with updated drivers
- NVIDIA Container Toolkit installed
- Docker configured for GPU access

### Reset persistent volume
To start fresh with a clean environment:
```bash
# Replace <folder-name> with your sandbox folder name
docker volume rm sandbox-conda-<folder-name>

# Example for default folder name:
docker volume rm sandbox-conda-persistent-sandbox
```

---

## 📁 Project Structure

```
persistent-sandbox/
├── .devcontainer/
│   ├── Dockerfile              # Container build definition
│   ├── devcontainer.json       # [Generated] Container config
│   └── environments/           # Conda environment files
│       ├── core.yml            # Tier 1: Scientific stack
│       ├── ml.yml              # Tier 2: Machine learning
│       ├── ai.yml              # Tier 3: Deep learning (CUDA 12.4)
│       ├── full.yml            # Tier 4: Big data & performance
│       ├── addon-r.yml         # Add-on: R language
│       ├── addon-viz.yml       # Add-on: Visualization
│       └── addon-nlp.yml       # Add-on: NLP tools
├── project_logs/               # Development documentation
│   ├── changes.md              # File modification history
│   ├── issue_tracker.md        # Known issues and fixes
│   └── dev_process.md          # Development narrative
├── setup.sh                    # Setup script (Bash - all platforms)
├── setup.ps1                   # Setup script (PowerShell - Windows)
├── config.json                 # [Generated] Your configuration
├── workspace.code-workspace    # [Generated] Multi-folder workspace
├── robust_reference_fetcher/   # 🛠️ Built-in: Zero-Failure reference fetcher
└── README.md                   # This file
```

---

## 📚 Glossary

| Term | Definition |
|------|------------|
| **Bind mount** | A link that connects a folder on your computer (host) into the container, so changes in one appear in both |
| **Container** | A lightweight, isolated environment that runs your code without affecting your main system |
| **DevContainer** | A VS Code/Antigravity feature that automatically opens your project inside a container |
| **Docker Named Volume** | Persistent storage managed by Docker that survives container rebuilds |
| **tmpfs** | A temporary filesystem stored in RAM that disappears when the container stops (used to hide `.git` folders) |
| **CUDA** | NVIDIA's toolkit for running code on GPUs (needed for AI/ML acceleration) |

---

## 📄 License

MIT License - Use freely for personal and commercial projects.

---

*Built for secure, high-velocity AI-assisted development.*
