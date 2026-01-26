# 📖 Development Process

> High-level narrative tracking the development of major components.

---

## Phase 1: Initialization (Completed)

**Objective**: Establish project structure and logging infrastructure.

The project was initialized with a clear separation of concerns:
- `.devcontainer/` for Docker-related configuration
- `.devcontainer/environments/` for Conda environment YAML files
- `project_logs/` for development tracking
- Root level for setup scripts and documentation

This structure ensures the repository is self-contained and can be pushed to GitHub as a standalone project.

---

## Phase 2: Docker Architecture (Completed)

**Objective**: Create a robust Dockerfile with persistent environment storage and Git security.

### Key Design Decisions

1. **Base Image**: Selected `condaforge/miniforge3:latest` for:
   - Cross-platform support (amd64/arm64)
   - Mamba package manager for fast installs
   - Well-maintained and actively updated

2. **Named Volume Strategy**: Docker Named Volume (`persistent-sandbox-conda`) mounted at `/opt/conda`:
   - Installed packages survive container rebuilds
   - First build: 5-15 minutes; Rebuilds: ~30 seconds
   - Significant time savings for iterative development

3. **Git Blocking**: Multi-layer protection implemented:
   - Git binary replaced with blocking script
   - Sibling `.git` directories shadowed with empty tmpfs mounts
   - IDE settings disable all git features
   - Prevents accidental commits/pushes to shared repos

---

## Phase 3: Setup Scripts (Completed)

**Objective**: Create cross-platform setup scripts with configuration wizard.

### Design Choices

Both `setup.sh` (Bash) and `setup.ps1` (PowerShell) implement identical functionality:
- Python version selection (3.11, 3.12, 3.13)
- Package tier selection
- Add-on multi-selection
- LaTeX support toggle
- Auto-discovery of ALL sibling directories
- Dynamic `devcontainer.json` generation

### Windows Compatibility

The Bash script is the primary recommendation for Windows users:
- Runs via Git Bash (bundled with Git for Windows)
- Runs via WSL (required for Docker Desktop anyway)
- PowerShell provided as an alternative

Key compatibility fixes:
- `date -Iseconds` fallback for Git Bash
- Proper quoting for folder names with spaces
- POSIX-compliant syntax throughout

---

## Phase 4: Git Safety (Completed)

**Objective**: Prevent AI agents from accidentally pushing to shared repositories.

### Protection Layers

| Layer | Implementation |
|-------|----------------|
| Binary Block | `/usr/bin/git` replaced with error script |
| Shadow Mounts | `.git` dirs mounted as empty tmpfs |
| IDE Settings | `git.enabled: false` in container settings |
| Environment | Dummy `GIT_AUTHOR_EMAIL` prevents accidental config |

This ensures that even if an AI agent attempts git operations, they will fail safely with a user-friendly message directing them to use git on the host machine.

---

## Phase 5: Initial Documentation (Completed)

**Objective**: Create production-ready standalone documentation.

### README Features
- Complete quick-start guide
- Security architecture diagram
- Package tier comparison table
- Troubleshooting section
- Reconfiguration instructions

### Project Logs
- `changes.md`: Chronological file modification log
- `issue_tracker.md`: All identified issues and fixes
- `dev_process.md`: High-level development narrative

---

## Phase 6: Environment Refactoring (Completed)

**Objective**: Restructure environments into clean cumulative tiers with modular add-ons.

### Rationale

The original 4-file structure (basic, ai, full, r) had several issues:
1. No clear hierarchy between tiers
2. R was a standalone environment instead of an add-on
3. ML packages (scikit-learn) were in the AI tier when they don't require GPUs
4. CUDA version was outdated (12.1 → 12.4)

### New Architecture

**Cumulative Tiers** (each includes all previous):
| Tier | File | Key Additions |
|------|------|---------------|
| 1 | `core.yml` | NumPy, Pandas, Jupyter, Matplotlib |
| 2 | `ml.yml` | scikit-learn, XGBoost, statsmodels, SHAP |
| 3 | `ai.yml` | PyTorch, JAX, Transformers, CUDA 12.4 |
| 4 | `full.yml` | Dask, Polars, Numba, OpenCV |

**Independent Add-ons** (multi-select):
| Add-on | File | Description |
|--------|------|-------------|
| R | `addon-r.yml` | R language + IRkernel + tidyverse |
| Viz | `addon-viz.yml` | Plotly, Bokeh, Altair, Streamlit |
| NLP | `addon-nlp.yml` | spaCy, NLTK, sentence-transformers |

### Benefits

1. **Clear progression**: Users can see exactly what each tier adds
2. **Modular add-ons**: Install only what you need
3. **Multi-select**: Combine any add-ons with any tier
4. **Current CUDA**: Updated to 12.4 for 2026 compatibility
5. **Better package placement**: ML tools don't require GPU

---

## Summary

The Persistent Agent Sandbox v2.0 is complete with:

- ✅ **4-tier environment system** (core → ml → ai → full)
- ✅ **3 modular add-ons** (R, Viz, NLP) with multi-select
- ✅ **CUDA 12.4** for current GPU support
- ✅ **Universal auto-discovery** of all sibling folders
- ✅ **Git safety** via multi-layer blocking
- ✅ **Persistent packages** via Docker Named Volume
- ✅ **Cross-platform support** (Bash primary, PowerShell backup)
- ✅ **Production-ready documentation**
