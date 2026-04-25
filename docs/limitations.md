# Known limitations

## Image size (~600 MB)

| Component | Approx. size |
|---|---|
| Chromium (Debian apt) | ~150 MB |
| Node.js 22 | ~200 MB |
| chrome-devtools-mcp npm deps | ~200 MB |
| debian:bookworm-slim base | ~50 MB |

All four components are **runtime dependencies** — none can be eliminated.

---

## Platform coverage

| Environment | Status |
|---|---|
| macOS (Apple Silicon) + Docker Desktop — `linux/arm64` native | ✅ Tested |
| CI (GitHub Actions `ubuntu-latest`, x86_64 + QEMU arm64 emulation) | ✅ Tested in CI |
| Linux hosts (x86_64 or arm64) | ⚠️ Untested |
| Windows + Docker Desktop | ⚠️ Untested |
| Other Debian base versions | ❌ Not supported (see [versioning.md](./versioning.md)) |

---

## Chromium vs Google Chrome

The container runs the **Debian-packaged Chromium** binary (`/usr/bin/chromium`),
not Google Chrome.

The upstream `chrome-devtools-mcp` package
[officially supports Google Chrome and Chrome for Testing only](https://github.com/ChromeDevTools/chrome-devtools-mcp).
Other Chromium-based browsers may work but are not guaranteed.

Practical implications:

- Some Chrome-specific DevTools features or APIs may behave differently or
  be absent in Chromium.
- Version skew between Chromium (apt) and Chrome for Testing is possible.
- Use at your own discretion for production automation.

---

## Chromium and Node.js are not tracked by Renovate

Renovate only watches the `chrome-devtools-mcp` npm package. Chromium and
Node.js are installed via apt / NodeSource and only update on a manual
`--no-cache` rebuild. See [versioning.md](./versioning.md) for details.

---

## No pre-built registry image

The image is built locally only — no image is pushed to a container registry.
