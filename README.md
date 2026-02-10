# docker-opencode-serve

A ready-to-use Docker image that runs **`opencode serve`**, the headless HTTP server exposing an OpenAPI endpoint for OpenCode clients.
The image is pre-configured with an entrypoint that maps environment variables to the CLI flags, so you can control every server option (port, hostname, mDNS, CORS, authentication, …) without writing custom scripts.

## Features

| Feature | How it's exposed |
| ------- | ---------------- |
| **Port & Hostname** | `PORT` and `HOSTNAME_OVERRIDE` (defaults to `0.0.0.0` inside Docker) |
| **CORS origins** | `CORS` – comma-separated list (e.g. `http://localhost:5173,https://app.example.com`) |
| **mDNS discovery** | `MDNS=true` and optional `MDNS_DOMAIN` |
| **HTTP Basic Auth** | `OPENCODE_SERVER_USERNAME` (default=`opencode`) and `OPENCODE_SERVER_PASSWORD` |
| **Config directory** | `OPENCODE_CONFIG_DIR` – path to config directory |
| **Custom config file** | `OPENCODE_CONFIG` – path to specific config file |
| **Inline config** | `OPENCODE_CONFIG_CONTENT` – JSON config content at runtime |
| **Automatic flag handling** | The entrypoint script builds the proper `opencode serve [flags]` command from the env vars |
| **CI / CD** | GitHub Actions workflow builds multi-arch images (amd64/arm64) and pushes them to GitHub Container Registry (GHCR) on every push to `main` or on version tags (`v*`). |

## Persistent Storage

The container supports persistent storage for configuration, credentials, and custom agents/commands.

### Volume Mount

Mount a host directory to `/root/.local/share/opencode` to persist data:

```bash
docker run -d \
  -p 4096:4096 \
  -v ./opencode-data:/root/.local/share/opencode \
  -v .:/workspace \
  -e OPENCODE_SERVER_PASSWORD=superSecret \
  ghcr.io/felixclements/opencode-server-docker:latest
```

Or with Docker Compose, see the `docker-compose.yml` file.

### Project Directory

The current project directory is mounted to `/workspace` inside the container. This allows OpenCode to access and modify your project files. Changes made by OpenCode are immediately visible in your IDE and vice versa.

The `opencode-data/` directory contains user-specific configuration and should not be committed to version control. It is included in `.gitignore`.

### Directory Structure

The mounted volume should contain:

```
opencode-data/
├── auth.json              # API credentials (created via /connect command)
├── config/
│   └── opencode.json      # Global configuration file
└── .opencode/            # Custom agents, commands, modes, plugins, skills, tools, themes
    ├── agents/
    ├── commands/
    ├── modes/
    ├── plugins/
    ├── skills/
    ├── tools/
    └── themes/
```

### Config Precedence

OpenCode loads config in this order (later sources override earlier ones):

1. Remote config (from .well-known/opencode) - organizational defaults
2. Global config (`~/.config/opencode/opencode.json`) - user preferences
3. Custom config (`OPENCODE_CONFIG` env var) - custom overrides
4. Project config (`opencode.json` in project) - project-specific settings
5. `.opencode/` directories - agents, commands, plugins, etc.
6. Inline config (`OPENCODE_CONFIG_CONTENT` env var) - runtime overrides

### Environment Variables

#### Server Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `PORT` | `4096` | Port to listen on |
| `HOSTNAME_OVERRIDE` | `0.0.0.0` | Hostname to bind to |
| `MDNS` | `false` | Enable mDNS discovery |
| `MDNS_DOMAIN` | `opencode.local` | mDNS domain name |
| `CORS` | - | Comma-separated CORS origins |

#### Authentication

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `OPENCODE_SERVER_USERNAME` | `opencode` | Basic auth username |
| `OPENCODE_SERVER_PASSWORD` | - | Basic auth password (required for auth) |

#### Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `OPENCODE_CONFIG` | - | Path to custom config file |
| `OPENCODE_CONFIG_DIR` | - | Path to config directory |
| `OPENCODE_CONFIG_CONTENT` | - | Inline JSON config content |

## Quickstart (Docker CLI)

```bash
docker run -d \
  -p 4096:4096 \
  -v ./opencode-data:/root/.local/share/opencode \
  -v .:/workspace \
  -e OPENCODE_SERVER_PASSWORD=superSecret \
  -e CORS=http://localhost:5173,https://app.example.com \
  ghcr.io/felixclements/opencode-server-docker:latest
```

## Quickstart (Docker Compose)

```bash
git clone https://github.com/FelixClements/opencode-server-docker.git
cd opencode-server-docker
docker compose up -d
```

Edit `docker-compose.yml` to customize environment variables and mount volumes for persistent storage.

## Building

```bash
docker build -t ghcr.io/felixclements/opencode-server-docker:latest .
```

## .gitignore

The repository includes a `.gitignore` file that excludes:
- `opencode-data/` - User credentials and custom configurations
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Environment files (`.env`, `.env.local`)

## License

MIT
