## Goal

Prevent the player from binding a key that is already bound to a different action. When they try, shake and flash red the row that already owns that key — and stay in capture mode so they can pick a different key.

## Affected files

- `lua/game/settings_state.lua` — remove collision-clearing loop from `set_keybind`
- `lua/game/scenes/settings_menu.lua` — detect taken key in `keypressed`, trigger shake/flash, keep capturing
- `tests/test_settings_state.lua` — update Test 6 (collision clearing no longer happens)

## What changes

### `settings_state.lua` — `set_keybind`

Remove the loop that clears the other action when a key collision is detected. The loop is now dead code because the menu layer rejects the attempt before calling `set_keybind`.

```lua
-- Before
function SettingsState:set_keybind(action, key)
    for other_action, bound_key in pairs(self.keybinds) do
        if other_action ~= action and bound_key == key then
            self.keybinds[other_action] = nil
        end
    end
    self.keybinds[action] = key
end

-- After
function SettingsState:set_keybind(action, key)
    self.keybinds[action] = key
end
```

### `settings_menu.lua` — new shake/flash state

Add two fields to `SettingsMenu.new()`:
- `self._shake_row` — index into `_ACTION_LIST` of the conflicting row (nil when idle)
- `self._shake_timer` — countdown from `0.5` to `0`; drives both offset amplitude and red tint

### `settings_menu.lua` — `keypressed` (capture path)

When `self._capturing ~= nil` and a non-modifier key is pressed:

1. Check whether the key is already bound to a **different** action:
   ```
   for i, action in ipairs(_ACTION_LIST) do
       if action ~= self._capturing and self._state.keybinds[action] == key then
           -- reject: shake row i, stay in capture mode
           self._shake_row   = i
           self._shake_timer = 0.5
           return true
       end
   end
   ```
2. If no conflict: call `set_keybind` as before and exit capture mode.

### `settings_menu.lua` — `update`

Tick the shake timer down:
```lua
if self._shake_timer and self._shake_timer > 0 then
    self._shake_timer = math.max(0, self._shake_timer - dt)
    if self._shake_timer == 0 then self._shake_row = nil end
end
```

### `settings_menu.lua` — `draw` (keybinds subscreen)

For each row `i`, if `self._shake_row == i` and `self._shake_timer > 0`:
- Compute a horizontal shake offset: `math.sin(self._shake_timer * 40) * 8 * (self._shake_timer / 0.5)`
- Tint both the label and value bars red: `love.graphics.setColor(1, 0.25, 0.25, 1)`
- Apply the `x` offset when drawing `img` and `printf` for that row
- After the row, reset color to `(1, 1, 1, 1)`

### `tests/test_settings_state.lua` — Test 6

Update to verify that binding a taken key no longer clears the other action. The rejection is now the menu layer's responsibility; `set_keybind` just sets the key unconditionally. Test 6 now only needs to confirm `set_keybind` stores the value (already covered by Test 5), so it can be removed or repurposed to document the new behavior.

## What stays the same

- `_all_bound` gate: Return button is still greyed out and escape is still blocked while any binding is nil.
- Escape during capture: still cancels capture without changing the binding.
- Modifier keys: still silently rejected (no shake; modifiers can't be bound).
- Collision detection is UI-only — `settings_state.lua` stays a dumb data store.

## Open questions

None — all answered before writing.
