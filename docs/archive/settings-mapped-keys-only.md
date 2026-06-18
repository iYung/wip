## Settings Mapped-Keys-Only Checklist

- [x] Task A — `lua/game/scenes/settings_menu.lua` — Remove all hardcoded key fallbacks so only mapped keys fire in the settings menu. Four sites need the same cleanup:

  1. `open()` (lines ~95–100): snapshot block — remove `or love.keyboard.isDown("return") or love.keyboard.isDown("space")` from the confirm snapshot; remove `love.keyboard.isDown("up") or` / `love.keyboard.isDown("down") or` etc. prefixes from nav snapshots, leaving only `love.keyboard.isDown(kb.move_up or "w")` etc.
  2. `update()` main-menu block (lines ~164–169): same removals.
  3. `update()` keybinds sub-screen block (lines ~125–129): same removals.
  4. `_confirm()` snapshot when entering keybinds sub-screen (lines ~231–235): same removals for the confirm snapshot.

  After the fix each variable should look like:
  ```lua
  local up      = love.keyboard.isDown(kb.move_up    or "w")
  local down    = love.keyboard.isDown(kb.move_down  or "s")
  local left    = love.keyboard.isDown(kb.move_left  or "a")
  local right   = love.keyboard.isDown(kb.move_right or "d")
  local confirm = love.keyboard.isDown(kb.interact   or "space")
  ```
  Keep `escape` unchanged. Keep the nil-guard defaults (`or "w"`, `or "space"`, etc.).

- [x] Task B — `tests/test_settings_menu.lua` — Update existing tests that used hardcoded arrow keys or Return for nav/confirm, and add new tests that verify the fix. **Depends on Task A being done first.**

  Changes to existing tests: replace every `sim_key(m, "down")` used for navigation with `sim_key(m, "s")`, `sim_key(m, "up")` with `sim_key(m, "w")`, `sim_key(m, "left")` with `sim_key(m, "a")`, `sim_key(m, "right")` with `sim_key(m, "d")`. Test 18's direct `love.keyboard.isDown = function(k) return k == "down"` stub must also change to `"s"`.

  New tests to add (after the existing tests, before the `love.event.quit` restore):
  - Arrow keys do NOT navigate in main menu: `sim_key(m, "down")` / `sim_key(m, "up")` / `sim_key(m, "left")` / `sim_key(m, "right")` should leave `m.selected` unchanged.
  - Arrow keys do NOT navigate in keybinds sub-screen: `sim_key(m, "down")` / `sim_key(m, "up")` in sub-screen should leave `m._subscreen_selected` unchanged.
  - Return key does NOT confirm: `sim_key(m, "return")` on row 1 should NOT toggle fullscreen.
  - Unmapped spacebar does NOT confirm when interact is rebound: bind interact to "x", then `sim_key(m, "space")` should not confirm.
