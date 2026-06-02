# Web Deployment Design

## Goal

Package the LÖVE 11.5 game as a WebAssembly build using `love.js` and auto-deploy to GitHub Pages via GitHub Actions. The live URL will be `https://iyung.github.io/wip/`. Every push to `main` redeploys. Every PR gets a downloadable web build artifact attached to its CI run.

---

## Affected files

| File | Change |
|------|--------|
| `.github/workflows/web.yml` | New workflow: build `.love` file, run `love.js`, deploy to `gh-pages` branch on `main` push, upload artifact on PRs |
| `scripts/build_web.sh` | New script: zips game sources into `game.love`, invokes `love.js` |
| `conf.lua` | Add `t.identity = "plantgame"` (already called out in `save_load.md`; needed for web save isolation too) |
| `package.json` | New file: pins `love.js` npm package version so the build is reproducible |
| `web-template/index.html` | New file: custom HTML wrapper with canvas + on-screen button overlay; copied over love.js's generated `index.html` by the build script |

Nothing in the Lua game code changes. The on-screen controls are purely an HTML/JS overlay injecting browser keyboard events that love.js already listens for.

---

## What changes

### 1. Build script (`scripts/build_web.sh`)

Creates `game.love` (a ZIP of all game files: `main.lua`, `conf.lua`, `lua/`, `assets/`) then runs:

```
npx love.js game.love web/ --title "plant game" --compatibility
```

Output directory `web/` contains `index.html`, the WASM runtime, and the packed game data. This directory is what gets deployed to GitHub Pages.

### 2. GitHub Actions workflow (`.github/workflows/web.yml`)

Two jobs:

**`build` (runs on every push and PR)**
- Checkout repo
- Install Node.js (LTS)
- Run `scripts/build_web.sh`
- Upload `web/` as a GitHub Actions artifact named `web-build`

**`deploy` (runs only on push to `main`, depends on `build`)**
- Downloads the `web-build` artifact
- Pushes its contents to the root of the `gh-pages` branch using `peaceiris/actions-gh-pages`
- GitHub Pages serves that branch at `https://iyung.github.io/wip/`

**`deploy-pr` (runs on PR open/synchronize)**
- Downloads the `web-build` artifact
- Pushes its contents to `pr-<number>/` subdirectory on the `gh-pages` branch (preserves other content with `keep_files: true`)
- Posts a comment on the PR: `🌐 Preview: https://iyung.github.io/wip/pr-<number>/`

**`cleanup-pr` (runs on PR close/merge)**
- Checks out the `gh-pages` branch, deletes the `pr-<number>/` subdirectory, and force-pushes the cleanup

### 3. `package.json`

Pins the `love.js` package version so CI and local builds use the same runtime. No other Node dependencies needed.

### 4. Custom HTML with on-screen controls (`web-template/index.html`)

The build script copies this file over love.js's generated `index.html` after the build, preserving all the generated JS/WASM filenames.

The page contains the `<canvas id="canvas">` love.js renders into, plus a button overlay. Each button fires `keydown` on `mousedown`/`touchstart` and `keyup` on `mouseup`/`touchend`/`mouseleave` so held movement keys work correctly.

**Button layout** (always visible, positioned below the canvas):

```
Left cluster          Right cluster
  [ ↑ ]                [ E ]  [ F ]
  [ ← ][ ↓ ][ → ]      [ Esc ]
```

Key mappings:
| Button | Key dispatched |
|--------|---------------|
| ← | `ArrowLeft` |
| → | `ArrowRight` |
| ↑ | `ArrowUp` |
| ↓ | `ArrowDown` |
| E | `e` |
| F | `f` |
| Esc | `Escape` |

The buttons use large touch targets (min 60×60 px), a semi-transparent dark background, and are styled to work on both mobile and desktop.

love.js hooks `keydown`/`keyup` on the canvas element. The JS dispatches events with `bubbles: true` so they propagate correctly. The input system in Lua polls `love.keyboard.isDown` every frame, so a held `keydown` registers as continuous movement and a tapped `keydown`+`keyup` registers as a single-frame press — matching how the game expects all inputs.

### 5. `conf.lua` — identity

Add `t.identity = "plantgame"`. Required for proper save-file isolation (save/load not implemented yet, but the identity should be set before web deploy because Emscripten's virtual FS uses it as the persistence key).

---

## What stays the same

- All Lua source files and game logic
- All assets
- Existing CI test workflow (`ci.yml`) — runs in parallel, unaffected
- The `--headless` arg detection in `conf.lua` is already safe (`arg or {}` guard)

---

## Open questions

1. **love.js / LÖVE 11.5 compatibility** — love.js bundles its own WASM build of LÖVE. The latest npm release may target 11.4. If the bundled runtime is 11.4 we need to verify there are no 11.5-only APIs in use (likely none — the game uses only stable love2d APIs). This must be confirmed at build time. If incompatible, options are: (a) downgrade CI/tests to 11.4, (b) build love.js from source targeting 11.5, or (c) wait for a love.js 11.5 release. The simplest path is (a).

2. **Audio autoplay** — browsers block audio until the user interacts. love.js inserts a "Click to start" interstitial page that satisfies this requirement. The game's `Sound.load()` already guards with `if not love.audio then return end`, so it degrades cleanly if audio fails. No game code changes needed, but the interstitial UX should be verified manually after first deploy.

3. **Canvas / window size** — the game defaults to 1280×720 with `resizable = true`. On the web, love.js renders into a `<canvas>`. Small screens may clip the canvas. The `index.html` love.js generates includes basic CSS to center and constrain the canvas. This is acceptable for testing; a custom HTML wrapper can be added later for a polished embed.

4. **GitHub Pages base path** — GitHub Pages serves the repo under `/wip/`. love.js-generated builds use relative paths for assets, so this should work without modification. Needs a smoke-test after first deploy.

5. **love.js / LÖVE version** — proceeding on the assumption that 11.4 runtime is acceptable for the web build (no 11.5-specific APIs are used in the game).
