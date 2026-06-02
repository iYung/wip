# Web Deploy Checklist

- [x] Task A — `package.json` — create file at repo root pinning `love.js` to latest stable (e.g. `"love.js": "^12.0.0"`); no other deps needed

- [x] Task B — `scripts/build_web.sh` — create executable build script: (1) zip `main.lua conf.lua lua/ assets/` into `game.love` using the `zip` CLI, (2) run `npx love.js game.love web/ --title "plant game" --compatibility`, (3) copy `web-template/controls.js` into `web/controls.js`, (4) inject `<script src="controls.js"></script>` before `</body>` in the generated `web/index.html` using `sed`, (5) exit non-zero on any failure

- [x] Task C — `conf.lua` — add `t.identity = "plantgame"` inside `love.conf(t)` (before the headless block)

- [x] Task D — `.github/workflows/web.yml` — create workflow with four jobs:
  1. **`build`** (trigger: push + PR): checkout, setup Node LTS, `npm install`, run `scripts/build_web.sh`, upload `web/` as artifact `web-build`
  2. **`deploy`** (trigger: push to `main`, needs `build`): download artifact, push to root of `gh-pages` branch via `peaceiris/actions-gh-pages`
  3. **`deploy-pr`** (trigger: PR `opened`/`synchronize`, needs `build`): download artifact, push to `pr-${{ github.event.pull_request.number }}/` on `gh-pages` branch with `keep_files: true`, then use `peter-evans/create-or-update-comment` to post/update a comment on the PR with the preview URL `https://iyung.github.io/wip/pr-<number>/`
  4. **`cleanup-pr`** (trigger: PR `closed`): checkout `gh-pages` branch, `git rm -rf pr-<number>/`, commit and push the deletion

- [x] Task E — `.github/workflows/web.yml` (permissions) — ensure the workflow has `contents: write` and `pull-requests: write` permissions so it can push to `gh-pages` and post PR comments

- [x] Task F — GitHub Pages setup note (manual step, not code) — in the PR description note that a repo admin must go to Settings → Pages → Source → Deploy from branch → `gh-pages` / `/ (root)` once the `gh-pages` branch exists after the first deploy

- [x] Task G — `web-template/controls.js` — standalone JS file injected into love.js's generated page; on DOMContentLoaded it (a) creates and appends a `<div id="game-controls">` with 7 buttons: ← → ↑ ↓ E F Esc, (b) each button fires `keydown` (`{key, code, bubbles:true}`) on `mousedown`/`touchstart` and `keyup` on `mouseup`/`touchend`/`mouseleave`/`touchcancel` targeting the canvas element (`document.getElementById('canvas')`), (c) buttons styled inline: min 60×60px, dark semi-transparent background, white text, rounded, arranged left-cluster (↑ above ←↓→) and right-cluster (E F on top row, Esc below), responsive flex layout
