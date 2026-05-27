## Code Review Items 7–9 Checklist

- [x] Task A — `main.lua` — add `local _runner = _visual_mode and require("lua/headless/runner") or nil` at module level (after the `do ... end` block that sets `_visual_mode`); in `love.draw()` replace `require("lua/headless/runner")._active_sm` with `_runner._active_sm`

- [x] Task B — `lua/game/input.lua` — add `move_up = {"up", "w"}`, `move_down = {"down", "s"}`, and `menu_confirm = {"return", "space", "f"}` to the `Input.new({...})` call

- [x] Task C — `lua/game/scenes/start_scene.lua` — remove `_prev_up`, `_prev_down`, `_prev_confirm` from `new()`; rewrite `update()` to use `self.input:pressed("move_up")`, `self.input:pressed("move_down")`, `self.input:pressed("menu_confirm")` instead of the hardcoded `love.keyboard.isDown` calls and manual prev-state tracking

- [x] Task D — `lua/game/config.lua` — add `LOGICAL_W = 1280` to the returned table

- [x] Task E — `lua/game/scenes/store_scene.lua` — add `local Config = require("lua/game/config")` at the top if not already present; replace `local half_w = 640` with `local half_w = Config.LOGICAL_W / 2`
