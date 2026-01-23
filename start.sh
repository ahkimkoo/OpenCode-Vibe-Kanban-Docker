#!/bin/bash

# Change to project directory
cd /root/project

# Start OpenCode web server in background
echo "Starting OpenCode web server on port 4096..."
opencode --hostname 0.0.0.0 --port 4096 web &
OPENCODE_PID=$!

# Start vibe-kanban in background
echo "Starting vibe-kanban on port 3721..."
PORT=3721 HOST=0.0.0.0 npx vibe-kanban &
VIBE_PID=$!

# Function to handle shutdown
shutdown() {
    echo "Shutting down services..."
    kill $OPENCODE_PID 2>/dev/null
    kill $VIBE_PID 2>/dev/null
    wait $OPENCODE_PID 2>/dev/null
    wait $VIBE_PID 2>/dev/null
    exit 0
}

# Trap signals for graceful shutdown
trap shutdown SIGTERM SIGINT

# Wait for services
wait $OPENCODE_PID $VIBE_PID
