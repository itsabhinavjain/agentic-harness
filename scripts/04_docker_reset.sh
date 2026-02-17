#!/bin/bash

# =============================================================================
# Reset agent Docker environment
# Stops containers, removes project resources, and cleans local mounts
# =============================================================================

set -e

# Always run from harness root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Docker Environment Reset${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "${RED}This will:${NC}"
echo -e "${RED}  - Stop and remove the agent container${NC}"
echo -e "${RED}  - Remove the agent Docker image${NC}"
echo ""

read -p "Are you sure? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Reset cancelled.${NC}"
    exit 0
fi

echo ""

# Step 1: Stop containers and remove project resources
echo -e "${YELLOW}Stopping containers and removing project images/volumes...${NC}"
docker compose down --rmi local --volumes --remove-orphans 2>/dev/null || true
echo -e "${GREEN}✓ Project containers and images removed${NC}"
echo ""

# Step 2: Remove dangling images only (safe — doesn't nuke other projects)
echo -e "${YELLOW}Removing dangling Docker images...${NC}"
docker image prune -f 2>/dev/null || true
echo -e "${GREEN}✓ Dangling images cleaned${NC}"
echo ""

# Step 3: Optionally remove container home directories (never deletes workspace)
echo -e "${YELLOW}Do you also want to remove the container home directory?${NC}"
echo -e "${YELLOW}  (caches, Claude Code binary, tool configs in volumes/agent_machine/home/)${NC}"
echo -e "${YELLOW}  Note: workspace/ is NEVER deleted.${NC}"
echo ""
read -p "Remove container home directory? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Removing container home directory...${NC}"

    if [ -d "volumes/agent_machine/home" ]; then
        rm -rf volumes/agent_machine/home
        mkdir -p volumes/agent_machine/home
        echo -e "${GREEN}✓ Removed volumes/agent_machine/home/ contents${NC}"
    fi

    if [ -d ".secrets" ]; then
        rm -rf .secrets
        echo -e "${GREEN}✓ Removed .secrets/${NC}"
    fi
else
    echo -e "${YELLOW}Skipped — container home directory kept.${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Reset Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}You can now run:${NC}"
echo -e "${GREEN}  ./scripts/01_docker_start.sh${NC}"
echo -e "${YELLOW}to set everything up from scratch.${NC}"
