#!/bin/bash
set -e

# Always run from harness root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =============================================================================
# Attach to running agent container
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

echo -e "${GREEN}Attaching to container '$CONTAINER_NAME'...${NC}"
echo -e "${YELLOW}(Press Ctrl+D or type 'exit' to detach)${NC}"
echo ""

docker exec -it -u "$AGENT_USER" "$CONTAINER_NAME" /bin/bash

echo -e "${GREEN}Exited from container!${NC}"
