FROM oven/bun:1 AS bun_runtime

FROM golang:1.24-bookworm AS go_runtime

FROM python:3.14-slim-bookworm

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    bash \
    gosu \
    git \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go_runtime /usr/local/go /usr/local/go
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
