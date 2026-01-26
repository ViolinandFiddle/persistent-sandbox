# 🐛 Issue Tracker

> Documentation of identified issues, their root causes, and applied fixes.

## Format

```
### ISS-XXX: [Title]
- **Status**: Open | Fixed | Won't Fix
- **Severity**: Critical | High | Medium | Low
- **Platform**: Windows | Linux | Mac | All
- **Root Cause**: [Description]
- **Fix Applied**: [Solution]
```

---

## Fixed Issues

### ISS-001: Windows Backslash in JSON Mount Paths
- **Status**: Fixed
- **Severity**: Critical
- **Platform**: Windows
- **Root Cause**: PowerShell's `Join-Path` uses backslashes (`\`) on Windows, but Docker requires forward slashes (`/`) in mount specifications.
- **Fix Applied**: All path variables are explicitly converted using `-replace '\\', '/'` before JSON generation.

### ISS-002: Named Volume Permissions on Linux Host
- **Status**: Fixed
- **Severity**: Medium
- **Platform**: Linux
- **Root Cause**: Named volumes may have root ownership, causing permission issues for non-root processes.
- **Fix Applied**: Container runs as root user (`"remoteUser": "root"`). Root has full access to all mounted files.

### ISS-003: Relative Path Portability
- **Status**: Fixed
- **Severity**: High
- **Platform**: All
- **Root Cause**: Absolute paths in `devcontainer.json` break portability when cloned elsewhere.
- **Fix Applied**: All mount source paths use `${localWorkspaceFolder}/../sibling` syntax (relative to workspace).

### ISS-004: Empty Sibling Directory List
- **Status**: Fixed
- **Severity**: Low
- **Platform**: All
- **Root Cause**: Empty folder list could produce malformed JSON.
- **Fix Applied**: Scripts handle empty case gracefully, including only the named volume mount.

### ISS-005: Git Push Protection
- **Status**: Fixed
- **Severity**: Critical
- **Platform**: All
- **Root Cause**: AI agents could accidentally push to shared repositories, causing data loss or conflicts.
- **Fix Applied**: Multi-layer protection:
  1. Git binary replaced with blocking script in Dockerfile
  2. All sibling `.git` directories shadowed with empty tmpfs mounts
  3. IDE settings disable git features (`git.enabled: false`)
  4. Container environment sets dummy git author/committer

### ISS-006: Windows Git Bash Compatibility
- **Status**: Fixed
- **Severity**: Medium
- **Platform**: Windows
- **Root Cause**: `date -Iseconds` not available in Git Bash (uses BSD date format).
- **Fix Applied**: Setup script uses fallback: `date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z`

### ISS-007: Folder Names with Spaces
- **Status**: Fixed
- **Severity**: Medium
- **Platform**: All
- **Root Cause**: Folder names with spaces break unquoted variable expansion in Bash.
- **Fix Applied**: All variables properly quoted in setup scripts. JSON escaping handles special characters.

### ISS-008: R Kernel Registration in Jupyter
- **Status**: Fixed
- **Severity**: Low
- **Platform**: All
- **Root Cause**: IRkernel must be explicitly registered for Jupyter to detect the R environment.
- **Fix Applied**: Dockerfile runs `IRkernel::installspec()` after R add-on installation.

### ISS-009: Unclear Package Tier Hierarchy
- **Status**: Fixed (v2.0)
- **Severity**: Medium
- **Platform**: All
- **Root Cause**: Original tier structure (basic, ai, full) didn't clearly show which packages were in which tier, and ML packages were bundled with GPU-dependent AI tier.
- **Fix Applied**: Refactored to 4 cumulative tiers (core → ml → ai → full) with clear documentation of what each tier adds.

### ISS-010: R as Standalone vs Add-on
- **Status**: Fixed (v2.0)
- **Severity**: Low
- **Platform**: All
- **Root Cause**: R environment was a separate standalone choice, not combinable with Python environment.
- **Fix Applied**: R is now an add-on (`addon-r.yml`) that extends the Python environment, allowing R + Python together.

### ISS-011: Outdated CUDA Version
- **Status**: Fixed (v2.0)
- **Severity**: Medium
- **Platform**: All
- **Root Cause**: CUDA 12.1 was outdated for January 2026.
- **Fix Applied**: Updated to CUDA 12.4 in `ai.yml` for current PyTorch/JAX compatibility.

### ISS-012: PyArrow Build Failure on Python 3.13
- **Status**: Fixed
- **Severity**: Critical
- **Platform**: All
- **Root Cause**: Pip resolution backtracking to ancient `pyarrow` versions (<7.0) which demand `numpy==1.19.4` (incompatible with Python 3.13).
- **Fix Applied**: Explicitly pinned `pyarrow>=16.0.0` in `ai.yml` to force modern, compatible versions.

### ISS-013: Missing R-Reactran Package
- **Status**: Fixed
- **Severity**: High
- **Platform**: All
- **Root Cause**: `r-reactran` package is not available on `conda-forge` channel.
- **Fix Applied**: Removed package from `addon-r.yml` and added custom CRAN installation step (`install.packages('ReacTran')`) to `Dockerfile`.

### ISS-014: Stale Volume Persists Old Environment
- **Status**: Fixed
- **Severity**: High
- **Platform**: All
- **Root Cause**: Docker named volumes persist data across container rebuilds. If the Dockerfile is updated, the volume still contains the old Conda environment, preventing updates from appearing.
- **Fix Applied**: Added `--reset-volume` flag (and interactive Wizard option) to setup scripts to allow explicit destruction of the stale volume with safety guards.

### ISS-015: Manual Volume Creation Results in Empty Environment
- **Status**: Fixed
- **Severity**: Critical
- **Platform**: All
- **Root Cause**: Setup scripts were manually running `docker volume create`. This creates an empty volume. When mounted over `/opt/conda`, it hid the pre-installed packages. Docker only copies image content to a volume if *Docker* itself creates the volume during container startup.
- **Fix Applied**: Removed explicit `docker volume create` from setup scripts. Scripts now only *delete* the volume (if requested), but rely on Docker to safely create/populate it on first run.

---

## Open Issues

*No open issues at this time.*
