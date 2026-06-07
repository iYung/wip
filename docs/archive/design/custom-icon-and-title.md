## Goal

Replace the default LÖVE heart icon and generic title with Frobert's own icon and name so the taskbar and window chrome reflect the game's identity.

## Affected files

- `conf.lua` — window title
- `main.lua` — icon loading at startup
- `assets/images/icon.png` — new icon file (supplied by user; square PNG, ≥32×32)

## What changes

1. **Window title** — `conf.lua` line 13: change `t.window.title = "plant game"` → `t.window.title = "Frobert"`.

2. **Window icon** — call `love.window.setIcon()` early in `love.load()` (before the visual-mode branch) so both normal and visual-test runs show the correct icon:

   ```lua
   local icon = love.image.newImageData("assets/images/icon.png")
   love.window.setIcon(icon)
   ```

   The icon file must be placed at `assets/images/icon.png` (square PNG, recommended 64×64 or 128×128).

## What stays the same

- Headless mode is unaffected — `love.load()` is never defined in that path, so no window calls are made.
- All other window settings (`width`, `height`, `resizable`) remain unchanged.
- No new modules or dependencies are introduced.

## Open questions

_(none — user will supply `assets/images/icon.png` before or alongside the implementation)_
