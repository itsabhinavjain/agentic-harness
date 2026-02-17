#!/bin/bash
# =============================================================================
# Container entrypoint — runs as ROOT
#
# Responsibilities (root-only):
#   1. Remap agent user UID/GID to match host
#   2. Fix bind mount ownership
#   3. Hand off to entrypoint-dev.sh (as agent user)
#   4. Signal health check
#   5. exec as agent user
#
# This script must NEVER create files inside bind-mounted directories.
# All user-level setup (tools, config) is in entrypoint-dev.sh.
# =============================================================================
set -euo pipefail

AGENT_USER="${AGENT_USER:-dev}"
HOME_DIR="/home/$AGENT_USER"
USER_ID="${LOCAL_UID:-1000}"
GROUP_ID="${LOCAL_GID:-1000}"

echo "Starting with AGENT_USER=$AGENT_USER UID=$USER_ID GID=$GROUP_ID"

# =============================================================================
# 1. UID/GID remapping
# =============================================================================
CURRENT_UID=$(id -u "$AGENT_USER")
CURRENT_GID=$(getent group "$AGENT_USER" | cut -d: -f3 || echo "")

# Remove any existing user that has the target UID
EXISTING_USER=$(getent passwd "$USER_ID" 2>/dev/null | cut -d: -f1 || echo "")
if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$AGENT_USER" ]; then
    echo "Removing existing user '$EXISTING_USER' that has UID $USER_ID"
    userdel "$EXISTING_USER" 2>/dev/null || true
fi

# Remove any existing group that has the target GID
EXISTING_GROUP=$(getent group "$GROUP_ID" 2>/dev/null | cut -d: -f1 || echo "")
if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$AGENT_USER" ]; then
    echo "Removing existing group '$EXISTING_GROUP' that has GID $GROUP_ID"
    groupdel "$EXISTING_GROUP" 2>/dev/null || true
fi

# Modify group if needed
if [ "$CURRENT_GID" != "$GROUP_ID" ]; then
    groupmod -g "$GROUP_ID" "$AGENT_USER" 2>/dev/null || true
fi

# Modify user if needed
if [ "$CURRENT_UID" != "$USER_ID" ]; then
    usermod -u "$USER_ID" -g "$GROUP_ID" "$AGENT_USER"
fi

# =============================================================================
# 2. Fix home directory ownership
# =============================================================================

# Top-level home directory
chown "$USER_ID":"$GROUP_ID" "$HOME_DIR"

# Recursive ownership fix only on first run (avoids slow chown on large caches on every restart)
OWNERSHIP_FLAG="$HOME_DIR/.ownership-fixed"
if [ ! -f "$OWNERSHIP_FLAG" ]; then
    echo "First run: fixing ownership on home directory..."
    chown -R "$USER_ID":"$GROUP_ID" "$HOME_DIR" 2>/dev/null || true
    gosu "$AGENT_USER" touch "$OWNERSHIP_FLAG"
fi

# =============================================================================
# 3. Run agent user setup (tools, config, verification)
# =============================================================================
echo "Running agent user setup..."
gosu "$AGENT_USER" /usr/local/bin/entrypoint-dev.sh

# =============================================================================
# 4. Signal that entrypoint setup is complete (for health check)
# =============================================================================
touch /tmp/.entrypoint-complete
echo "Setup complete — container ready!"

# =============================================================================
# 5. Drop to agent user and exec the CMD
# =============================================================================
exec gosu "$AGENT_USER" "$@"
