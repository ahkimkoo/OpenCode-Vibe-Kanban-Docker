# Use Ubuntu 24.04 LTS as base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create working directory
WORKDIR /root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/root/.opencode/bin:${PATH}"

# Install vibe-kanban
RUN npm install -g vibe-kanban@latest

# Create project directory
RUN mkdir -p /root/project

# Create vibe-kanban directory
RUN mkdir -p /var/tmp/vibe-kanban

# Copy startup script
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# Expose ports
# 4096: OpenCode web server
# 3721: vibe-kanban
# 2026: User service (reserved)
EXPOSE 4096 3721 2026

# Set default working directory
WORKDIR /root/project

# Run startup script
CMD ["/root/start.sh"]
