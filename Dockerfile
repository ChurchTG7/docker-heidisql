FROM ubuntu:24.04

LABEL maintainer="Tibor Sári <tiborsari@gmx.de>"
LABEL description="Dockerized HeidiSQL (wine) - 2026 Revision"
LABEL version="2.0"

ARG WINE_VERSION=9.0
ARG HEIDISQL_VERSION=latest
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies with pinned versions
RUN apt-get update && apt-get install -y \
        wine-stable=9.0~ubuntu-1 \
        wine32=9.0~ubuntu-1 \
        unzip=6.0-27ubuntu1 \
        wget=1.21.4-1ubuntu4 \
        sudo=1.9.13p3-1ubuntu5 \
        ca-certificates=20240203 \
        --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

# Initialize Wine prefix and set up HeidiSQL directory
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win32

RUN mkdir -p /home/wine && \
    wineboot --init 2>/dev/null || true

# Download and install HeidiSQL with HTTPS
RUN cd /home/wine && \
    if [ "${HEIDISQL_VERSION}" = "latest" ]; then \
        HEIDISQL_URL=$(wget -q -O - "https://www.heidisql.com/download.php" | grep -oP 'https://www.heidisql.com/downloads/releases/HeidiSQL_[0-9.]+_Portable.zip' | head -1) && \
        wget --no-verbose --https-only "${HEIDISQL_URL}" -O HeidiSQL.zip && \
        unzip -q HeidiSQL.zip && \
        rm HeidiSQL.zip; \
    else \
        HEIDISQL_FILE="HeidiSQL_${HEIDISQL_VERSION}_Portable.zip" && \
        wget --no-verbose --https-only "https://www.heidisql.com/downloads/releases/${HEIDISQL_FILE}" -O "${HEIDISQL_FILE}" && \
        unzip -q "${HEIDISQL_FILE}" && \
        rm "${HEIDISQL_FILE}"; \
    fi && \
    chmod -R 755 /home/wine


# Declare volume for persistent HeidiSQL settings
VOLUME ["/root/.config/HeidiSQL"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set up the command arguments
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["wine", "/home/wine/heidisql.exe"]