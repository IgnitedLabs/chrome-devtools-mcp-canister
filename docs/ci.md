# CI pipeline

Defined in `.github/workflows/ci.yml`.  
Triggered on every pull request targeting `main`.

## Overview

Three jobs run in sequence. All three must pass before a PR can merge
(enforced by branch protection — see [branch-protection.md](./branch-protection.md)).

```
PR opened / pushed
       │
       ▼
   [ build ]  ~5 min
       │
       ▼
   [ smoke ]  ~30 sec
       │
       ▼
[ browser-probe ]  ~60 sec
       │
  (Renovate PR only)
       ▼
  [ auto-merge ]
```

---

## Job 1 — build

Validates the container build end-to-end:

- NodeSource `setup_22.x` script still runs cleanly on Debian Bookworm.
- `chromium` apt package is available and installs.
- `npm install -g chrome-devtools-mcp@<version>` succeeds.

The built image is exported as a gzipped tar artifact and shared with
subsequent jobs — no rebuilding in later jobs.

**QEMU note:** GitHub Actions runners are `x86_64`. The compose file targets
`linux/arm64`. `docker/setup-qemu-action` is used to enable arm64 emulation
before the build step.

## Job 2 — smoke

Sends an MCP `initialize` request over stdio and asserts a valid JSON-RPC 2.0
`result` is returned. Confirms:

- The Node.js runtime inside the container is healthy.
- The `chrome-devtools-mcp` package starts without errors.
- The MCP protocol handshake works.

Timeout: 2 minutes.

## Job 3 — browser-probe

Sends `notifications/initialized`, then calls `tools/list` to discover
available tool names at runtime (guards against upstream API renames).
Then exercises:

1. A page-creation tool (`new_tab`, `new_page`, or `navigate` — whichever
   is present in the tools list).
2. A `navigate` call to `https://example.com` (if the tool exists separately).

Confirms Chromium actually launches inside the container and can navigate.

Timeout: 3 minutes.

## Auto-merge job

Runs only when `github.actor == 'renovate[bot]'` and all three jobs have
passed. Calls `gh pr merge --auto --squash`. Branch protection is the actual
gate — this job just enqueues the merge.

Requires the repository's **workflow token permissions** to be set to `write`
for pull requests. See [branch-protection.md](./branch-protection.md) for the
`gh` CLI command that configures this.

## Concurrency

Only one CI run per PR branch runs at a time. A new push to the same branch
cancels the in-progress run:

```yaml
concurrency:
  group: ci-${{ github.head_ref }}
  cancel-in-progress: true
```
