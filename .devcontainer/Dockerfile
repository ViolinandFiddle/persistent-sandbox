# ==============================================================================
# PERSISTENT AGENT SANDBOX - Dockerfile
# ==============================================================================
# A secure, isolated Python/R development environment with persistent storage.
#
# BASE IMAGE:  condaforge/miniforge3:latest
# BUILD ARGS:
#   - PYTHON_VERSION: Python version (3.11|3.12|3.13)
#   - BUILD_TYPE:     Package tier (barebones|core|ml|ai|full)
#   - INSTALL_LATEX:  LaTeX for PDF export (true|false)
#   - ADDON_R:        R language add-on (true|false)
#   - ADDON_VIZ:      Advanced visualization add-on (true|false)
#   - ADDON_NLP:      NLP tools add-on (true|false)
#
# TIER HIERARCHY (cumulative):
#   barebones → core → ml → ai → full
#   Each tier includes all packages from previous tiers.
#
# SECURITY:
#   - Git is BLOCKED at build time to prevent accidental commits/pushes
#   - Sibling .git folders are shadowed with tmpfs mounts
#   - Runs as root for simplified permissions
# ==============================================================================

FROM condaforge/miniforge3:latest

# OCI Image Labels
LABEL org.opencontainers.image.title="Persistent Agent Sandbox"
LABEL org.opencontainers.image.description="Secure Python/R environment with Git disabled and persistent packages"
LABEL org.opencontainers.image.version="2.0.0"

# Build arguments
ARG PYTHON_VERSION=3.11
ARG BUILD_TYPE=core
ARG INSTALL_LATEX=false
ARG ADDON_R=false
ARG ADDON_VIZ=false
ARG ADDON_NLP=false
ARG ADDON_QUARTO=false
ARG ADDON_CHROME=false
ARG DEBIAN_FRONTEND=noninteractive

# Environment Configuration
ENV CONDA_DIR=/opt/conda
ENV PATH="${CONDA_DIR}/envs/sandbox/bin:${PATH}"
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV SANDBOX_ACTIVE=true

# ==============================================================================
# SYSTEM PACKAGES
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential gcc g++ make cmake \
    # Network & security
    git curl wget openssh-client ca-certificates gnupg2 socat iproute2 \
    # Archive tools
    zip unzip tar gzip bzip2 xz-utils \
    # Editors & utilities
    vim nano gawk jq htop tree locate dos2unix sudo \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 🛡️ GIT BLOCKING (Security Layer)
# ==============================================================================
# Replaces the git binary with a blocking script. This prevents AI agents
# from accidentally committing or pushing code from within the container.
# Use git on your HOST machine instead.
RUN mv /usr/bin/git /usr/bin/.git-real \
    && printf '#!/bin/bash\necho "🛡️ Git is BLOCKED in this sandbox for your protection."\necho "   This prevents accidental commits/pushes to shared repositories."\necho "   Use git on your HOST machine instead."\nexit 1\n' > /usr/bin/git \
    && chmod +x /usr/bin/git

# ==============================================================================
# OPTIONAL: LATEX (for Jupyter PDF export via nbconvert)
# ==============================================================================
# Installs a comprehensive LaTeX distribution for exporting notebooks as PDFs.
# Includes: texlive-xetex, texlive-fonts, pandoc, and all required converters.
RUN if [ "$INSTALL_LATEX" = "true" ]; then \
    echo "📦 Installing LaTeX for PDF export..." && \
    apt-get update && apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-extra \
    texlive-plain-generic \
    texlive-science \
    lmodern \
    fonts-liberation \
    pandoc \
    latexmk \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# ==============================================================================
# COPY ENVIRONMENT FILES
# ==============================================================================
COPY .devcontainer/environments/ /tmp/environments/

# ==============================================================================
# MAMBA CONFIGURATION
# ==============================================================================
RUN conda config --set channel_priority strict --system

# ==============================================================================
# BASE ENVIRONMENT: Python Only (all tiers start here)
# ==============================================================================
RUN echo "📦 Creating sandbox environment with Python ${PYTHON_VERSION}..." && \
    mamba create -n sandbox python=${PYTHON_VERSION} -y && \
    mamba clean -afy

# ==============================================================================
# TIER 1: CORE - Essential Scientific Stack
# ==============================================================================
# Installed for: core, ml, ai, full
RUN if [ "$BUILD_TYPE" != "barebones" ]; then \
    echo "📦 [Tier 1/4] Installing Core scientific stack..." && \
    mamba env update -n sandbox -f /tmp/environments/core.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# TIER 2: ML - Classical Machine Learning
