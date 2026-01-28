#!/bin/bash

# OpenCode Userdata Initialization Script
# This script copies configuration files from a temporary container to the host

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Temporary container name
TEMP_CONTAINER="opencode-init-tmp"

# Fixed image name
IMAGE_NAME="successage/opencode-kanban"

# Host directories
HOST_USERDATA_DIR="./userdata"
HOST_OPENCODE_DIR="$HOST_USERDATA_DIR/.opencode"
HOST_CONFIG_DIR="$HOST_USERDATA_DIR/.config"
HOST_OPENCODE_CONFIG_DIR="$HOST_CONFIG_DIR/opencode"
HOST_OPENSPEC_CONFIG_DIR="$HOST_CONFIG_DIR/openspec"
HOST_VIBE_KANBAN_CONFIG_DIR="$HOST_CONFIG_DIR/vibe-kanban"
HOST_VIBE_KANBAN_DIR="$HOST_USERDATA_DIR/.vibe-kanban"
HOST_CLAUDE_DIR="$HOST_USERDATA_DIR/.claude"
HOST_CLAUDE_JSON="$HOST_USERDATA_DIR/.claude.json"
HOST_OPENCODE_SHARE_DIR="$HOST_USERDATA_DIR/.local/share/opencode"

# Container paths
CONTAINER_OPENCODE_DIR="/home/user/.opencode"
CONTAINER_CONFIG_DIR="/home/user/.config"
CONTAINER_OPENCODE_CONFIG_DIR="$CONTAINER_CONFIG_DIR/opencode"
CONTAINER_OPENSPEC_CONFIG_DIR="$CONTAINER_CONFIG_DIR/openspec"
CONTAINER_VIBE_KANBAN_SHARE_DIR="/home/user/.local/share/vibe-kanban"
CONTAINER_VIBE_KANBAN_DIR="/home/user/.vibe-kanban"
CONTAINER_CLAUDE_DIR="/home/user/.claude"
CONTAINER_CLAUDE_JSON="/home/user/.claude.json"
CONTAINER_OPENCODE_SHARE_DIR="/home/user/.local/share/opencode"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OpenCode Userdata Initialization${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if userdata directories already exist
if [ -d "$HOST_OPENCODE_DIR" ] && [ "$(ls -A $HOST_OPENCODE_DIR 2>/dev/null)" ] || \
   [ -d "$HOST_OPENCODE_CONFIG_DIR" ] && [ "$(ls -A $HOST_OPENCODE_CONFIG_DIR 2>/dev/null)" ] || \
   [ -d "$HOST_OPENSPEC_CONFIG_DIR" ] && [ "$(ls -A $HOST_OPENSPEC_CONFIG_DIR 2>/dev/null)" ] || \
   [ -d "$HOST_VIBE_KANBAN_CONFIG_DIR" ] && [ "$(ls -A $HOST_VIBE_KANBAN_CONFIG_DIR 2>/dev/null)" ] || \
   [ -d "$HOST_VIBE_KANBAN_DIR" ] && [ "$(ls -A $HOST_VIBE_KANBAN_DIR 2>/dev/null)" ]; then
    echo -e "${YELLOW}Warning: Userdata directories already exist on host with data.${NC}"
    echo ""
    echo "Existing directories:"
    [ -d "$HOST_OPENCODE_DIR" ] && echo "  - $HOST_OPENCODE_DIR"
    [ -d "$HOST_OPENCODE_CONFIG_DIR" ] && echo "  - $HOST_OPENCODE_CONFIG_DIR"
    [ -d "$HOST_OPENSPEC_CONFIG_DIR" ] && echo "  - $HOST_OPENSPEC_CONFIG_DIR"
    [ -d "$HOST_VIBE_KANBAN_CONFIG_DIR" ] && echo "  - $HOST_VIBE_KANBAN_CONFIG_DIR"
    [ -d "$HOST_VIBE_KANBAN_DIR" ] && echo "  - $HOST_VIBE_KANBAN_DIR"
    echo ""
    read -p "Do you want to continue? This may overwrite existing files. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Initialization cancelled."
        exit 0
    fi
fi

# Build or verify image exists
echo -e "${GREEN}Checking Docker image...${NC}"

if docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "  Image exists: $IMAGE_NAME"
    echo ""
    echo -e "${YELLOW}Do you want to rebuild the image?${NC}"
    echo -e "${YELLOW}Press 'y' within 5 seconds to rebuild, or any other key to skip...${NC}"

    read -t 5 -n 1 -r REPLY 2>/dev/null || REPLY=""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Rebuilding image..."
        if [ -f "./build-image.sh" ]; then
            ./build-image.sh
        else
            docker build -t "$IMAGE_NAME" .
        fi
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to build image.${NC}"
            exit 1
        fi
        echo "  Image rebuilt successfully."
    else
        echo "  Using existing image (timeout or skipped)."
    fi
else
    echo "  Image not found. Building..."
    if [ -f "./build-image.sh" ]; then
        ./build-image.sh
    else
        docker build -t "$IMAGE_NAME" .
    fi
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to build image.${NC}"
        exit 1
    fi
    echo "  Image built successfully."
fi
echo ""

# Create host directories
echo -e "${GREEN}Creating host directories...${NC}"
mkdir -p "$HOST_USERDATA_DIR"
mkdir -p "$HOST_OPENCODE_DIR"
mkdir -p "$HOST_CONFIG_DIR"
mkdir -p "$HOST_OPENCODE_CONFIG_DIR"
mkdir -p "$HOST_OPENSPEC_CONFIG_DIR"
mkdir -p "$HOST_VIBE_KANBAN_CONFIG_DIR"
mkdir -p "$HOST_VIBE_KANBAN_DIR"
echo "  Created: $HOST_USERDATA_DIR"
echo "  Created: $HOST_OPENCODE_DIR"
echo "  Created: $HOST_CONFIG_DIR"
echo "  Created: $HOST_OPENCODE_CONFIG_DIR"
echo "  Created: $HOST_OPENSPEC_CONFIG_DIR"
echo "  Created: $HOST_VIBE_KANBAN_CONFIG_DIR"
echo "  Created: $HOST_VIBE_KANBAN_DIR"
echo ""

# Start temporary container
echo -e "${GREEN}Starting temporary container...${NC}"
docker run -d --name $TEMP_CONTAINER --privileged $IMAGE_NAME sleep infinity 2>/dev/null || {
    echo -e "${RED}Error: Failed to start temporary container.${NC}"
    echo "  Image ID: $IMAGE_NAME"
    exit 1
}
echo "  Container started: $TEMP_CONTAINER"
echo ""

# Wait for container to be ready
echo -e "${GREEN}Waiting for container to be ready...${NC}"
sleep 2
echo ""

# Generate OpenCode and OpenSpec configuration
echo -e "${GREEN}Generating OpenCode configuration...${NC}"
echo "  Running OpenCode in background..."
docker exec $TEMP_CONTAINER bash -c "
    mkdir -p /home/user/project
    rm -rf /home/user/.opencode/data/ /home/user/.opencode/cache/ 2>/dev/null || true
    export PATH=/home/user/.opencode/bin:\$PATH
    opencode run \"hello world\" > /tmp/opencode.log 2>&1 &
    OPENCODE_PID=\$!
    echo \"OpenCode started with PID: \$OPENCODE_PID\"

    # Wait for OpenCode to fully initialize (60 seconds)
    echo \"Waiting for OpenCode to initialize (60 seconds)...\"
    sleep 60

    # Kill OpenCode process
    echo \"Stopping OpenCode...\"
    kill \$OPENCODE_PID 2>/dev/null || true
    wait \$OPENCODE_PID 2>/dev/null || true
    echo \"OpenCode stopped\"
" || {
    echo -e "${YELLOW}Warning: OpenCode configuration generation may have failed.${NC}"
}

