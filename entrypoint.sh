#!/bin/bash
# general good practice (stop on error, missing variables):
set -eu

# Validate required environment variables
if [ -z "${USER:-}" ] || [ -z "${UID:-}" ] || [ -z "${GID:-}" ]; then
    echo "Error: USER, UID, and GID environment variables must be set" >&2
    exit 1
fi

# Verify Wine prefix is initialized
if [ ! -d "${WINEPREFIX:-/root/.wine}" ]; then
    echo "Error: Wine prefix not initialized. Check Dockerfile Wine installation." >&2
    exit 1
fi

# Creating user: $USER ($UID:$GID)
if ! id "$USER" &>/dev/null 2>&1; then
    homeCommand="--create-home"
    if [ -d "/home/$USER" ]; then
        homeCommand="-d /home/$USER"
    fi
    groupadd --system --gid=$GID "$USER" 2>/dev/null || true
    useradd --system --gid=$GID --uid=$UID $homeCommand "$USER" 2>/dev/null || true
fi

# Ensure HeidiSQL config directory exists and is writable
mkdir -p /root/.config/HeidiSQL
chmod 755 /root/.config/HeidiSQL

exec sudo --preserve-env -u "$USER" "$@"