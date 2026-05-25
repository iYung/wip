## Goal

Create a `SettingsState` class that backs the existing `SettingsMenu` UI, mirroring the `GameState` pattern. `SettingsMenu` becomes a pure view layer; all setting mutations go through `SettingsState`, which owns calling the Love2D APIs. No filesystem I/O is added yet — `SettingsState` lives in memory only, ready to be saved/loaded in a future pass.

---

## Affected files

| File | Change |
|------|--------|
| `lua/game/settings_state.lua` | **New** — data class holding `fullscreen` bool + `toggle_fullscreen()` |
| `lua/game/scenes/settings_menu.lua` | Accepts `SettingsState` in `new()`; delegates fullscreen logic to it |
| `main.lua` | Constructs `SettingsState`, passes it to `SettingsMenu.new()` |

---

## What changes

### `lua/game/settings_state.lua` (new file)

Same Lua class pattern as `GameState`:

```lua
local SettingsState = {}
SettingsState.__index = SettingsState

function SettingsState.new()
    local self = setmetatable({}, SettingsState)
    self.fullscreen = false
    return self
end

function SettingsState:toggle_fullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setFullscreen(self.fullscreen)
end

return SettingsState
```

### `lua/game/scenes/settings_menu.lua`

- `SettingsMenu.new(settings_state)` stores `self._state = settings_state`
- `_confirm()` option 1: replace `love.window.setFullscreen(not love.window.getFullscreen())` with `self._state:toggle_fullscreen()`
- `draw()` label for option 1: replace `love.window.getFullscreen()` with `self._state.fullscreen`

### `main.lua`

```lua
local SettingsState = require("lua/game/settings_state")

-- in love.load():
local ss = SettingsState.new()
settings_menu = SettingsMenu.new(ss)
```

---

## What stays the same

- No filesystem reads or writes — `SettingsState` is memory-only for now
- `SettingsMenu` UI layout, key handling, and open/close behavior are unchanged
- Only one setting today: fullscreen
- `GameState` is not touched
- `SettingsMenu` is still a singleton created once in `love.load()` and shared across all scenes

---

## Open questions

None — all resolved before writing this doc.
