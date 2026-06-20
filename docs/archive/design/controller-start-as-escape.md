# Controller Start Button as Full Escape Equivalent

## Goal

Make the Start button behave like Escape at every level of the UI — not just the top level of the settings menu. Currently pressing Start inside the keybinds sub-screen or during a key-capture closes the entire menu instead of backing out one level.

## Affected files

- `main.lua` — `love.gamepadpressed` hook
- `lua/game/scenes/settings_menu.lua` — add `gamepadpressed(button)` method; fix sub-screen escape polling

## What changes

### 1. Add `SettingsMenu:gamepadpressed(button)`

Mirror the existing `SettingsMenu:keypressed(key)` method for gamepad events. Mirrors `keypressed` exactly — handles context-aware back:

| State | Start behaviour |
|---|---|
| `_capturing ~= nil` | Cancel capture (`_capturing = nil`), return `true` |
| `_subscreen == "keybinds"` | Exit sub-screen if all bound (same guard as keyboard), return `true` |
| Main menu open | Close the menu (`self:close()`), return `true` |

### 2. Update `love.gamepadpressed` in `main.lua`

Before the existing `button == "start"` branch, delegate to the menu when it is open — same pattern as `love.keypressed` already does for `keypressed(key)`:

```lua
if settings_menu and settings_menu.is_open then
    if settings_menu:gamepadpressed(button) then return end
end
```

Remove the direct `settings_menu:close()` call from the `button == "start"` branch — the new `gamepadpressed()` method handles that path now.

### 3. Add Start to the sub-screen polling escape in `settings_menu.lua`

Inside the `_subscreen == "keybinds"` block in `update()`, merge Start into `escape` the same way the main-menu level already does:

```lua
local escape = love.keyboard.isDown("escape")
    or (self._input._joystick ~= nil
        and self._input._joystick:isConnected()
        and self._input._joystick:isGamepadDown("start"))
```

This keeps the poll path consistent; the event path (fix 2) is the primary trigger.

## What stays the same

- On the start screen (StartScene), pressing Start quits — same as keyboard Escape; this is consistent and intentional
- Opening settings with Start when the menu is closed — unchanged
- All keyboard Escape handling — untouched
- The `_all_bound` guard when exiting the keybinds sub-screen — preserved
- `cancel` action (`[B]`) in store/buy scenes — not involved

## Open questions

None.
