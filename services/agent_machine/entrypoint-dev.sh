#!/bin/bash
# =============================================================================
# Agent user setup — runs as agent user (called by entrypoint-root.sh via gosu)
# Everything this script creates is owned by the agent user automatically.
# =============================================================================

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
BASHRC_FILE="$HOME/.bashrc"

# Set npm global prefix to ~/.local so global installs land in ~/.local/bin/ (already in PATH)
# Note that npm prefix is user-scopped and not system-scopped. 
if ! npm config get prefix 2>/dev/null | grep -q "$HOME/.local"; then
    echo "Setting npm global prefix to $HOME/.local..."
    npm config set prefix "$HOME/.local"
fi

# =============================================================================
# Installations of tools (idempotent checks prevent reinstallation)
# =============================================================================

echo "Checking Python 3.12..."
if uv python list 2>/dev/null | grep -q "3.12"; then
    echo "  Python 3.12: already installed"
else
    echo "  Python 3.12: installing via uv..."
    uv python install 3.12
    echo "  Python 3.12: installed"
fi

echo "Checking Claude Code..."
if command -v claude >/dev/null 2>&1; then
    echo "  Claude Code: already installed"
else
    echo "  Claude Code: not found, installing..."
    curl -fsSL https://claude.ai/install.sh | bash
    if command -v claude >/dev/null 2>&1; then
        echo "  Claude Code: installed successfully"
    else
        echo "  Claude Code: installation failed"
    fi
fi

echo "Checking Gemini CLI..."
if command -v gemini >/dev/null 2>&1; then
    echo "  Gemini CLI: already installed"
else
    echo "  Gemini CLI: not found, installing..."
    npm install -g @google/gemini-cli
    if command -v gemini >/dev/null 2>&1; then
        echo "  Gemini CLI: installed successfully"
    else
        echo "  Gemini CLI: installation failed"
    fi
fi

# =============================================================================
# Set up .bashrc (idempotent — grep guards prevent duplicate entries)
# =============================================================================
touch "$BASHRC_FILE"

# Add PATH setup if not already present
if ! grep -q '# Added by entrypoint-dev.sh — PATH' "$BASHRC_FILE" 2>/dev/null; then
    cat >> "$BASHRC_FILE" << BASHRC_PATH

# Added by entrypoint-dev.sh — PATH
export PATH="$HOME/.local/bin:\$PATH"
BASHRC_PATH
fi

# Source workspace .env if it exists
if ! grep -q '# Added by entrypoint-dev.sh — workspace env' "$BASHRC_FILE" 2>/dev/null; then
    cat >> "$BASHRC_FILE" << BASHRC_ENV

# Added by entrypoint-dev.sh — workspace env
if [ -f "$HOME/workspace/.env" ]; then
    set -a
    source "$HOME/workspace/.env"
    set +a
fi
BASHRC_ENV
fi

# Print tool versions on shell login
if ! grep -q '# Added by entrypoint-dev.sh — tool versions' "$BASHRC_FILE" 2>/dev/null; then
    cat >> "$BASHRC_FILE" << 'BASHRC_VERSIONS'

# Added by entrypoint-dev.sh — color configuration
export CLICOLOR=1
export COLORTERM=truecolor
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=42:cd=46:su=37:sg=47:tw=37:ow=34'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
BASHRC_VERSIONS
fi

echo ""
echo "Agent user setup complete."
