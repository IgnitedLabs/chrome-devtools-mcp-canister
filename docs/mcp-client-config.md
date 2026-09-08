# MCP client configuration

The container image exposes the MCP server over **stdio** (stdin/stdout).

There are two supported patterns. Pick one — don't mix them for the same
client.

## Pattern A — isolated per-client browser (simple, single session)

Every client below launches the container as a subprocess, each with its
**own** headless Chrome inside. No separate `compose up` step needed. This
is fine as long as only one client/session runs at a time.

> **Note:** `--shm-size 2gb` is required. Chromium's renderer processes use
> shared memory heavily and will crash with the default 64 MB limit.

> **Do not add `-p 127.0.0.1:9222:9222`** to any of the snippets below if
> you might run more than one session concurrently. Each container tries to
> bind that host port for its own Chrome; only the first succeeds and every
> later one dies instantly with `CONNECTION_CLOSED`. Pattern A has no need
> for a published port at all — CDP stays internal to each container.

---

## Pattern B — shared persistent browser (multiple concurrent sessions)

Use this when several MCP clients/sessions need to browse *at the same
time* and you want them to share one browser (same cookies/login, one
Chrome process instead of N).

1. Start the shared Chrome daemon once (auto-restarts with Docker):
   ```bash
   docker compose up -d
   ```
   This runs `chrome-devtools-mcp-canister-chrome` — a non-headless Chrome
   (behind a virtual display, see step 4) with CDP on port 9222, **not**
   the MCP server itself. See the comment block at the top of
   `docker-compose.yaml` for why.

2. Point every client's MCP config at it via `--network container:<name>`
   (shares the container's network *namespace*, not just a network) and
   `--browserUrl`, instead of `--shm-size`/full entrypoint:
   ```json
   {
     "mcpServers": {
       "chrome-devtools": {
         "command": "docker",
         "args": [
           "run", "--rm", "-i",
           "--network", "container:chrome-devtools-mcp-canister-chrome",
           "--entrypoint", "chrome-devtools-mcp",
           "--env", "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true",
           "chrome-devtools-mcp-canister:latest",
           "--browserUrl", "http://127.0.0.1:9222",
           "--no-usage-statistics"
         ]
       }
     }
   }
   ```
   This exact snippet is `.mcp.json` at the repo root.

   **Why `--network container:<name>` and not a bridge network + hostname:**
   Chrome's DevTools port ignores `--remote-debugging-address=0.0.0.0` and
   always binds `127.0.0.1` only inside its own container — this is a
   Chromium security hardening, not something this image controls. That
   makes CDP unreachable by IP or hostname from any other container, and
   unreachable from the host even through a published port. The only way
   to reach it is to share the *same* network namespace, so `127.0.0.1`
   resolves to the same loopback on both sides.

   **Consequence:** `chrome-devtools-mcp-canister-chrome` (pinned via
   `container_name` in `docker-compose.yaml`) is load-bearing — every
   client config references it literally. Don't rename the compose
   service/container, and don't run a second copy of the compose stack.

3. Chrome's profile (cookies, logins) persists in the `chrome-cache` volume
   via `--user-data-dir`, so a login survives container restarts as long as
   the volume isn't removed.

4. **Logging in to a gated site.** The shared browser runs behind a virtual
   display (`Xvfb`) with a VNC server (`x11vnc`) and a web viewer
   (`noVNC`/`websockify`), started by `scripts/start-vnc-chrome.sh`. Open
   ```
   http://127.0.0.1:6080/vnc.html?autoconnect=true&resize=scale
   ```
   in a browser **on the host** — this shows the real screen of the
   containerized Chrome. Navigate to the site and log in directly with your
   keyboard/mouse. The credentials never pass through an MCP client, a
   `docker exec`, or an AI agent's context — only through your own input
   into that page, same as using any other browser. The resulting cookies
   land in the same profile every MCP client connects to (step 2), so once
   you're logged in there, every session sees it.

   noVNC is published as `127.0.0.1:6080` only, and `x11vnc` runs with
   `-nopw` (no password) — **never** change the port binding to `0.0.0.0`;
   that would let anyone on the LAN drive this browser, and anything it's
   logged in to, with no authentication at all.

---

## Pattern A snippets

## Claude Desktop

Edit `~/.claude.json`
(macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--shm-size", "2gb",
        "--env", "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true",
        "chrome-devtools-mcp-canister:latest"
      ]
    }
  }
}
```

## Claude Code

```bash
claude mcp add chrome-devtools '{"command":"docker","args":["run","--rm","-i","-v","chrome-devtools-mcp-canister-cache:/home/node/.cache","--shm-size","2gb","--env","CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true","--env","CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=true","chrome-devtools-mcp-canister:latest"]}'
```

> Previous versions of this snippet included `-p 127.0.0.1:9222:9222`.
> Don't add it back — see the warning under Pattern A above: it works for
> exactly one concurrent session and silently breaks (`CONNECTION_CLOSED`)
> for every session after the first.

## VS Code (`mcp.json`)

```json
{
  "servers": {
    "chrome-devtools": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--shm-size", "2gb",
        "--env", "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true",
        "chrome-devtools-mcp-canister:latest"
      ]
    }
  }
}
```

## Cursor

Go to **Cursor Settings → MCP → New MCP Server** and paste:

```json
{
  "name": "chrome-devtools",
  "command": "docker",
  "args": [
    "run", "--rm", "-i",
    "--shm-size", "2gb",
    "--env", "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true",
    "chrome-devtools-mcp-canister:latest"
  ]
}
```

## Generic stdio client

Any MCP client that supports stdio transport can launch:

```bash
docker run --rm -i --shm-size 2gb \
  --env CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true \
  chrome-devtools-mcp-canister:latest
