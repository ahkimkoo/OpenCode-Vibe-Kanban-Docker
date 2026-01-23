# OpenCode + Vibe-Kanban Docker 镜像

简体中文 | [English](README.md)

基于 Ubuntu 24.04 LTS 的 Docker 镜像，预装了 OpenCode 和 Vibe-Kanban，以及相关的 OpenCode 插件。

## 功能特性

- **OpenCode**: 开源 AI 编程代理
- **Vibe-Kanban**: 项目管理工具
- **Node.js 20**: 通过 NodeSource 仓库安装
- **Python 3**: 包含 pip 包管理器
- **Git**: 版本控制系统
- **构建工具**: build-essential 工具链

## 已安装的 OpenCode 插件

以下插件已安装，可以在 OpenCode 中使用：

- **oh-my-opencode**: OpenCode 增强功能 ([GitHub](https://github.com/code-yeongyu/oh-my-opencode))
- **superpowers**: OpenCode 超级能力 ([GitHub](https://github.com/obra/superpowers))
- **playwright-mcp**: Playwright MCP 服务器 ([GitHub](https://github.com/microsoft/playwright-mcp))
- **agent-browser**: 代理浏览器 ([GitHub](https://github.com/vercel-labs/agent-browser))
- **chrome-devtools-mcp**: Chrome DevTools MCP 服务器 ([GitHub](https://github.com/ChromeDevTools/chrome-devtools-mcp))

## 端口映射

| 端口 | 服务 | 说明 |
|------|------|------|
| 4096  | OpenCode | OpenCode Web 服务器 |
| 3721  | Vibe-Kanban | Vibe-Kanban Web 界面 |
| 2026  | 保留 | 用于用户自定义服务 |

## 目录映射

| 宿主机路径 | 容器路径 | 说明 |
|-----------|----------------|-------------|
| `./project` | `/root/project` | 默认工作目录，项目文件存放于此 |
| `./vibe-kanban` | `/var/tmp/vibe-kanban` | Vibe-Kanban 数据目录 |

## 快速开始

### 前提条件

- Docker 20.10 或更高版本
- Docker Compose 2.0 或更高版本

### 使用 Docker Compose 启动

1. 克隆或下载此仓库到本地

```bash
git clone <repository-url>
cd <repository-directory>
```

2. 启动服务

```bash
docker compose up -d
```

3. 访问服务

- **OpenCode**: http://localhost:4096
- **Vibe-Kanban**: http://localhost:3721

### 使用 Docker 直接运行

```bash
docker build -t opencode-vibe:latest .
docker run -d \
  --name opencode-vibe \
  -p 4096:4096 \
  -p 3721:3721 \
  -p 2026:2026 \
  -v $(pwd)/project:/root/project \
  -v $(pwd)/vibe-kanban:/var/tmp/vibe-kanban \
  opencode-vibe:latest
```

## 使用说明

### 项目目录

`/root/project` 是默认的工作目录。将你的项目文件放在 `./project` 目录中，它们将自动在容器中可用。

### OpenCode

OpenCode 服务器会在容器启动时自动启动，监听端口 4096。

首次启动 OpenCode 时，你会看到一条警告消息：
```
! OPENCODE_SERVER_PASSWORD is not set; server is unsecured.
```

这是预期的行为。如果需要安全访问，可以在 docker-compose.yml 中设置环境变量 `OPENCODE_SERVER_PASSWORD`。

### Vibe-Kanban

Vibe-Kanban 服务器会在容器启动时自动启动，监听端口 3721。

### 自定义服务

端口 2026 预留给用户启动自己的服务。例如：

```bash
docker exec -it opencode-vibe bash
cd /root/project
python -m http.server 2026
```

然后通过 http://localhost:2026 访问你的服务。

## 停止服务

```bash
docker compose down
```

## 查看日志

```bash
docker compose logs -f
```

## 进入容器

```bash
docker exec -it opencode-vibe bash
```

## 故障排除

### 端口已被占用

如果看到 "address already in use" 错误，说明端口已被占用。你可以：

1. 停止占用端口的进程
2. 或者修改 `docker-compose.yml` 中的端口映射

### 卷权限问题

如果在容器中遇到文件权限问题，可以调整宿主机目录权限：

```bash
chmod -R 755 project vibe-kanban
```

### 重启容器

```bash
docker compose restart
```

## 镜像大小

- **构建大小**: ~832MB
- **基础镜像**: Ubuntu 24.04 LTS

## 开发

### 重新构建镜像

```bash
docker compose build --no-cache
```

### 清理

```bash
docker compose down
docker system prune -a
```

## 许可证

本镜像中包含的软件组件遵循各自的许可证：

- [OpenCode](https://github.com/anomalyco/opencode)
- [Vibe-Kanban](https://github.com/BloopAI/vibe-kanban)
- [Ubuntu](https://ubuntu.com/legal/terms-and-policies)

## 支持与贡献

- OpenCode 文档: https://opencode.ai/docs
- OpenCode GitHub: https://github.com/anomalyco/opencode
- Vibe-Kanban GitHub: https://github.com/BloopAI/vibe-kanban

## 注意事项

1. **端口冲突**: 默认端口 4096、3721 和 2026 可能被其他服务占用。请确保这些端口可用或修改端口映射。
2. **数据持久化**: 所有数据都通过卷映射保存到宿主机。删除容器不会丢失数据。
3. **安全**: 默认情况下，OpenCode 服务器未设置密码。在生产环境中，请设置 `OPENCODE_SERVER_PASSWORD` 环境变量。
4. **Playwright 浏览器**: Playwright 的 Chromium 浏览器未预安装，需要时可使用 `npx playwright install chromium` 安装。

## 更新日志

### v1.0.0 (2026-01-23)

- 初始版本发布
- 安装 OpenCode 1.1.33
- 安装 Vibe-Kanban
- 预装 5 个 OpenCode 插件（oh-my-opencode, superpowers, playwright-mcp, agent-browser, chrome-devtools-mcp）
- 配置双服务启动脚本
- 端口映射：4096 (OpenCode), 3721 (Vibe-Kanban), 2026 (自定义)
- 卷映射支持项目持久化
