# 📋 Change Log

> Chronological record of file modifications for the Persistent Agent Sandbox project.

## 2026-01-22

### Phase 1: Initialization

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:36:00 | CREATE | `project_logs/` | Initialized logging directory |
| 22:36:00 | CREATE | `project_logs/changes.md` | This file - change tracking |
| 22:36:00 | CREATE | `project_logs/issue_tracker.md` | Bug and fix documentation |
| 22:36:00 | CREATE | `project_logs/dev_process.md` | Development narrative |

### Phase 2: Docker Architecture

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:36:01 | CREATE | `.devcontainer/Dockerfile` | Container definition with Miniforge base |
| 22:40:30 | UPDATE | `.devcontainer/Dockerfile` | Added Git blocking, R support, LaTeX for PDF export |
| 22:40:35 | CREATE | `.devcontainer/environments/basic.yml` | PhD Baseline packages |
| 22:40:35 | CREATE | `.devcontainer/environments/ai.yml` | AI/ML stack (PyTorch, JAX) |
| 22:40:35 | CREATE | `.devcontainer/environments/full.yml` | Full data science suite |
| 22:40:35 | CREATE | `.devcontainer/environments/r.yml` | R language with IRkernel |

### Phase 3: Setup Scripts

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:36:02 | CREATE | `setup.ps1` | Initial PowerShell script |
| 22:41:00 | UPDATE | `setup.ps1` | Added Python version, package tiers, LaTeX, R options |
| 22:36:03 | CREATE | `setup.sh` | Initial Bash script |
| 22:41:00 | UPDATE | `setup.sh` | Added full config wizard, Git shadow mounts |

### Phase 4: Git Safety

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:40:30 | UPDATE | `.devcontainer/Dockerfile` | Git binary replaced with blocking script |
| 22:41:00 | UPDATE | `setup.ps1` | Added tmpfs shadow mounts for .git directories |
| 22:41:00 | UPDATE | `setup.sh` | Added tmpfs shadow mounts for .git directories |

### Phase 5: Initial Documentation

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:36:04 | CREATE | `.gitignore` | Repository hygiene rules |
| 22:36:04 | CREATE | `README.md` | Initial documentation |
| 22:43:00 | UPDATE | `README.md` | Production-ready standalone documentation |
| 22:44:00 | UPDATE | `project_logs/changes.md` | Complete change history |
| 22:44:00 | UPDATE | `project_logs/issue_tracker.md` | All identified issues |
| 22:44:00 | UPDATE | `project_logs/dev_process.md` | Full development narrative |

---

### Phase 6: Environment Refactoring (v2.0)

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 22:53:00 | DELETE | `.devcontainer/environments/basic.yml` | Replaced by core.yml |
| 22:53:00 | DELETE | `.devcontainer/environments/r.yml` | Replaced by addon-r.yml |
| 22:54:00 | CREATE | `.devcontainer/environments/core.yml` | Tier 1: Essential scientific stack |
| 22:54:00 | CREATE | `.devcontainer/environments/ml.yml` | Tier 2: Classical ML (scikit-learn, XGBoost) |
| 22:54:00 | UPDATE | `.devcontainer/environments/ai.yml` | Tier 3: Deep learning, CUDA 12.4 |
| 22:54:00 | UPDATE | `.devcontainer/environments/full.yml` | Tier 4: Big data (Dask, Polars) |
| 22:55:00 | CREATE | `.devcontainer/environments/addon-r.yml` | Add-on: R language + IRkernel |
| 22:55:00 | CREATE | `.devcontainer/environments/addon-viz.yml` | Add-on: Plotly, Bokeh, Streamlit |
| 22:55:00 | CREATE | `.devcontainer/environments/addon-nlp.yml` | Add-on: spaCy, NLTK, sentence-transformers |
| 22:56:00 | UPDATE | `.devcontainer/Dockerfile` | v2.0: 4-tier + 3 add-on build system |
| 22:57:00 | UPDATE | `setup.sh` | v2.0: Multi-select add-ons, new tier names |
| 22:57:00 | UPDATE | `setup.ps1` | v2.0: Multi-select add-ons, new tier names |
| 22:59:00 | UPDATE | `project_logs/changes.md` | Phase 6 changelog |
| 22:59:00 | UPDATE | `project_logs/dev_process.md` | Phase 6 narrative |

---

### Phase 7: QA Recommendations

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 23:06:00 | UPDATE | `setup.sh` | Replaced awk with pure bash arithmetic for Git Bash compatibility |
| 23:06:00 | UPDATE | `setup.sh` | Made Docker volume name unique per sandbox folder |
| 23:06:00 | UPDATE | `setup.ps1` | Made Docker volume name unique per sandbox folder |
| 23:06:00 | UPDATE | `README.md` | Added glossary of technical terms (tmpfs, bind mount, etc.) |
| 23:06:00 | UPDATE | `README.md` | Updated volume name references to show dynamic naming |

## 2026-01-26

### Phase 8: Build Stability Fixes

| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 16:40:00 | UPDATE | `.devcontainer/environments/ai.yml` | Pinned `pyarrow>=16.0.0` to fix Python 3.13 build error (ISS-012) |
| 16:50:00 | UPDATE | `.devcontainer/environments/addon-r.yml` | Removed `r-reactran` (missing from conda-forge) (ISS-013) |
| 16:50:00 | UPDATE | `.devcontainer/Dockerfile` | Added custom CRAN install step for `ReacTran` (ISS-013) |
| 16:55:00 | UPDATE | `project_logs/issue_tracker.md` | Documented build issues ISS-012 & ISS-013 |
| 16:55:00 | UPDATE | `project_logs/changes.md` | Logged build stability fixes |
| 17:15:00 | UPDATE | `setup.ps1` | Added `-ResetVolume` parameter and safe delete wizard (ISS-014) |
| 17:15:00 | UPDATE | `setup.sh` | Added `--reset-volume` flag and safe delete wizard (ISS-014) |
| 17:15:00 | UPDATE | `project_logs/issue_tracker.md` | Documented stale volume issue ISS-014 |

### Phase 9: Volume Initialization Fix
| Time (UTC) | Action | File | Description |
|------------|--------|------|-------------|
| 17:35:00 | UPDATE | `setup.ps1` | Removed manual `docker volume create` (ISS-015) |
| 17:35:00 | UPDATE | `setup.sh` | Removed manual `docker volume create` (ISS-015) |
| 17:35:00 | UPDATE | `project_logs/issue_tracker.md` | Documented empty volume bug ISS-015 |