```

## Test MCP server
```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}\n{"jsonrpc":"2.0","id":2,"me
  thod":"tools/call","params":{"name":"new_page","arguments":{"url":"https://example.com"}}}\n' \
    | docker run --rm -i -p 9224:9222 \
        -v skills_chrome-cache:/home/node/.cache \
        --env CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true \
        chrome-devtools-mcp-canister:latest \
    2>/dev/null | jq
```

---

## Building the image first

All snippets above assume the image has been built locally.
Run this once (and again after each version bump):

```bash
docker compose build
```

The compose file also tags the versioned image as `:latest` so the
`chrome-devtools-mcp-canister:latest` reference above always resolves correctly.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/mcp` shows `CONNECTION_CLOSED`, second/third session onward | Pattern A config has `-p 127.0.0.1:9222:9222`; each session's container races for that host port and every one after the first dies instantly | Remove `-p ...` from the config (Pattern A doesn't need it), or switch to Pattern B for concurrent sessions |
| `/mcp` shows `CONNECTION_CLOSED`, Pattern B | The shared `chrome-devtools-mcp-canister-chrome` container isn't running | `docker compose up -d`, then reconnect |
| Tool calls fail with `ECONNREFUSED` or `fetch failed` fetching `.../json/version` | Pattern B config uses a bridge network + hostname instead of `--network container:<name>` — Chrome only listens on `127.0.0.1` inside its own container, unreachable any other way | Use `--network container:chrome-devtools-mcp-canister-chrome` as shown above, not `--network <bridge-name>` with a hostname |
| Tool calls fail with `ECONNREFUSED`/`fetch failed` after a `docker compose` recreate | The shared container got a new name (no `container_name` pin, or the pin was removed/changed) | Confirm the running name with `docker compose ps` and match it in every client's `--network container:<name>` |
| Editing `.mcp.json` (or a plugin's) has no effect after reconnecting | If installed as a Claude Code plugin, `claude plugin install` caches a copy under `~/.claude/plugins/cache/...`; editing the source doesn't refresh it | Bump the plugin's `version` in `plugin.json` and the marketplace manifest, then `claude plugin uninstall` → `claude plugin marketplace update` → `claude plugin install` again |
| `http://127.0.0.1:6080/vnc.html` doesn't load / `websockify` is `[defunct]` in `docker compose logs` | `novnc`'s files got removed — `apt-get purge -y --auto-remove curl gnupg dirmngr` in the same apt transaction as installing `novnc` can sweep it away as a false-positive orphan | Already fixed in this Dockerfile: install the VNC stack (`xvfb x11vnc novnc websockify`) in a separate `apt-get install` *after* the purge step, never combined with it |
| `x11vnc` exits immediately with an X authorization / `.Xauthority` error | `Xvfb` started without disabling access control | `Xvfb :99 ... -ac` (already set in `scripts/start-vnc-chrome.sh`) |
| Chrome logs "The profile appears to be in use by another Chromium process" and keeps restarting | A previous container using the same `--user-data-dir` (the `chrome-cache` volume persists across `--force-recreate`) left a stale `Singleton*` lock behind | Already handled: the startup script removes `Singleton*` from the profile dir before launching Chrome, since only one instance ever runs against it |
