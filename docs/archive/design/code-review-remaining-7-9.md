# Design: Code Review Items 7–9

## Goal

Address the three remaining items from the code review checklist:

1. **`main.lua:127`** — cache `require("lua/headless/runner")` as a module-level local instead of calling it inside `love.draw()` every frame.
2. **`start_scene.lua:38-40`** — replace hardcoded `love.keyboard.isDown` calls with the passed-in `input` object so menu navigation respects remapped keybinds.
3. **`store_scene.lua:226`** — replace magic number `640` (half of the logical width) with a named constant.

---

## Affected files

| File | Item |
|---|---|
| `main.lua` | 1 — cache runner require |
| `lua/game/input.lua` | 2 — add `move_up`, `move_down`, `menu_confirm` actions |
| `lua/game/scenes/start_scene.lua` | 2 — use input object; remove manual edge-detection state |
| `lua/game/config.lua` | 3 — add `LOGICAL_W = 1280` |
| `lua/game/scenes/store_scene.lua` | 3 — use `Config.LOGICAL_W / 2` |

---

## What changes

### Item 1 — `main.lua`: cache runner require

Currently, `love.draw()` calls `require("lua/headless/runner")` on every frame:

```lua
-- love.draw() today
local sm = _visual_mode and require("lua/headless/runner")._active_sm or scene_manager
```

Although Lua's `require` caches modules, calling it every frame is a code smell — it hides the dependency and makes the function harder to read.

**Fix:** Add a module-level local `_runner` immediately after the `do ... end` block that sets `_visual_mode`:

```lua
local _runner = _visual_mode and require("lua/headless/runner") or nil
```

Then `love.draw()` becomes:

```lua
local sm = _visual_mode and _runner._active_sm or scene_manager
```

- In headless mode, `return` fires before this line is reached, so no change there.
- In visual mode, `_visual_mode = true`, so `_runner = require("lua/headless/runner")`.
- In normal mode, `_visual_mode = false`, so the `and` short-circuits and `_runner = nil`.
- The `love.load()` already has its own `local runner = require(...)` (called once); that stays unchanged.

---

### Item 2 — `lua/game/input.lua` + `start_scene.lua`: use input object

**Problem:** `StartScene:update()` calls `love.keyboard.isDown` directly, so it ignores user-remapped keybinds.

**Fix in `lua/game/input.lua`:** Add the three missing actions. `move_up`/`move_down` align with the existing `settings_state` remappable keybind names; `menu_confirm` covers the non-remappable confirm keys:

```lua
return Input.new({
    move_up      = {"up", "w"},
    move_down    = {"down", "s"},
    move_left    = {"left", "a"},
    move_right   = {"right", "d"},
    pick_up_down = {"e"},
    interact     = {"f"},
    menu_confirm = {"return", "space", "f"},
})
```

**Fix in `start_scene.lua`:**

- Replace the three `love.keyboard.isDown` lines with `self.input:pressed(...)` calls.
- `input:pressed()` already implements edge detection (true only the first frame the key is held), so remove `_prev_up`, `_prev_down`, `_prev_confirm` from `new()` and the `update()` body entirely.

Before:
```lua
function StartScene:update(dt)
    local up      = love.keyboard.isDown("up")    or love.keyboard.isDown("w")
    local down    = love.keyboard.isDown("down")  or love.keyboard.isDown("s")
    local confirm = love.keyboard.isDown("return") or love.keyboard.isDown("space") or love.keyboard.isDown("f")

    if up and not self._prev_up then ...
    if down and not self._prev_down then ...
    if confirm and not self._prev_confirm then ...

    self._prev_up      = up
    self._prev_down    = down
    self._prev_confirm = confirm
end
```

After:
```lua
function StartScene:update(dt)
    if self.input:pressed("move_up") then ...
    if self.input:pressed("move_down") then ...
    if self.input:pressed("menu_confirm") then ...
end
```

---

### Item 3 — `config.lua` + `store_scene.lua`: named constant for logical width

`store_scene.lua:229` has `local half_w = 640`. The value `640` is half the logical resolution (1280×720) — that value is already declared as `local LOGICAL_W, LOGICAL_H = 1280, 720` inside `main.lua`, but inaccessible to other modules.

**Fix in `lua/game/config.lua`:** Add:

```lua
LOGICAL_W = 1280,
```

**Fix in `store_scene.lua`:** At the top, ensure `Config` is already required (it is). Change:

```lua
local half_w = 640
```

to:

```lua
local half_w = Config.LOGICAL_W / 2
```

---

## What stays the same

- All gameplay behaviour — no logic changes, only code quality.
- `settings_menu.lua` continues to use its own hardcoded keyboard checks (updating it is out of scope for this checklist).
- The keybind-remapping system is unaffected; adding `move_up`/`move_down`/`menu_confirm` to `input.lua` does not interfere with the settings-menu rebuild of `input._map` (those three actions will simply retain their defaults if not remapped, which is correct).
- All existing tests remain valid.

---

## Open questions

None.
