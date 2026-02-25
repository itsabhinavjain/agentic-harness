#!/bin/bash

set -e

# Always run from harness root regardless of where the script is invoked from
cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Regisedge Harness Docker Environment Setup...  ${NC}"
echo -e "${GREEN}=================================================${NC}"

case "$(uname -s)" in
    Linux*)
        OS_TYPE="Linux/WSL2"
        export LOCAL_UID=$(id -u)
        export LOCAL_GID=$(id -g)
        ;;
    Darwin*)
        OS_TYPE="macOS"
        export LOCAL_UID=$(id -u)
        export LOCAL_GID=$(id -g)
        ;;
    MINGW*|CYGWIN*|MSYS*)
        OS_TYPE="Windows (Git Bash)"
        export LOCAL_UID=1000
        export LOCAL_GID=1000
        ;;
    *)
        OS_TYPE="Unknown"
        export LOCAL_UID=1000
        export LOCAL_GID=1000
        ;;
esac

echo -e "${YELLOW}Detected OS:${NC} $OS_TYPE"
echo -e "${YELLOW}LOCAL_UID:${NC}  $LOCAL_UID"
echo -e "${YELLOW}LOCAL_GID:${NC}  $LOCAL_GID"
echo ""

# Ensure required directories exist on the host machine
echo -e "${YELLOW}Checking required directories on host machine...${NC}"
mkdir -p volumes/agent_machine/home
mkdir -p workspace
mkdir -p .secrets

echo -e "${GREEN}Host machine directories ready!${NC}"
echo ""

echo -e "${GREEN}Starting container...${NC}"
docker compose up --build -d

echo ""
echo -e "${YELLOW}Waiting for container setup to complete...${NC}"
echo -e "${YELLOW}(Installing tools if needed — this may take a moment)${NC}"
echo ""

# Stream container logs in the background so the user can see what's being installed
docker compose logs -f &
LOGS_PID=$!
trap 'kill $LOGS_PID 2>/dev/null' EXIT

# Poll for container health status with timeout
MAX_WAIT=300  # 5 minutes
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Check container health status
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' agent_machine 2>/dev/null || echo "unknown")

    case "$HEALTH" in
        healthy)
            kill $LOGS_PID 2>/dev/null
            echo ""
            echo -e "${GREEN}===============================================${NC}"
            echo -e "${GREEN}  Container is ready!${NC}"
            echo -e "${GREEN}===============================================${NC}"
            echo ""
            echo -e "${YELLOW}Run ${GREEN}./admin_scripts/03_docker_shell.sh${YELLOW} to enter the container${NC}"
            exit 0
            ;;
        unhealthy)
            kill $LOGS_PID 2>/dev/null
            echo ""
            echo -e "${RED}===============================================${NC}"
            echo -e "${RED}  Container setup failed!${NC}"
            echo -e "${RED}===============================================${NC}"
            exit 1
            ;;
        *)
            sleep $INTERVAL
            ELAPSED=$((ELAPSED + INTERVAL))
            ;;
    esac
done

# Timeout reached
kill $LOGS_PID 2>/dev/null
echo ""
echo -e "${RED}===============================================${NC}"
echo -e "${RED}  Container setup timed out!${NC}"
echo -e "${RED}===============================================${NC}"
exit 1
