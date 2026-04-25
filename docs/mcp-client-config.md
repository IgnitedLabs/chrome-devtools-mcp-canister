# MCP client configuration

The container image exposes the MCP server over **stdio** (stdin/stdout).
Every client below launches the container as a subprocess — no separate
`compose up` step is needed for day-to-day use.

> **Note:** `--shm-size 2gb` is required. Chromium's renderer processes use
> shared memory heavily and will crash with the default 64 MB limit.

---

## Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`
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
        "chrome-devtools-mcp:latest"
      ]
    }
  }
}
```

## Claude Code

```bash
claude mcp add chrome-devtools \
  docker run --rm -i --shm-size 2gb \
  --env CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true \
  chrome-devtools-mcp:latest
```

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
        "chrome-devtools-mcp:latest"
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
    "chrome-devtools-mcp:latest"
  ]
}
```

## Generic stdio client

Any MCP client that supports stdio transport can launch:

```bash
docker run --rm -i --shm-size 2gb \
  --env CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=true \
  chrome-devtools-mcp:latest
```

---

## Building the image first

All snippets above assume the image has been built locally.
Run this once (and again after each version bump):

```bash
docker compose build
```

The compose file also tags the versioned image as `:latest` so the
`chrome-devtools-mcp:latest` reference above always resolves correctly.
