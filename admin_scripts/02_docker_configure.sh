#!/bin/bash
set -e

# Always run from harness root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =============================================================================
# Configure the various services here 
# Use ic : Interactive shell in the container to run commands as the agent user
# =============================================================================


# =============================================================================
# Main agent machine 
# =============================================================================

CONTAINER_NAME="agent_machine"

# Source .env for AGENT_USER (if set)
if [ -f .env ]; then
    set -a; source .env; set +a
fi
AGENT_USER="${AGENT_USER:-dev}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Container '$CONTAINER_NAME' is not running!${NC}"
    echo -e "${YELLOW}Start it first with: ./admin_scripts/01_docker_start.sh${NC}"
    exit 1
fi

# echo -e "${GREEN}Claude Code${NC}"
# echo -e "${GREEN} - Authenticate${NC}"
# echo -e "${GREEN} - Add Marketplaces and Plugins${NC}"
# docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash -ic "claude"
# docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash -ic "claude plugin marketplace add anthropics/knowledge-work-plugins"
# docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash -ic "claude plugin install sales@knowledge-work-plugins"

# echo -e "${GREEN}Gemini${NC}"
# echo -e "${GREEN} - Authenticate${NC}"
# echo -e "${GREEN} - Add Extensions${NC}"
# docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash -ic "gemini"

# echo -e "${GREEN}Add skills for the workspace${NC}"
# docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash -ic "CI=true npx skills add https://github.com/anthropics/skills --skill frontend-design --yes"

# echo -e "${GREEN}Add skills for the user${NC}"

echo -e "${GREEN}Configuration complete!${NC}"