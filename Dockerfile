# Use Ubuntu 24.04 LTS as base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# Create working directory
WORKDIR /home/user

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
    sudo \
    fuse-overlayfs \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install Playwright
RUN npm install -g playwright \
    && playwright install \
    && playwright install chrome

# Install agent-browser
RUN npm install -g agent-browser \
    && agent-browser install

# Install Golang (latest stable)
RUN curl -fsSL https://go.dev/dl/go1.21.6.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && export PATH=/usr/local/go/bin:${PATH} \
    && go version

# Install Rust via apt (faster, more reliable than rustup download)
RUN apt-get update \
    && apt-get install -y rustc cargo \
    && rm -rf /var/lib/apt/lists/* \
    && rustc --version \
    && cargo --version

# Install Miniconda and configure custom env path
RUN mkdir -p /app/conda-env \
    && curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /home/user/miniconda3 \
    && rm /tmp/miniconda.sh \
    && /home/user/miniconda3/bin/conda config --append envs_dirs /app/conda-env \
    && echo "export PATH=/home/user/miniconda3/bin:\$PATH" >> /home/user/.bashrc \
    && /home/user/miniconda3/bin/conda --version

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

RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/home/user/.opencode/bin:/home/user/.bun/bin:/home/user/miniconda3/bin:/usr/local/go/bin:/home/user/.cargo/bin:${PATH}"

# Install vibe-kanban
#RUN npm install -g vibe-kanban@latest

# Create user with sudo privileges and setup directories
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /bin/bash user \
    && echo 'user:pwd4user' | chpasswd \
    && echo 'user ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir -p /home/user/project \
    && mkdir -p /home/user/.local/state \
    && mkdir -p /home/user/.local/share \
    && mkdir -p /app/docker-data \
    && usermod -aG docker user \
    && chown -R user:user /home/user

COPY docker-daemon.json /etc/docker/daemon.json

COPY docker-init.sh /etc/init.d/docker
RUN chmod +x /etc/init.d/docker

RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY ssh-config /etc/ssh/sshd_config

# Generate SSH host keys and set correct permissions
RUN ssh-keygen -A \
    && chmod 600 /etc/ssh/ssh_host_*_key \
    && chmod 644 /etc/ssh/ssh_host_*_key.pub

# Switch to user
USER user

# Install Bun for oh-my-opencode
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/home/user/.bun/bin:${PATH}"

# Install oh-my-opencode platform package first
RUN bun install oh-my-opencode-linux-x64

# Install oh-my-opencode (non-interactive mode for Docker)
RUN bunx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no --opencode-zen=no --zai-coding-plan=no

# Copy startup script
COPY --chown=user start.sh /home/user/start.sh
RUN chmod +x /home/user/start.sh

# Expose ports
# 2046: OpenCode web server
# 3927: vibe-kanban
# 2027: User service (reserved)
# 2211: SSH server
EXPOSE 2046 3927 2027 2211

# Set default working directory
WORKDIR /home/user/project

# Run startup script as user
CMD ["/home/user/start.sh"]
