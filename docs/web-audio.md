# Web Audio — Resolved

Audio now works in the web build.

---

## Fix

The build was using `--compatibility` mode (`src/compat/love.js`), which does not use pthreads. The love.js README explicitly states this causes "dodgy audio."

The fix switches to the release build (pthreads) and adds `coi-serviceworker` to inject the `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers via a service worker, which GitHub Pages requires for `SharedArrayBuffer` (used by pthreads).

Changes:
- `scripts/build_web.sh` — removed `--compatibility` flag; copies `coi-serviceworker.js` to `web/` and injects it as the first script in `<head>`
- `package.json` — added `coi-serviceworker ^0.1.7` as a dev dependency

On first visit the page reloads once (the service worker registers and redirects). Subsequent visits load normally with audio working.

---

## History

### What was tried before

**Silent-buffer unlock** — on the first `touchstart`, a 1-sample silent `AudioBufferSourceNode` was created and played in a new `AudioContext`. Standard iOS autoplay unlock technique. Did not fix the issue; reverted.

### Root cause

`--compatibility` (compat build) uses a different Emscripten binary with no web workers. The release build uses pthreads (`love.worker.js`) which requires cross-origin isolation headers. GitHub Pages does not serve these headers natively, hence the `coi-serviceworker` workaround.
