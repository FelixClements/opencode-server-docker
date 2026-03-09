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

The container persists OpenCode data through a single host mount: `./opencode-data:/data`. Inside the container, `/data/config` is the canonical OpenCode global config root, and `/root/.config/opencode` is symlinked to that location at startup.

### Volume Mount

Mount a host directory to `/data` to persist config, credentials, and custom OpenCode resources:

```bash
docker run -d \
  -p 4096:4096 \
  -v ./opencode-data:/data \
  -v .:/workspace \
  -e OPENCODE_SERVER_PASSWORD=superSecret \
  -e OPENCODE_CONFIG_DIR=/data/config \
  -e OPENCODE_CONFIG=/data/config/opencode.json \
  ghcr.io/felixclements/opencode-server-docker:latest
```

Or with Docker Compose, see `docker-compose.yml`.

### Project Directory

The current project directory is mounted to `/workspace` inside the container. This allows OpenCode to access and modify your project files. Changes made by OpenCode are immediately visible in your IDE and vice versa.

The `opencode-data/` directory contains user-specific configuration and should not be committed to version control. It is included in `.gitignore`.

### Directory Structure

The mounted volume should contain:

```text
opencode-data/
├── auth.json
└── config/
    ├── opencode.json
    ├── agents/
    ├── commands/
    ├── modes/
    ├── plugins/
    ├── skills/
    │   └── <name>/SKILL.md
    ├── tools/
    └── themes/
```

Legacy `opencode-data/.opencode/*` content is treated as a compatibility source only. On startup, the entrypoint copies legacy directories into the canonical `opencode-data/config/*` location when the canonical destination does not already exist.

### Config Precedence

OpenCode loads config in this order (later sources override earlier ones):

1. Remote config (from .well-known/opencode) - organizational defaults
2. Global config (`~/.config/opencode/opencode.json`) - user preferences
3. Custom config (`OPENCODE_CONFIG` env var) - custom overrides
4. Project config (`opencode.json` in project) - project-specific settings
5. Global resource directories under `~/.config/opencode/` - agents, commands, plugins, skills, tools, themes, and related resources
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
  -v ./opencode-data:/data \
  -v .:/workspace \
  -e OPENCODE_SERVER_PASSWORD=superSecret \
  -e OPENCODE_CONFIG_DIR=/data/config \
  -e OPENCODE_CONFIG=/data/config/opencode.json \
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

## Baked-In Tooling

The image ships with Python, Go, and the default LSP bundle already installed. Fresh containers have `python3`, `pip3`, `go`, `pyright-langserver`, `gopls`, `bash-language-server`, `yaml-language-server`, and `vscode-json-language-server` on `PATH` without any first-run install step.

## Building

```bash
docker build -t ghcr.io/felixclements/opencode-server-docker:latest .
```

## Smoke Checks

```bash
docker build -t opencode-local:test .
docker run --rm opencode-local:test bash -lc 'python3 --version && go version && command -v pyright-langserver && command -v gopls && command -v bash-language-server && command -v yaml-language-server && command -v vscode-json-language-server'
rm -rf ./opencode-data && mkdir -p ./opencode-data
docker compose up -d
docker exec opencode-server bash -lc 'test -d /data/config && test -d /data/config/skills && test -L /root/.config/opencode && [ "$(readlink -f /root/.config/opencode)" = "/data/config" ]'
rm -rf ./opencode-data && mkdir -p ./opencode-data/.opencode/skills/demo && printf '# Demo\n' > ./opencode-data/.opencode/skills/demo/SKILL.md
docker run --rm -v "$PWD/opencode-data:/data" opencode-local:test bash -lc 'test -f /data/config/skills/demo/SKILL.md'
docker run --rm -e PUID=1000 -e PGID=1000 -v "$PWD/opencode-data:/data" opencode-local:test bash -lc 'opencode --help >/dev/null && test -L /root/.config/opencode'
docker run --rm -e PUID=1000 -e PGID=1000 opencode-local:test bash -lc 'command -v pyright-langserver && command -v gopls && command -v bash-language-server && command -v yaml-language-server && command -v vscode-json-language-server'
```

## .gitignore

The repository includes a `.gitignore` file that excludes:
- `opencode-data/` - User credentials and custom configurations
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Environment files (`.env`, `.env.local`)

## License

MIT
