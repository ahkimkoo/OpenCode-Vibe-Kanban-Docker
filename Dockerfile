# Use Ubuntu 24.04 LTS as base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# Create working directory
WORKDIR /root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    python3 \
    python3-pip \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-server \
    fuse-overlayfs \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
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

RUN mkdir -p /app/docker-data

COPY docker-daemon.json /etc/docker/daemon.json

COPY docker-init.sh /etc/init.d/docker
RUN chmod +x /etc/init.d/docker

RUN mkdir -p /var/run/sshd \
    && echo 'root:pwd4root' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'Port 2222' >> /etc/ssh/sshd_config

COPY clean-ssh-config /etc/ssh/sshd_config

COPY clean-ssh-config /etc/ssh/sshd_config

# Copy startup script
COPY start.sh /root/start.sh
RUN chmod +x /root/start.sh

# Expose ports
# 4096: OpenCode web server
# 3927: vibe-kanban
# 2026: User service (reserved)
# 2222: SSH server
EXPOSE 4096 3927 2026 2222

# Set default working directory
WORKDIR /root/project

# Run startup script
CMD ["/root/start.sh"]
