# docker‑opencode‑serve

A ready‑to‑use Docker image that runs **`opencode serve`**, the headless HTTP server exposing an OpenAPI endpoint for Opencode clients.  
The image is pre‑configured with an entrypoint that maps environment variables to the CLI flags, so you can control every server option (port, hostname, mDNS, CORS, authentication, …) without writing custom scripts.

## 🚀 What the image does

| Feature | How it’s exposed |
| ------- | ---------------- |
| **Port & Hostname** | `PORT` and `HOSTNAME_OVERRIDE` (defaults to `0.0.0.0` inside Docker) |
| **CORS origins** | `CORS` – comma‑separated list (e.g. `http://localhost:5173,https://app.example.com`) |
| **mDNS discovery** | `MDNS=true` and optional `MDNS_DOMAIN` |
| **HTTP Basic Auth** | `OPENCODE_SERVER_USERNAME` (default = `opencode`) and `OPENCODE_SERVER_PASSWORD` |
| **Automatic flag handling** | The entrypoint script builds the proper `opencode serve [flags]` command from the env vars |
| **CI / CD** | GitHub Actions workflow builds multi‑arch images (amd64 / arm64) and pushes them to GitHub Container Registry (GHCR) on every push to `main` or on version tags (`v*`). |

## 📦 Quickstart (Docker CLI)

```bash
docker run -d \
  -p 4096:4096 \
  -e PORT=4096 \
  -e OPENCODE_SERVER_PASSWORD=superSecret \
  -e CORS=http://localhost:5173,https://app.example.com \
  -e MDNS=true \
  ghcr.io/<YOUR_USER>/docker-opencode-serve:latest
