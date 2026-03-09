# 1. Switch to a Debian-based image for glibc compatibility
FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -y \
    curl \
    bash \
    gosu \
    git \
    python3 \
    python3-pip \
    python3-venv \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

RUN npm i -g \
    opencode-ai \
    bash-language-server \
    pyright \
    vscode-langservers-extracted \
    yaml-language-server \
    && GOBIN=/usr/local/bin go install golang.org/x/tools/gopls@latest

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
