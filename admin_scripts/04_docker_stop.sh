#!/bin/bash

# =============================================================================
# Stop the agent container
# =============================================================================

set -e

# Always run from harness root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping agent container...${NC}"

docker compose down "$@"

echo -e "${GREEN}Container stopped!${NC}"
