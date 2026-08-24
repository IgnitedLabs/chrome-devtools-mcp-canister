#!/bin/sh
# Starts a virtual display + VNC viewer + Chrome for the shared persistent
# canister browser (docker-compose "Pattern B"). Lets a human log in to a
# gated site visually — credentials never pass through an MCP client or an
# AI agent's context, only through the person's own eyes/keyboard via noVNC.
set -e

DISPLAY_NUM=:99
export DISPLAY="$DISPLAY_NUM"

# /tmp is part of the container's own (non-volume) filesystem layer, so a
# `docker compose up -d` that restarts this same stopped container (rather
# than recreating it) sees whatever a previous, abruptly-killed Xvfb left
# behind. A stale lock here makes Xvfb silently refuse to (re)bind :99,
# which then cascades into "no X server" for x11vnc and Chrome alike. Only
# one Xvfb ever runs in this container, so it's always safe to clear it.
rm -f "/tmp/.X${DISPLAY_NUM#:}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM#:}"

# -ac: disable X11 access control so x11vnc (same user, no cookie
# exchange needed for a single-user container) can attach without an
# xauth dance.
Xvfb "$DISPLAY_NUM" -screen 0 1600x900x24 -ac &
XVFB_PID=$!

# Wait for the X server socket instead of a fixed sleep.
for i in $(seq 1 50); do
  [ -e "/tmp/.X11-unix/X${DISPLAY_NUM#:}" ] && break
  sleep 0.1
done

x11vnc -display "$DISPLAY_NUM" -nopw -forever -shared -rfbport 5900 -quiet &
websockify --web=/usr/share/novnc 6080 localhost:5900 &

cleanup() {
  kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup TERM INT

# A previous container using this same --user-data-dir (a volume, so it
# outlives the container) can leave a stale Singleton* lock behind if it
# didn't exit cleanly (e.g. force-recreate). Only one Chrome instance ever
# runs against this profile, so it's always safe to clear it on start.
rm -f /home/node/.cache/chrome-profile/Singleton*

exec chromium \
  --no-sandbox \
  --disable-dev-shm-usage \
  --remote-debugging-port=9222 \
  --user-data-dir=/home/node/.cache/chrome-profile \
  --window-size=1600,900 \
  --window-position=0,0 \
  --no-first-run \
  --no-default-browser-check
