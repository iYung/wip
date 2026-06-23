## Goal

Hide the OS mouse cursor for the entire game. The game is fully keyboard/gamepad-driven and never uses mouse input, so the cursor is visual noise that should not appear at any point during play.

## Affected files

- `main.lua` — one call to `love.mouse.setVisible(false)` added in `love.load()`
- `lua/headless/stubs.lua` — add a `love.mouse` stub so tests (which run without a window) don't error if any code path ever calls into `love.mouse`

## What changes

**`main.lua`**

Add `love.mouse.setVisible(false)` near the top of `love.load()`, immediately after the existing `love.graphics.setDefaultFilter("nearest", "nearest")` line. This runs once at startup and hides the cursor for the lifetime of the process across all scenes (StartScene, StoreScene, BuyScene, SettingsMenu).

No per-scene or conditional logic is needed — the call is unconditional and global.

**`lua/headless/stubs.lua`**

Add a `love.mouse` stub entry alongside the existing `love.window` and `love.keyboard` stubs:

```lua
love.mouse = love.mouse or {}
love.mouse.setVisible = function() end
```

This prevents a nil-index error if the `love.mouse` global is absent in the headless environment.

## What stays the same

- No settings toggle — cursor hiding is always-on, not user-configurable
- No changes to `SettingsState`, `Save`, or any scene files
- Web build is out of scope; `love.mouse.setVisible` on web is a no-op concern for later
- All existing tests continue to pass; the headless stub absorbs the call silently

## Open questions

None.
