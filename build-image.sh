#!/bin/bash

# OpenCode Kanban Docker Image Build Script
# Builds the Docker image with a fixed name: successage/opencode-kanban

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fixed image name
IMAGE_NAME="successage/opencode-kanban"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building Docker Image${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Image name: $IMAGE_NAME"
echo ""

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Error: Dockerfile not found in current directory.${NC}"
    exit 1
fi

# Check if image already exists
BUILD_OPTS=""
if docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo -e "${YELLOW}Image '$IMAGE_NAME' already exists.${NC}"
    echo ""
    echo "Image details:"
    docker image inspect "$IMAGE_NAME" --format='  ID: {{.Id}}' 2>/dev/null | head -1
    docker image inspect "$IMAGE_NAME" --format='  Created: {{.Created}}' 2>/dev/null | head -1
    docker image inspect "$IMAGE_NAME" --format='  Size: {{.Size}}' 2>/dev/null | head -1 | sed 's/ bytes//' | awk '{printf "  Size: %.2f MB\n", $1/1024/1024}'
    echo ""
    read -p "Rebuild with --no-cache? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BUILD_OPTS="--no-cache"
        echo -e "${YELLOW}Will rebuild with --no-cache (no layer caching).${NC}"
    else
        echo -e "${GREEN}Will rebuild using layer cache (faster).${NC}"
    fi
    echo ""
fi

# Build the image
echo -e "${GREEN}Building image...${NC}"
echo ""

docker build $BUILD_OPTS -t "$IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Image name: $IMAGE_NAME"
    echo ""
    echo "Image details:"
    docker image inspect "$IMAGE_NAME" --format='  ID: {{.Id}}' 2>/dev/null | head -1
    docker image inspect "$IMAGE_NAME" --format='  Created: {{.Created}}' 2>/dev/null | head -1
    docker image inspect "$IMAGE_NAME" --format='  Size: {{.Size}}' 2>/dev/null | head -1 | sed 's/ bytes//' | awk '{printf "  Size: %.2f MB\n", $1/1024/1024}'
    echo ""
    echo "You can now run:"
    echo "  docker compose up -d"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Build failed!${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
