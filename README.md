# chrome-devtools-mcp-canister

Container packaging for the [`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp)
npm package — run the Chrome DevTools MCP server in a container without a local Node.js install.

> **Not affiliated with Google LLC.**  
> "Chrome", "Chromium", and "Chrome DevTools" are trademarks of Google LLC.  
> This project provides container infrastructure *compatible with* the
> `chrome-devtools-mcp`™ npm package.  
> See [NOTICE](./NOTICE) for full trademark and attribution details.

---

## What this repo is (and isn't)

| In scope | Out of scope |
|---|---|
| `Containerfile` / `Dockerfile` and compose file | The MCP server source code — lives at [ChromeDevTools/chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) |
| Renovate config for automated version PRs | Publishing a pre-built image to a registry |
| GitHub Actions CI (build → smoke → browser probe) | Multi-platform CI (tested on macOS Apple Silicon only) |

---

## Prerequisites

| Tool | Minimum version |
|---|---|
| Container engine (e.g. Docker Engine, Podman) | Docker 24.x / Podman 4.x |
| Compose plugin | `docker compose` v2.x or `podman-compose` |

No Node.js required on the host.

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/IgnitedLabs/chrome-devtools-mcp-canister.git
cd chrome-devtools-mcp-canister

# 2. Build the image
docker compose build
```

The MCP server itself listens on `stdin/stdout` (stdio transport) and is
launched per-client — see **[docs/mcp-client-config.md](./docs/mcp-client-config.md)**
for the two supported patterns (isolated per-client browser vs. one shared
persistent browser for concurrent sessions). Only the shared pattern needs
`docker compose up -d`.

The shared pattern also exposes a noVNC viewer (`http://127.0.0.1:6080`) so
a human can log in to a gated site directly in the real browser window —
credentials never pass through an MCP client. See "Logging in to a gated
site" in [docs/mcp-client-config.md](./docs/mcp-client-config.md).

---

## MCP client configuration

See **[docs/mcp-client-config.md](./docs/mcp-client-config.md)** for
ready-to-paste snippets for Claude Desktop, Claude Code, VS Code, Cursor,
and other clients.

---

## Documentation

| Document | Description |
|---|---|
| [docs/mcp-client-config.md](./docs/mcp-client-config.md) | MCP client configuration snippets |
| [docs/versioning.md](./docs/versioning.md) | How the package version is pinned and updated by Renovate |
| [docs/limitations.md](./docs/limitations.md) | Known constraints: image size, platform coverage, Chromium vs Chrome |

---

## Trademark notices

"Chrome", "Chromium", and "Chrome DevTools" are trademarks of Google LLC.  
"Node.js" is a trademark of the OpenJS Foundation.  
"Debian" is a registered trademark of Software in the Public Interest, Inc.

This project is **not affiliated with, endorsed by, or sponsored by Google LLC**.
See [NOTICE](./NOTICE) for complete third-party attribution.

---

## License

Copyright [2026] [IgnitedProteus]

Licensed under the [Apache License, Version 2.0](./LICENSE).

The `chrome-devtools-mcp` npm package is copyright Google LLC,
also licensed under the Apache License, Version 2.0.
