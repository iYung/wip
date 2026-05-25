## Goal

Let players remap the six core actions (move up/down/left/right, pick up/put down, interact) from inside the settings menu. Bindings live in `SettingsState` for the session; no file I/O. One key per action. Rebinding uses a press-to-capture overlay.

## Affected files

- `lua/game/settings_state.lua` — add `keybinds` table and `set_keybind` / `key_map` helpers
- `lua/game/input.lua` — initialize from SettingsState defaults instead of bare literals
- `lua/game/scenes/settings_menu.lua` — add "Keybinds" item, keybind sub-screen, capture state, `keypressed()` method
- `main.lua` — call `settings_menu:keypressed(key)` from `love.keypressed`
- `tests/test_settings_state.lua` — cover keybind defaults and `set_keybind`
- `tests/test_settings_menu.lua` — cover keybind sub-screen navigation and capture flow

## What changes

### SettingsState

Gains a `keybinds` table mapping each action to its current key:

```
keybinds = {
    move_up      = "w",
    move_down    = "s",
    move_left    = "a",
    move_right   = "d",
    pick_up_down = "e",
    interact     = "f",
}
```

New methods:
- `set_keybind(action, key)` — updates `keybinds[action]`
- `key_map()` — returns the table in `{action = {key}}` form that `Input.new()` accepts

### lua/game/input.lua

Instead of a hardcoded literal, calls `settings_state:key_map()` so the Input instance always reflects current bindings. `main.lua` passes `ss` (the SettingsState) when constructing input, or input is re-created after a rebind. Simplest approach: call `input._map = ss:key_map()` after any rebind — no re-construction needed since `Input` reads `_map` on every update.

### SettingsMenu — main screen

A fourth item "Keybinds" is added before "Exit Settings":

```
1. Fullscreen / Window
2. Keybinds
3. Exit Settings
4. Leave Game
```

Selecting "Keybinds" pushes the keybind sub-screen (sets `_subscreen = "keybinds"`).

### SettingsMenu — keybind sub-screen

Renders a list of the six actions with their current key:

```
move up      [W]
move down    [S]
move left    [A]
move right   [D]
pick up/down [E]
interact     [F]
```

Navigation: same up/down edge-trigger as main screen, escape returns to main screen.

Selecting an action enters **capture mode** (`_capturing = action`): the label becomes `[press a key]` and all other input is frozen until a key arrives.

### Capture mode

`SettingsMenu:keypressed(key)` is called by `main.lua` from `love.keypressed`. When `_capturing` is set:

1. Calls `_state:set_keybind(_capturing, key)`.
2. Updates `_input._map` via `_state:key_map()` (SettingsMenu holds a reference to the Input instance).
3. Clears `_capturing`.
4. Escape during capture cancels without changing the binding.

Menu navigation in the keybind sub-screen continues to use `_state.keybinds.move_up` / `move_down` so navigation reflects live bindings.

### main.lua

`love.keypressed` already handles escape toggling the menu. Add a call:

```lua
if settings_menu and settings_menu.is_open then
    settings_menu:keypressed(key)
end
```

before the existing escape logic (the menu's `keypressed` will handle escape in capture mode and absorb it; otherwise `keypressed` is a no-op so the existing logic still runs).

## What stays the same

- `SettingsState.fullscreen` and `toggle_fullscreen()` are untouched.
- `Input` class (`lua/core/input.lua`) is unchanged — it already accepts any key_map.
- Settings menu rendering approach (button images, font, layout constants) is unchanged.
- Escape opens/closes the menu from `main.lua`; that path is preserved.
- All existing tests continue to pass.

## Decisions

- **Key collision:** not allowed. When a captured key is already bound to another action, that action's binding is cleared (set to `nil`) before the new binding is applied. The UI shows `[unbound]` for any action with no key.
- **Modifier keys:** not capturable. Keys where `love.keypressed` fires with names like `lshift`, `rshift`, `lctrl`, `rctrl`, `lalt`, `ralt`, `lgui`, `rgui`, `capslock`, `numlock`, `scrolllock` are ignored during capture.
