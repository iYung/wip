## Code Review Remaining Checklist

- [x] Task 1 — `lua/game/scenes/buy_scene.lua` — On line 304, rename `local y = 652` to `local hint_y = 652`; update the two references to `y` inside the hints loop body (line 306 `56, y` → `56, hint_y` and line 307 `y = y - 20` → `hint_y = hint_y - 20`) to eliminate shadowing of the outer `local y` declared at line 225.

- [x] Task 2 — `lua/game/scenes/settings_menu.lua` — Remove the six class-level field declarations on lines 22–27 (`SettingsMenu.is_open`, `SettingsMenu.selected`, `SettingsMenu._prev_up`, `SettingsMenu._prev_down`, `SettingsMenu._prev_confirm`, `SettingsMenu._prev_escape`) and add them as per-instance assignments inside `new()` after the `setmetatable` call: `self.is_open = false`, `self.selected = 1`, `self._prev_up = false`, `self._prev_down = false`, `self._prev_confirm = false`, `self._prev_escape = false`.

- [x] Task 3 — `lua/game/scenes/store_scene.lua` — Add `local A = require("lua/game/assets")` at the top of the file after the existing requires (after line 13); remove the two per-function `local A = require("lua/game/assets")` declarations at lines 85 and 411 since the module-level local will be in scope.
