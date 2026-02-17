## Harness definition
### Objective
- Run DeepAgent AI agents inside a dockerised environment
- This allows us to give access to additional tools without installing them on the host machine
- What should be persisted between runs
	- Workspace (Project files)
 	- Installed tool binaries
  	- Configuration of the installed tools
  	- Authentication of the installed tools

### Repository Structure
```
.
├── docker-compose.yaml            # Service definitions, mounts, networking, healthcheck
├── sample.env                     # Template for .env
│
├── services/
│   └── agent_machine/
│       ├── Dockerfile             # System packages, user creation (build-time)
│       ├── entrypoint-root.sh     # Root: UID/GID remap, permissions (run-time)
│       └── entrypoint-dev.sh      # Agent user: Python, Claude Code, .bashrc (run-time)
│
├── scripts/
│   ├── 01_docker_start.sh         # Build & start container, poll health
│   ├── 02_docker_shell.sh         # Attach interactive shell as agent user
│   ├── 03_docker_stop.sh          # Stop container
│   └── 04_docker_reset.sh         # Full reset (with confirmation)
│
├── workspace/                     # Working directory inside container (checked into git)
│   ├── README.md
│   └── sample.env
│
├── volumes/                       # Runtime data (git-ignored)
│   └── agent_machine/
│       └── home/                  # Persisted container home directory
│           ├── .cache/            # Tool caches
│           ├── .config/           # Tool configs
│           ├── .local/            # User-installed binaries
│           ├── .claude/           # Claude Code config
│           ├── .bashrc            # Shell config (auto-persists)
│           └── .bash_history      # Shell history (auto-persists)
│
├── admin_tools/                   # Host-side tooling (e.g. log analysis)
│   └── log_analysis/
│
├── admin_docs/                    # Internal documentation
│
├── .secrets/                      # API keys (git-ignored, mounted read-only)
├── DESIGN.md
└── README.md
```

### What's in git vs what's not

| In git | Git-ignored |
|--------|-------------|
| `workspace/` — your working directory | `volumes/` — container home dir, caches, tool configs |
| `services/` — Dockerfiles, entrypoints | `.env` — environment variables |
| `scripts/` — lifecycle scripts | `.secrets/` — API keys and credentials |
| `admin_tools/`, `admin_docs/` | |

### Architecture: Three-Layer Separation of Concerns

#### Layer 1: Dockerfile — Root System Tools (build-time)
Installs system-wide packages owned by root. Never creates files under `/home/<AGENT_USER>/` that need later ownership changes.

- System packages: curl, wget, git, jq, ripgrep, fd, tmux, vim, htop, build-essential, gosu, etc.
- Node.js 22 LTS (via NodeSource → /usr/bin/node)
- uv binary (→ /usr/local/bin/uv, /usr/local/bin/uvx)
- Agent user creation with UID/GID 1000 (name configurable via `AGENT_USER` build arg, defaults to `dev`)
- Copies entrypoint-root.sh and entrypoint-dev.sh

**Not installed here:** Python 3.12, Claude Code (these are agent-user tools → entrypoint-dev.sh)

#### Layer 2: entrypoint-root.sh — Root Runtime (every container start)
Runs as root. Does the minimum privileged work, then hands off to the agent user.

1. UID/GID remapping (match agent user to host UID/GID)
2. Home directory ownership fix (first-run only for recursive)
3. Calls `entrypoint-dev.sh` as agent user via `gosu`
4. Writes health check sentinel
5. `exec gosu $AGENT_USER "$@"`

**Rule:** This script never creates files inside bind-mounted directories.

#### Layer 3: entrypoint-dev.sh — Agent User Tools (every container start)
Runs as agent user. Everything it creates is owned by the agent user automatically.

1. Install Python 3.12 via uv (idempotent)
2. Install Claude Code (idempotent)
3. Set up .bashrc (PATH, workspace .env sourcing, tool versions on login)

### Volume Mounts (host → container)

| Host path | Container path | Mode | Purpose |
|---|---|---|---|
| volumes/agent_machine/home/ | /home/\<user\> | rw | Persisted home directory — tool configs, caches, dotfiles |
| workspace/ | /home/\<user\>/workspace | rw | Working directory (checked into git) |
| .secrets/ | /home/\<user\>/.secrets | ro | API keys and secrets |

### Configurable Agent User

The container user name is configurable via the `AGENT_USER` environment variable (defaults to `dev`):

```bash
# In .env (or export before running scripts)
AGENT_USER=regisedge_agent
```

This flows through:
- **Dockerfile** (`ARG AGENT_USER`) — user creation at build time
- **docker-compose.yaml** — build arg, runtime env, volume mount paths
- **entrypoint-root.sh** — UID/GID remapping and ownership fixes
- **entrypoint-dev.sh** — uses `$HOME` (set by Dockerfile `ENV HOME`)
- **scripts/02_docker_shell.sh** — `docker exec -u $AGENT_USER`

### Permission Model

| Path | Owner | Set by | Mutated by |
|------|-------|--------|------------|
| /usr/local/bin/* (uv, node) | root:root | Dockerfile | Never |
| /usr/bin/* (system tools, tmux) | root:root | Dockerfile | Never |
| /home/\<user\>/ (entire home) | user:user | entrypoint chown | entrypoint-dev, all tools at runtime |
| /home/\<user\>/.secrets/ | user:user | entrypoint chown | Read-only at runtime |

### Users within agent_machine
- `root`          : System tools, entrypoint UID remapping
- `$AGENT_USER`   : Agent user — all interactive work happens here (default: `dev`)

### Cross-Platform Notes
- **macOS:** Docker Desktop handles UID mapping via virtiofs; UID/GID remap still applied for consistency
- **WSL2:** Run from WSL2 native filesystem for performance; cache permission fix handles WSL2 bind mount quirks
- **Linux:** Primary target; works as-is
- **Windows (Git Bash):** Falls back to UID/GID 1000

## Usage

### General usage
```bash
# Start (builds image, polls health, installs tools)
./scripts/01_docker_start.sh

# Enter container as agent user
./scripts/02_docker_shell.sh

# Note : in the first run make sure that you are configuring the various tools
# - Tools
# 	- Claude Code : Authenticate 
#   - Gemini      : Authenticate 
#   - (Others)
# - We are using API keys for others

# Stop container
./scripts/03_docker_stop.sh

# Full reset (prompts for confirmation)
./scripts/04_docker_reset.sh
```