echo ""

# Copy files from container to host
echo -e "${GREEN}Copying files from container to host...${NC}"

# Copy .opencode directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_OPENCODE_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_OPENCODE_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_OPENCODE_DIR -> $HOST_OPENCODE_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_OPENCODE_DIR/. "$HOST_OPENCODE_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_DIR (not found in container)${NC}"
fi

# Copy .config/opencode directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_OPENCODE_CONFIG_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_OPENCODE_CONFIG_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_OPENCODE_CONFIG_DIR -> $HOST_OPENCODE_CONFIG_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_OPENCODE_CONFIG_DIR/. "$HOST_OPENCODE_CONFIG_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_CONFIG_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_CONFIG_DIR (not found in container)${NC}"
fi

# Copy .config/openspec directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_OPENSPEC_CONFIG_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_OPENSPEC_CONFIG_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_OPENSPEC_CONFIG_DIR -> $HOST_OPENSPEC_CONFIG_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_OPENSPEC_CONFIG_DIR/. "$HOST_OPENSPEC_CONFIG_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_OPENSPEC_CONFIG_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_OPENSPEC_CONFIG_DIR (not found in container)${NC}"
fi

# Copy ~/.local/share/vibe-kanban directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_VIBE_KANBAN_SHARE_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_VIBE_KANBAN_SHARE_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_VIBE_KANBAN_SHARE_DIR -> $HOST_VIBE_KANBAN_CONFIG_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_VIBE_KANBAN_SHARE_DIR/. "$HOST_VIBE_KANBAN_CONFIG_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_VIBE_KANBAN_SHARE_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_VIBE_KANBAN_SHARE_DIR (not found in container)${NC}"
fi

