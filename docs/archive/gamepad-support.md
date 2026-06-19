## Gamepad Support Checklist

- [x] Task 1 — `lua/headless/stubs.lua` — Add `love.joystick` stub so headless tests don't crash when `Input:update()` polls joystick state. Append the following after the `love.audio.play = noop` line (before the `package.loaded` reset at the bottom):
  ```lua
  love.joystick = love.joystick or {}
  love.joystick.getJoysticks = function() return {} end
  ```
  This unblocks all subsequent tasks that touch `Input:update()`.

- [x] Task 2 — `lua/core/input.lua` — Extend `Input` with gamepad mode tracking and polling. Specific changes:
  1. In `Input.new()`, add two new fields after `self._pressed = {}`:
     ```lua
     self._mode     = "keyboard"   -- "keyboard" | "gamepad"
     self._joystick = nil          -- active Love2D joystick object or nil
     ```
  2. Replace the body of `Input:update()` with an extended version that (a) runs the existing keyboard loop unchanged, then (b) if `self._joystick` is set and `self._joystick:isConnected()` is true, polls axes and buttons for the five actions and ORs results into `_down` and `_pressed`. The fixed gamepad→action mapping is:
     - `move_up`: `self._joystick:getAxis(2) < -0.3` (left stick Y up) OR `self._joystick:isGamepadDown("dpup")`
     - `move_down`: `self._joystick:getAxis(2) > 0.3` OR `self._joystick:isGamepadDown("dpdown")`
     - `move_left`: `self._joystick:getAxis(1) < -0.3` (left stick X) OR `self._joystick:isGamepadDown("dpleft")`
     - `move_right`: `self._joystick:getAxis(1) > 0.3` OR `self._joystick:isGamepadDown("dpright")`
     - `interact`: `self._joystick:isGamepadDown("a")`
     For each action, if the gamepad is `down` and the keyboard loop already wrote `_down[action] = true`, keep it true (OR semantics). Only set `_pressed[action] = true` if the combined `down` is true and `self._down[action]` was false before this frame (use a `prev_down` local captured before overwriting).
  3. Replace `Input:key_for(action)` so that when `self._mode == "gamepad"` it returns a gamepad label from a module-local table instead of reading `_map`. The label table:
     ```lua
     local _PAD_LABELS = {
         move_up    = "↑",
         move_down  = "↓",
         move_left  = "←",
         move_right = "→",
         interact   = "[A]",
     }
     ```
     When `self._mode == "keyboard"` the existing behaviour (`return keys and keys[1]`) is unchanged.

