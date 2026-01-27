# OpenCode + Vibe-Kanban Docker Image

[简体中文](README.zh-CN.md) | English

Docker image based on Ubuntu 24.04 LTS, pre-installed with OpenCode and Vibe-Kanban, along with related OpenCode plugins.

## Features

- **OpenCode**: Open-source AI programming agent
- **Claude Code**: Claude AI code editor (pre-installed)
- **Vibe-Kanban**: Project management tool
- **Docker**: Full Docker engine with Docker Compose support (Docker-in-Docker)
- **SSH**: SSH server for remote access
- **Programming Languages**: Pre-installed development environments
  - **Go**: Golang development environment
  - **Rust**: Rust toolchain and cargo package manager
  - **Node.js 20**: Installed via NodeSource repository
  - **Python 3**: Includes pip package manager
  - **Conda**: Package and environment manager (envs stored in `/app/conda-env/`)
- **Git**: Version control system
- **Build tools**: build-essential toolchain

## Installed OpenCode Plugins

The following plugins are installed and can be used in OpenCode:

- **oh-my-opencode**: OpenCode enhancements ([GitHub](https://github.com/code-yeongyu/oh-my-opencode))
- **superpowers**: OpenCode superpowers ([GitHub](https://github.com/obra/superpowers))
- **playwright-mcp**: Playwright MCP server ([GitHub](https://github.com/microsoft/playwright-mcp))
- **agent-browser**: Agent browser ([GitHub](https://github.com/vercel-labs/agent-browser))
- **chrome-devtools-mcp**: Chrome DevTools MCP server ([GitHub](https://github.com/ChromeDevTools/chrome-devtools-mcp))

## Port Mappings

 | Port | Service | Description |
|------|---------|-------------|
 | 2046  | OpenCode | OpenCode Web server |
| 3927  | Vibe-Kanban | Vibe-Kanban Web interface |
| 2027  | Reserved | For user custom services |
| 2211  | SSH | SSH server for remote access |

## Volume Mappings

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `./project` | `/home/user/project` | Default working directory, project files stored here |
| `./vibe-kanban` | `/var/tmp/vibe-kanban` | Vibe-Kanban data directory |
| `./app` | `/app` | Application directory |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket for Docker-in-Docker |

## Quick Start

### Prerequisites

- Docker 20.10 or higher
- Docker Compose 2.0 or higher

### Starting with Docker Compose

1. Clone or download this repository locally

```bash
git clone <repository-url>
cd <repository-directory>
```

2. Start the service

```bash
docker compose up -d
```

3. Access the services

- **OpenCode**: http://localhost:2046
- **Vibe-Kanban**: http://localhost:3927

### Running with Docker Directly

```bash
docker build -t successage/opencode-vibe-kanban-docker:latest .
docker run -d \
  --name opencode-vibe \
  --privileged \
  -p 2046:2046 \
  -p 3927:3927 \
  -p 2027:2027 \
  -p 2211:2211 \
  -v $(pwd)/project:/home/user/project \
  -v $(pwd)/vibe-kanban:/var/tmp/vibe-kanban \
  -v $(pwd)/app:/app \
  -v /var/run/docker.sock:/var/run/docker.sock \
  successage/opencode-vibe-kanban-docker:latest
```

## Usage

### Project Directory

`/home/user/project` is the default working directory. Place your project files in the `./project` directory, and they will be automatically available in the container.

### OpenCode

The OpenCode server starts automatically when the container starts, listening on port 2046.

When starting OpenCode for the first time, you will see a warning message:
```
! OPENCODE_SERVER_PASSWORD is not set; server is unsecured.
```

This is expected behavior. If secure access is needed, you can set the environment variable `OPENCODE_SERVER_PASSWORD` in docker-compose.yml.

### Vibe-Kanban

The Vibe-Kanban server starts automatically when the container starts, listening on port 3927.

### Claude Code

Claude Code is pre-installed and ready to use. Configuration files will be automatically synced between the container and host (`./userdata/.claude.json` and `./userdata/.claude/`).

**First-time setup:**
```bash
# 1. Start the container
docker-compose up -d

# 2. Connect to container via SSH
ssh -p 2211 user@localhost
# Password: pwd4user

# 3. Run Claude Code (will prompt for login on first run)
claude

# 4. Configuration files will be automatically saved to ./userdata/
```

**Subsequent usage:**
Configuration persists across container restarts. Simply run `claude` after connecting via SSH.

### SSH Access

The SSH server starts automatically when the container starts, listening on port 2211.

**Connection details:**
- Host: localhost (or your server IP)
- Port: 2211
- Username: user
- Password: pwd4user

```bash
ssh -p 2211 user@localhost
```

### Docker-in-Docker

The container includes a full Docker installation that starts automatically. This allows you to run and manage Docker containers from within the container.

**Docker configuration:**
- Storage driver: fuse-overlayfs (required for running Docker inside containers)
- Custom network configuration to avoid conflicts with host:
  - Bridge IP: 192.168.200.1/24
  - Default address pools: 10.200.0.0/16
  - MTU: 1400
- Data directory: /app/docker-data

**Docker Compose:**
Both `docker compose` and `docker-compose` commands are available.

**Note:** For Docker-in-Docker to work properly, the container must be started in privileged mode and the Docker socket must be mounted. These are configured in docker-compose.yml.

### Custom Services

Port 2027 is reserved for users to start their own services. For example:

```bash
docker exec -it opencode-vibe bash
cd /home/user/project
python -m http.server 2027
```

Then access your service at http://localhost:2027.

## Stopping Services

```bash
docker compose down
```

## Viewing Logs

```bash
docker compose logs -f
```

## Entering Container

```bash
docker exec -it opencode-vibe bash
```

## Troubleshooting

### Port Already in Use

If you see an "address already in use" error, the port is already occupied. You can:

1. Stop the process occupying the port
2. Or modify the port mappings in `docker-compose.yml`

### Volume Permission Issues

If you encounter file permission issues in the container, you can adjust the host directory permissions:

```bash
chmod -R 755 project vibe-kanban
```

### Restarting Container

```bash
docker compose restart
```

## Image Size

- **Build size**: ~832MB
- **Base image**: Ubuntu 24.04 LTS

## Development

### Rebuilding Image

```bash
docker compose build --no-cache
```

### Cleanup

```bash
docker compose down
docker system prune -a
```

## License

Software components included in this image follow their respective licenses:

- [OpenCode](https://github.com/anomalyco/opencode)
- [Vibe-Kanban](https://github.com/BloopAI/vibe-kanban)
- [Ubuntu](https://ubuntu.com/legal/terms-and-policies)

## Support and Contributions

- OpenCode documentation: https://opencode.ai/docs
- OpenCode GitHub: https://github.com/anomalyco/opencode
- Vibe-Kanban GitHub: https://github.com/BloopAI/vibe-kanban

## Notes

1. **Port conflicts**: Default ports 2046, 3927, 2027, and 2211 may be occupied by other services. Please ensure these ports are available or modify the port mappings.
2. **Data persistence**: All data is saved to the host via volume mappings. Deleting the container will not lose data.
3. **Security**: By default, the OpenCode server has no password set. In production, please set the `OPENCODE_SERVER_PASSWORD` environment variable.
4. **SSH security**: The default SSH password (pwd4user) should be changed in production environments. You can modify it by rebuilding the image with a custom configuration.
5. **Docker-in-Docker**: Running Docker inside Docker requires privileged mode and Docker socket mounting, which are configured in docker-compose.yml. This setup is suitable for development but should be carefully evaluated for production use.
6. **Playwright browser**: The Playwright Chromium browser is pre-installed and ready to use.

## Changelog

### v2.0.0 (2026-01-23)

- Add Docker engine with Docker-in-Docker support
- Add SSH server for remote access (port 2211, user/pwd4user)
- Configure Docker for container environment (fuse-overlayfs, custom network)
- Add Docker init script for service management
- Update docker-compose.yml with privileged mode and Docker socket mount
- Add app volume mapping (./app → /app)
- Update documentation for SSH and Docker features

### v1.0.0 (2026-01-23)

- Initial release
- Install OpenCode 1.1.33
- Install Vibe-Kanban
- Pre-install 5 OpenCode plugins (oh-my-opencode, superpowers, playwright-mcp, agent-browser, chrome-devtools-mcp)
- Configure dual service startup scripts
- Port mappings: 2046 (OpenCode), 3927 (Vibe-Kanban), 2027 (custom)
- Volume mapping support for project persistence
