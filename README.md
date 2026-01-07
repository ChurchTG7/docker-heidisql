## docker-heidisql
Dockerized HeidiSQL (wine) - 2026 Revision

### Overview
This containerized version of HeidiSQL runs on Ubuntu 24.04 with Wine 9.0+, enabling headless database management across platforms. The container uses ephemeral Wine environments (fresh for each run) with persistent HeidiSQL settings via volume mounting.

**Version Information:**
- Base: Ubuntu 24.04
- Wine: 9.0+ (stable)
- HeidiSQL: 12.5+ (or specified version)
- Last Updated: January 2026

### Quick Start

#### Basic X11 Socket Mount (Linux Native)
```bash
docker build -t heidisql:latest-ubuntu24.04 .
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "DISPLAY=$DISPLAY" \
    -e "WINEPREFIX=/root/.wine" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    --net="host" \
    heidisql:latest-ubuntu24.04
```

### Build Arguments

Customize versions at build time:

```bash
# Use latest HeidiSQL (default)
docker build -t heidisql:latest-ubuntu24.04 .

# Pin to specific HeidiSQL version
docker build \
    --build-arg HEIDISQL_VERSION=12.5 \
    -t heidisql:12.5-ubuntu24.04 .

# Override Wine version (if needed for compatibility)
docker build \
    --build-arg WINE_VERSION=9.0 \
    --build-arg HEIDISQL_VERSION=12.5 \
    -t heidisql:12.5-ubuntu24.04 .
```

### 2026 Revision - Display & Forwarding Options

#### Option 1: X11 Socket Mount (Linux, most direct)
Best for local Linux systems with X11. Shares the X11 socket directly.

```bash
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "DISPLAY=$DISPLAY" \
    -e "WINEPREFIX=/root/.wine" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    --net="host" \
    heidisql:latest-ubuntu24.04
```

#### Option 2: WSL2 (Windows Subsystem for Linux 2)
Use WSL2's built-in X11 support (Windows 11+). Set `DISPLAY` environment variable in WSL2.

```bash
# In WSL2 terminal:
export DISPLAY=$(grep nameserver /etc/resolv.conf | awk '{print $2}'):0
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "DISPLAY=$DISPLAY" \
    -e "WINEPREFIX=/root/.wine" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    heidisql:latest-ubuntu24.04
```

#### Option 3: SSH X11 Forwarding (Remote Systems)
Forward X11 over SSH tunnel for secure remote access.

```bash
# On remote server where container runs:
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "DISPLAY=localhost:10.0" \
    -e "WINEPREFIX=/root/.wine" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    heidisql:latest-ubuntu24.04

# On local client:
ssh -X user@remote-server
# Then run docker command above on remote
```

#### Option 4: VNC (Remote or Indirect Display)
Run container with VNC server for GUI access via VNC client (requires VNC setup in container).

```bash
# For persistent VNC setup, modify Dockerfile to include VNC packages
# Then expose VNC port:
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "WINEPREFIX=/root/.wine" \
    -p "5900:5900" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    heidisql:latest-ubuntu24.04-vnc

# Connect with VNC client: localhost:5900
```

### Architecture: Ephemeral Wine + Persistent Config

This container uses a **fresh Wine environment on each run**, while **HeidiSQL settings persist** across container restarts.

- **Ephemeral Wine**: `/root/.wine` is recreated fresh each container start → prevents stale/corrupted Wine state
- **Persistent HeidiSQL Config**: `/root/.config/HeidiSQL` is mounted as a Docker volume → retains database connections, saved queries, and settings

This design ensures:
1. Clean Wine environment (no leftover registry corruption)
2. Preserved HeidiSQL connection profiles and settings between runs
3. Easy backup: Just copy `~/.config/HeidiSQL` directory

### Usage with Your Databases

Test connections during container runtime:

```bash
docker run -it --rm \
    -e "USER=$USER" \
    -e "UID=$(id -u)" \
    -e "GID=$(id -g)" \
    -e "DISPLAY=$DISPLAY" \
    -e "WINEPREFIX=/root/.wine" \
    --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    --volume="$HOME/.config/HeidiSQL:/root/.config/HeidiSQL" \
    --net="host" \
    heidisql:latest-ubuntu24.04
```

Your database connection profiles will be available in HeidiSQL UI at startup. Add new connections as needed; they'll be saved to `~/.config/HeidiSQL` and persist for next run.

### Troubleshooting

**Container won't display GUI:**
- Check `$DISPLAY` is set: `echo $DISPLAY`
- Verify X11 socket exists: `ls -la /tmp/.X11-unix/`
- Try: `xhost +local:docker` (allows Docker X11 access)

**Wine prefix error:**
- Container automatically initializes Wine on first run via `wineboot`
- If issues persist, delete Wine cache: `rm -rf ~/.wine32`

**HeidiSQL won't start:**
- Verify download success: `docker build --progress=plain`
- Check latest version available: Visit https://www.heidisql.com/download.php
- Force specific version: `docker build --build-arg HEIDISQL_VERSION=12.5`

**Settings not persisting:**
- Ensure volume is mounted: `-v "$HOME/.config/HeidiSQL:/root/.config/HeidiSQL"`
- Verify directory exists on host: `mkdir -p ~/.config/HeidiSQL`

### Security Improvements (2026)
- ✅ HTTPS-only downloads (no HTTP)
- ✅ Pinned Ubuntu + Wine versions for reproducibility
- ✅ Updated HeidiSQL 12.5+ (vs. 9.3 from 2015)
- ✅ Reduced file permissions (755 vs. 777)
- ✅ Non-root Wine runtime with proper user isolation
- ✅ Explicit CA certificate bundle for TLS validation
    