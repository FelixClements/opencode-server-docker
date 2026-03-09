#!/bin/bash
set -e

# PUID/PGID Configuration (defaults to root if not set)
PUID=${PUID:-0}
PGID=${PGID:-0}

# Data directory configuration
DATA_DIR="/data"
CONFIG_DIR="$DATA_DIR/config"
LEGACY_OPENCODE_DIR="$DATA_DIR/.opencode"
CANONICAL_SUBDIRS=(agents commands modes plugins skills tools themes)

# Export environment variables for the running application
export DATA_DIR
export CONFIG_DIR
export LEGACY_OPENCODE_DIR
export HOME="/root"
export OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$CONFIG_DIR}"
export OPENCODE_CONFIG="${OPENCODE_CONFIG:-$CONFIG_DIR/opencode.json}"

migrate_legacy_directories() {
    local legacy_dir
    local canonical_dir
    local canonical_contents

    for dir in "${CANONICAL_SUBDIRS[@]}"; do
        legacy_dir="$LEGACY_OPENCODE_DIR/$dir"
        canonical_dir="$CONFIG_DIR/$dir"
        canonical_contents=()

        if [ -d "$canonical_dir" ]; then
            shopt -s nullglob dotglob
            canonical_contents=("$canonical_dir"/*)
            shopt -u nullglob dotglob
        fi

        if [ -d "$legacy_dir" ] && [ ${#canonical_contents[@]} -eq 0 ]; then
            mkdir -p "$canonical_dir"
            cp -a "$legacy_dir/." "$canonical_dir/"
        fi
    done
}

create_directories() {
    echo "Creating OpenCode data directories..."

    mkdir -p "$DATA_DIR" "$CONFIG_DIR"

    migrate_legacy_directories

    for dir in "${CANONICAL_SUBDIRS[@]}"; do
        mkdir -p "$CONFIG_DIR/$dir"
    done

    mkdir -p /root/.config
    chmod 755 /root /root/.config
    rm -rf /root/.config/opencode
    ln -s "$CONFIG_DIR" /root/.config/opencode

    echo "Directory structure created successfully."
}

# Set ownership of data directories
set_ownership() {
    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        echo "Setting ownership to PUID=$PUID, PGID=$PGID..."
        chown -R "$PUID:$PGID" "$DATA_DIR"
        chown -R "$PUID:$PGID" /root/.config
    fi
}

# Create user if PUID/PGID are specified
create_user() {
    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        # Check if group exists, create if not
        if ! getent group "$PGID" > /dev/null 2>&1; then
            groupadd -g "$PGID" opencode
        fi
        
        # Check if user exists, create if not
        if ! id -u "$PUID" > /dev/null 2>&1; then
            useradd -u "$PUID" -g "$PGID" -d /root -s /bin/bash opencode
        fi
    fi
}

# Build the opencode serve command
build_command() {
    local args=(serve)
    
    # 1. Handle Port
    if [ -n "$PORT" ]; then
        args+=(--port "$PORT")
    fi
    
    # 2. Handle Hostname (default to 0.0.0.0 in Docker)
    if [ -n "$HOSTNAME_OVERRIDE" ]; then
        args+=(--hostname "$HOSTNAME_OVERRIDE")
    else
        args+=(--hostname 0.0.0.0)
    fi
    
    # 3. Handle mDNS
    if [ "$MDNS" = "true" ]; then
        args+=(--mdns)
    fi
    
    # 4. Handle mDNS Domain
    if [ -n "$MDNS_DOMAIN" ]; then
        args+=(--mdns-domain "$MDNS_DOMAIN")
    fi
    
    # 5. Handle CORS (comma-separated list)
    if [ -n "$CORS" ]; then
        IFS=',' read -ra ORIGINS <<< "$CORS"
        for origin in "${ORIGINS[@]}"; do
            args+=(--cors "$(echo "$origin" | xargs)")
        done
    fi

    printf '%s\n' "${args[@]}"
}

run_opencode_server() {
    local command_args=()

    while IFS= read -r line; do
        command_args+=("$line")
    done < <(build_command)

    command_args+=("$@")

    echo "Starting opencode server..."

    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        exec gosu "$PUID:$PGID" opencode "${command_args[@]}"
    else
        exec opencode "${command_args[@]}"
    fi
}

# Main execution
main() {
    create_directories
    create_user
    set_ownership

    if [ "$#" -eq 0 ]; then
        run_opencode_server
    fi

    case "$1" in
        serve)
            shift
            run_opencode_server "$@"
            ;;
        -*)
            run_opencode_server "$@"
            ;;
        *)
            if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
                exec gosu "$PUID:$PGID" "$@"
            else
                exec "$@"
            fi
            ;;
    esac
}

# Run main function
main "$@"