# Copy ~/.vibe-kanban directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_VIBE_KANBAN_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_VIBE_KANBAN_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_VIBE_KANBAN_DIR -> $HOST_VIBE_KANBAN_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_VIBE_KANBAN_DIR/. "$HOST_VIBE_KANBAN_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_VIBE_KANBAN_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_VIBE_KANBAN_DIR (not found in container)${NC}"
fi

# Copy ~/.claude directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_CLAUDE_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_CLAUDE_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_CLAUDE_DIR -> $HOST_CLAUDE_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_CLAUDE_DIR/. "$HOST_CLAUDE_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_CLAUDE_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_CLAUDE_DIR (not found in container)${NC}"
fi

# Copy ~/.claude.json file
if docker exec $TEMP_CONTAINER test -f "$CONTAINER_CLAUDE_JSON" 2>/dev/null; then
    echo "  Copying $CONTAINER_CLAUDE_JSON -> $HOST_CLAUDE_JSON"
    docker cp $TEMP_CONTAINER:$CONTAINER_CLAUDE_JSON "$HOST_CLAUDE_JSON" 2>/dev/null || echo "    (Copy failed)"
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_CLAUDE_JSON (not found in container)${NC}"
fi

# Copy ~/.local/share/opencode directory
if docker exec $TEMP_CONTAINER test -d "$CONTAINER_OPENCODE_SHARE_DIR" 2>/dev/null; then
    FILE_COUNT=$(docker exec $TEMP_CONTAINER find $CONTAINER_OPENCODE_SHARE_DIR -type f 2>/dev/null | wc -l)
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  Copying $CONTAINER_OPENCODE_SHARE_DIR -> $HOST_OPENCODE_SHARE_DIR"
        docker cp $TEMP_CONTAINER:$CONTAINER_OPENCODE_SHARE_DIR/. "$HOST_OPENCODE_SHARE_DIR/" 2>/dev/null || echo "    (Copy failed)"
    else
        echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_SHARE_DIR (empty directory)${NC}"
    fi
else
    echo -e "${YELLOW}  Skipped: $CONTAINER_OPENCODE_SHARE_DIR (not found in container)${NC}"
fi

# Cleanup temporary container
echo ""
echo -e "${GREEN}Cleaning up temporary container...${NC}"
docker stop $TEMP_CONTAINER >/dev/null 2>&1
docker rm $TEMP_CONTAINER >/dev/null 2>&1
echo "  Container removed: $TEMP_CONTAINER"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Initialization complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "The following directories have been initialized on the host:"
echo "  - $HOST_OPENCODE_DIR"
echo "  - $HOST_OPENCODE_CONFIG_DIR"
echo "  - $HOST_OPENSPEC_CONFIG_DIR"
echo "  - $HOST_VIBE_KANBAN_CONFIG_DIR"
echo "  - $HOST_VIBE_KANBAN_DIR"
echo ""
echo "These directories are now mapped to the container and will persist data."
echo ""
echo "You can now start the container:"
echo "  docker compose up -d"
echo ""
