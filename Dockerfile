FROM node:24-alpine

# Install bash for the entrypoint script and opencode-ai
RUN apk add --no-cache bash && npm i -g opencode-ai

WORKDIR /app

# Copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment variables for Authentication
# OPENCODE_SERVER_PASSWORD is required to enable auth
ENV OPENCODE_SERVER_USERNAME=opencode
# OPENCODE_SERVER_PASSWORD is not set here to force usage at runtime

# Expose the default port
EXPOSE 4096

# Set the entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command runs the server
CMD ["serve"]