# ==============================================================================
# Installed for: ml, ai, full
RUN if [ "$BUILD_TYPE" = "ml" ] || [ "$BUILD_TYPE" = "ai" ] || [ "$BUILD_TYPE" = "full" ]; then \
    echo "📦 [Tier 2/4] Installing ML packages (scikit-learn, XGBoost)..." && \
    mamba env update -n sandbox -f /tmp/environments/ml.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# TIER 3: AI - Deep Learning (PyTorch, JAX, CUDA 12.4)
# ==============================================================================
# Installed for: ai, full
RUN if [ "$BUILD_TYPE" = "ai" ] || [ "$BUILD_TYPE" = "full" ]; then \
    echo "🧠 [Tier 3/4] Installing AI stack (PyTorch, JAX, CUDA 12.4)..." && \
    mamba env update -n sandbox -f /tmp/environments/ai.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# TIER 4: FULL - Big Data & Performance
# ==============================================================================
# Installed for: full only
RUN if [ "$BUILD_TYPE" = "full" ]; then \
    echo "📊 [Tier 4/4] Installing Big Data suite (Dask, Polars, Numba)..." && \
    mamba env update -n sandbox -f /tmp/environments/full.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# ADD-ON: R Language Support
# ==============================================================================
# Independent add-on - can be combined with any tier
RUN if [ "$ADDON_R" = "true" ]; then \
    echo "📦 [Add-on] Installing R environment with IRkernel..." && \
    mamba env update -n sandbox -f /tmp/environments/addon-r.yml && \
    mamba clean -afy && \
    # Install ReacTran from CRAN (missing on conda-forge)
    ${CONDA_DIR}/envs/sandbox/bin/Rscript -e "install.packages('ReacTran', repos='http://cran.us.r-project.org')" && \
    # Register R kernel for Jupyter
    ${CONDA_DIR}/envs/sandbox/bin/Rscript -e "IRkernel::installspec(user = FALSE, name = 'ir', displayname = 'R (Sandbox)')"; \
    fi

# ==============================================================================
# ADD-ON: Advanced Visualization
# ==============================================================================
# Independent add-on - Plotly, Bokeh, Altair, Streamlit, etc.
RUN if [ "$ADDON_VIZ" = "true" ]; then \
    echo "📦 [Add-on] Installing advanced visualization tools..." && \
    mamba env update -n sandbox -f /tmp/environments/addon-viz.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# ADD-ON: NLP Tools
# ==============================================================================
# Independent add-on - spaCy, NLTK, sentence-transformers, etc.
RUN if [ "$ADDON_NLP" = "true" ]; then \
    echo "📦 [Add-on] Installing NLP tools (spaCy, NLTK)..." && \
    mamba env update -n sandbox -f /tmp/environments/addon-nlp.yml && \
    mamba clean -afy; \
    fi

# ==============================================================================
# ADD-ON: Quarto & TinyTeX
# ==============================================================================
RUN if [ "$ADDON_QUARTO" = "true" ]; then \
    echo "📦 [Add-on] Installing Quarto & TinyTeX..." && \
    apt-get update && apt-get install -y --no-install-recommends \
    evince \
    && QUARTO_VERSION="1.4.550" \
    && wget -q https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && dpkg -i quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && rm quarto-${QUARTO_VERSION}-linux-amd64.deb \
    && quarto install tool tinytex \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# ==============================================================================
# ADD-ON: Google Chrome
# ==============================================================================
RUN if [ "$ADDON_CHROME" = "true" ]; then \
    echo "📦 [Add-on] Installing Google Chrome..." && \
    apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# ==============================================================================
# JUPYTER KERNEL REGISTRATION
# ==============================================================================
RUN if [ "$BUILD_TYPE" != "barebones" ]; then \
    mamba run -n sandbox python -m ipykernel install \
    --prefix=${CONDA_DIR}/envs/sandbox \
    --name sandbox \
    --display-name "Python ${PYTHON_VERSION} (Sandbox)"; \
    fi

# ==============================================================================
# SHELL CONFIGURATION
# ==============================================================================
# Auto-activate sandbox environment on login
RUN echo ". /opt/conda/etc/profile.d/conda.sh && conda activate sandbox" >> /root/.bashrc

# Initialize mamba for shell
RUN mamba shell init --shell bash --root-prefix=${CONDA_DIR}

# ==============================================================================
# CLEANUP
# ==============================================================================
RUN rm -rf /tmp/environments/

# Working directory
WORKDIR /workspaces

# Default command
CMD ["/bin/bash"]
