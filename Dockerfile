FROM debian:bookworm-slim

ARG CHROME_DEVTOOLS_MCP_VERSION=1.0.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        dirmngr \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
        chromium \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove curl gnupg dirmngr

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN npm install -g chrome-devtools-mcp@${CHROME_DEVTOOLS_MCP_VERSION} \
    && npm cache clean --force

RUN useradd -m -s /bin/bash node \
    && mkdir -p /home/node/.cache \
    && chown -R node:node /home/node/.cache

USER node
WORKDIR /home/node

# ── Runtime ───────────────────────────────────────────────────────────────────
# --headless            : no display required inside the container
# --no-usage-statistics : do not phone home to Google analytics
# --executablePath      : point at the Debian-packaged Chromium binary
# Chrome flags:
#   --no-sandbox              : required inside Docker (no user namespace)
#   --disable-dev-shm-usage   : /dev/shm is often too small; use /tmp instead
#   --disable-gpu             : no GPU in a headless container
#   --remote-debugging-*      : bind CDP on all interfaces so host can connect
ENTRYPOINT ["chrome-devtools-mcp", \
    "--headless", \
    "--no-usage-statistics", \
    "--executablePath=/usr/bin/chromium", \
    "--chrome-arg=--no-sandbox", \
    "--chrome-arg=--disable-dev-shm-usage", \
    "--chrome-arg=--disable-gpu", \
    "--chrome-arg=--remote-debugging-port=9222", \
    "--chrome-arg=--remote-debugging-address=0.0.0.0"]
