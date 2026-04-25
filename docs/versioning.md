# Versioning

## How the package version is pinned

The `chrome-devtools-mcp` npm package version is pinned in **three places**,
all kept in sync by Renovate:

```
Containerfile / Dockerfile
    ARG CHROME_DEVTOOLS_MCP_VERSION=0.23.0

docker-compose.yaml
    image: chrome-devtools-mcp:v0.23.0
    - CHROME_DEVTOOLS_MCP_VERSION=0.23.0
```

The `image:` tag drives the local tag name produced by `compose build`.
The `ARG` drives the `npm install -g` step inside the build.
Both must match — Renovate updates all three in the same PR commit.

## Automated update flow

```
npm publishes chrome-devtools-mcp@X.Y.Z
         │
         ▼
  Renovate opens PR
  (updates all three version references atomically)
         │
         ▼
  CI: build → smoke → browser-probe
         │
    all green?
    ┌────┴────┐
   yes        no
    │          └── PR stays open for manual review
    ▼
  auto-merge (squash)
  branch deleted automatically
```

## What Renovate does NOT update

**`debian:bookworm-slim`** — the base image is pinned to Debian Bookworm and
excluded from Renovate via `ignoreDeps: ["debian"]` in `.github/renovate.json`.

Reasons:
- Bookworm LTS support runs until 2029; there is no urgency.
- A base image bump can silently break the NodeSource setup script or the
  `chromium` apt package (package name, shared library versions, or ABI).
- Any base image upgrade must be tested manually before merging.

**Chromium** and **Node.js** — these are installed via apt and NodeSource
inside the container build. They are not tracked by Renovate. They update only
when a new container image is built from scratch (e.g. `--no-cache`).

## Manually bumping the base image

When a Debian base image update is needed:

1. Edit `Containerfile` / `Dockerfile`: change `FROM debian:bookworm-slim` to
   the new tag.
2. Build with `--no-cache` and verify:
   - NodeSource `setup_22.x` installs cleanly.
   - `chromium` package is available and the binary runs.
   - All three CI jobs pass.
3. Open a PR with the label `base-image` and merge manually after review.
