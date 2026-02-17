FROM ubuntu:24.04

# =============================================================================
# Use bash with pipefail so curl | bash failures don't get hidden
# =============================================================================
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# =============================================================================
# Prevent interactive prompts + set timezone (configurable, defaults to UTC)
# =============================================================================
ENV DEBIAN_FRONTEND=noninteractive
ARG TZ=UTC
ENV TZ=$TZ

# =============================================================================
# Agent user name (configurable at build time, defaults to "dev")
# =============================================================================
ARG AGENT_USER=dev

# =============================================================================
# Base system + Node.js + dev tooling (single layer for smaller image)
# =============================================================================
RUN apt-get update && apt-get install -y \
    tzdata \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    gnupg \
    jq \
    ripgrep \
    fd-find \
    tree \
    htop \
    vim \
    tmux \
    build-essential \
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    zlib1g-dev \
    gosu \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    \
    # -------------------------
    # Node.js 22 LTS
    # -------------------------
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Install uv (Python manager) — system-wide binary only
# Python itself is installed later as agent user (see entrypoint-dev.sh)
# =============================================================================
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && cp /root/.local/bin/uv /usr/local/bin/uv \
    && cp /root/.local/bin/uvx /usr/local/bin/uvx

# =============================================================================
# Create agent user with UID/GID 1000 (most common host UID)
# Remove any existing user/group with UID/GID 1000 first (e.g., 'ubuntu' in Ubuntu images)
# =============================================================================
RUN EXISTING_USER=$(getent passwd 1000 | cut -d: -f1 || true) && \
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$AGENT_USER" ]; then \
        userdel -r "$EXISTING_USER" 2>/dev/null || true; \
    fi && \
    EXISTING_GROUP=$(getent group 1000 | cut -d: -f1 || true) && \
    if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$AGENT_USER" ]; then \
        groupdel "$EXISTING_GROUP" 2>/dev/null || true; \
    fi && \
    if ! getent group "$AGENT_USER" >/dev/null 2>&1; then \
        groupadd -g 1000 "$AGENT_USER"; \
    fi && \
    if ! id -u "$AGENT_USER" >/dev/null 2>&1; then \
        useradd -u 1000 -g 1000 -m -s /bin/bash "$AGENT_USER"; \
    fi && \
    echo "$AGENT_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$AGENT_USER" && \
    chmod 0440 /etc/sudoers.d/"$AGENT_USER"

# =============================================================================
# Copy entrypoint (root runtime) and agent user setup
# =============================================================================
COPY ./entrypoint-root.sh /usr/local/bin/entrypoint-root.sh
COPY ./entrypoint-dev.sh /usr/local/bin/entrypoint-dev.sh
RUN chmod +x /usr/local/bin/entrypoint-root.sh /usr/local/bin/entrypoint-dev.sh

# =============================================================================
# Environment
# =============================================================================
ENV AGENT_USER=$AGENT_USER
ENV HOME=/home/$AGENT_USER

# =============================================================================
# Entrypoint
# =============================================================================
ENTRYPOINT ["/usr/local/bin/entrypoint-root.sh"]
