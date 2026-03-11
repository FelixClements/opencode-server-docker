FROM node:24-bookworm-slim AS node_runtime

FROM oven/bun:1 AS bun_runtime

FROM golang:1.24-bookworm AS go_runtime

FROM python:3.14-slim-bookworm

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    gosu \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go_runtime /usr/local/go /usr/local/go
COPY --from=node_runtime /usr/local/bin/node /usr/local/bin/node
COPY --from=node_runtime /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node_runtime /usr/local/bin/npx /usr/local/bin/npx
COPY --from=node_runtime /usr/local/bin/corepack /usr/local/bin/corepack
COPY --from=node_runtime /usr/local/include/node /usr/local/include/node
COPY --from=node_runtime /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=bun_runtime /usr/local/bin/bun /usr/local/bin/bun
COPY --from=bun_runtime /usr/local/bin/bunx /usr/local/bin/bunx

ENV PATH="/usr/local/go/bin:${PATH}"

RUN npm i -g \
    opencode-ai \
    bash-language-server \
    pyright \
    vscode-langservers-extracted \
    yaml-language-server

RUN GOBIN=/usr/local/bin go install golang.org/x/tools/gopls@latest

WORKDIR /app

# 4. Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose the default port
EXPOSE 4096

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command runs the server
CMD ["serve"]
