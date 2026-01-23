#!/bin/bash

echo "Starting Docker daemon..."
service docker start

echo "Starting SSH server on port 2222..."

# Start SSH daemon
/usr/sbin/sshd

# Change to project directory
cd /root/project

# Start OpenCode web server first (primary service)
echo "Starting OpenCode web server on port 4096..."
opencode --hostname 0.0.0.0 --port 4096 web &
OPENCODE_PID=$!

# Wait for OpenCode to initialize
echo "Waiting for OpenCode to start..."
sleep 8

# Check if OpenCode is running
if ! kill -0 $OPENCODE_PID 2>/dev/null; then
    echo "ERROR: OpenCode failed to start"
    exit 1
fi

# Start vibe-kanban in background
echo "Starting vibe-kanban on port 3927..."
PORT=3927 HOST=0.0.0.0 npx vibe-kanban &
VIBE_PID=$!

# Function to handle shutdown
shutdown() {
    echo "Shutting down services..."
    kill $OPENCODE_PID 2>/dev/null
    kill $VIBE_PID 2>/dev/null
    service docker stop
    killall sshd 2>/dev/null
    wait $OPENCODE_PID 2>/dev/null
    wait $VIBE_PID 2>/dev/null
    exit 0
}

# Trap signals for graceful shutdown
trap shutdown SIGTERM SIGINT

# Wait for services
wait $OPENCODE_PID $VIBE_PID