- [x] Task 3 — `main.lua` — Add three new Love2D callback functions and amend the existing `love.keypressed`. All changes are in the non-`_visual_mode` path (guard with `if not _visual_mode then … end` or rely on the fact that the callbacks simply won't fire in visual/headless mode). Add after `love.keypressed`:
  1. `love.gamepadpressed(joystick, button)` — set `input._joystick = joystick` and `input._mode = "gamepad"`. If `button == "start"`, apply the same ESC toggle logic that already exists in `love.keypressed`: if `settings_menu` exists and `scene_manager.current.esc_opens_settings` is true, toggle `settings_menu` open/closed; otherwise if settings isn't open, quit.
  2. `love.joystickadded(joystick)` — if `joystick:isGamepad()` and `input._joystick == nil`, set `input._joystick = joystick`.
  3. `love.joystickremoved(joystick)` — if `joystick == input._joystick`, clear `input._joystick = nil` then scan `love.joystick.getJoysticks()` for another connected gamepad and assign it if found.
  4. In the existing `love.keypressed(key)` function, add `input._mode = "keyboard"` as the very first line of the function body (before the `settings_menu` check), so any keyboard press switches mode back.

- [x] Task 4 — `lua/game/scenes/settings_menu.lua` — Add gamepad navigation support. Specific changes:
  1. Add a module-local helper function `_joy_nav(input)` near the top of the file (after the module-local constants). It reads `input._joystick`; if nil or not connected it returns all-false. Otherwise it returns a table `{up, down, left, right, confirm, back}` where:
     - `up` / `down` / `left` / `right`: left-stick axes (threshold ±0.3) OR the corresponding D-pad buttons (`dpup`, `dpdown`, `dpleft`, `dpright`)
     - `confirm`: `isGamepadDown("a")`
     - `back`: `isGamepadDown("b")` — used to close subscreens and the menu itself
  2. In `SettingsMenu:open()`, after the existing keyboard snapshot lines, add a gamepad snapshot block that calls `_joy_nav(self._input)` and stores results into `self._prev_up`, `self._prev_down`, `self._prev_left`, `self._prev_right`, `self._prev_confirm`, and a new `self._prev_back` field (also initialise `self._prev_back = false` in `SettingsMenu.new()`). OR the joystick booleans into the existing keyboard booleans so that a held gamepad input at open-time is also suppressed:
     ```lua
     local jn = _joy_nav(self._input)
     self._prev_up      = self._prev_up      or jn.up
     self._prev_down    = self._prev_down    or jn.down
     self._prev_left    = self._prev_left    or jn.left
     self._prev_right   = self._prev_right   or jn.right
     self._prev_confirm = self._prev_confirm or jn.confirm
     self._prev_back    = jn.back
     ```
  3. In the main-menu block of `SettingsMenu:update()` (the block starting at `local kb = self._state.keybinds`), after the keyboard `up`/`down`/`left`/`right`/`confirm`/`escape` locals are computed, call `_joy_nav` and OR the gamepad values in:
     ```lua
     local jn = _joy_nav(self._input)
     up      = up      or jn.up
     down    = down    or jn.down
     left    = left    or jn.left
     right   = right   or jn.right
     confirm = confirm or jn.confirm
     escape  = escape  or jn.back or (self._input._joystick ~= nil and self._input._joystick:isConnected() and self._input._joystick:isGamepadDown("start"))
     ```
     Also update `self._prev_back` at the end of that block alongside the other `self._prev_*` assignments: `self._prev_back = jn.back`.
  4. In the `keybinds` subscreen block of `SettingsMenu:update()`, after the keyboard `up`/`down`/`confirm`/`escape` locals, similarly OR in joystick navigation and store `_prev_sub_back`. B button should act as escape for the subscreen (cancelling the keybind subscreen when all actions are bound). If `_capturing ~= nil`, B button should clear `self._capturing` (cancel the key-capture prompt). Add `self._prev_sub_back = false` in `SettingsMenu.new()` and snapshot it in `SettingsMenu:_confirm()` when opening the keybinds subscreen.
  5. Also snapshot `self._prev_back` in `SettingsMenu:_confirm()` (when `self.selected == 4` opens keybinds) the same way the other `_prev_sub_*` fields are snapshotted there.

- [x] Task 5 — `lua/game/scenes/start_scene.lua` — Fix key-hint display (lines 166–179) to call `self.input:key_for(action)` instead of reading `self.input._map` directly. Replace the five lines that read from `m` with:
  ```lua
  local ku = self.input:key_for("move_up")    or "?"
  local kl = self.input:key_for("move_left")  or "?"
  local kd = self.input:key_for("move_down")  or "?"
  local kr = self.input:key_for("move_right") or "?"
  local kb_text = ku .. "/" .. kl .. "/" .. kd .. "/" .. kr
  ```
  Remove the `string.upper()` call wrapping `kb_text` (gamepad arrow symbols like `↑` do not have uppercase equivalents and `string.upper` on them is a no-op in Lua, but dropping it is cleaner and avoids any ambiguity). For the interact hint on line 177, replace:
  ```lua
  local ki = string.upper(m.interact and m.interact[1] or "?")
  ```
  with:
  ```lua
  local ki = self.input:key_for("interact") or "?"
  ```
  Also remove the `local m = self.input._map` line (line 166) since it is no longer needed.

---

**Ordering notes:**
- Task 1 (stubs) must be completed before running any tests that exercise the updated `Input:update()` — complete it first.
- Tasks 2, 3, 4, and 5 are independent of each other and can run in parallel once Task 1 is done.
- Task 3 depends on the `_mode` and `_joystick` fields added in Task 2 (both tasks touch different files, but Task 3 sets `input._mode` and `input._joystick` which are defined in Task 2). Complete Task 2 before or alongside Task 3, ensuring the fields exist before the callbacks reference them.
