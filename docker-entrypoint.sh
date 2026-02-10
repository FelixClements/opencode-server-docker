#!/bin/sh
set -e

# Start with the command "serve"
COMMAND="serve"

# 1. Handle Port
# If PORT env var is set, append --port <val>
if [ -n "$PORT" ]; then
    COMMAND="$COMMAND --port $PORT"
fi

# 2. Handle Hostname
# Default to 0.0.0.0 in Docker so it is accessible outside the container,
# unless explicitly overridden.
if [ -n "$HOSTNAME_OVERRIDE" ]; then
    COMMAND="$COMMAND --hostname $HOSTNAME_OVERRIDE"
else
    COMMAND="$COMMAND --hostname 0.0.0.0"
fi

# 3. Handle mDNS
# If MDNS=true, add the flag
if [ "$MDNS" = "true" ]; then
    COMMAND="$COMMAND --mdns"
fi

# 4. Handle mDNS Domain
if [ -n "$MDNS_DOMAIN" ]; then
    COMMAND="$COMMAND --mdns-domain $MDNS_DOMAIN"
fi

# 5. Handle CORS
# Docker users often set CORS as a comma-separated string (e.g., "http://a,http://b")
# We split that string into multiple --cors flags.
if [ -n "$CORS" ]; then
    # Split string by comma
    IFS=',' read -ra ORIGINS <<< "$CORS"
    for origin in "${ORIGINS[@]}"; do
        # Trim whitespace and append flag
        COMMAND="$COMMAND --cors $(echo $origin | xargs)"
    done
fi

# Execute the opencode command with constructed arguments
# Pass all other arguments ($@) as well to allow manual overrides
exec opencode $COMMAND "$@"
