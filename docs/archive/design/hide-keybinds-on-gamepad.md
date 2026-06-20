# Hide Keybinds in Settings When Using a Controller

## Goal

When the player's last-used input device is a gamepad (`input._mode == "gamepad"`), the "Keybinds" option should not appear in the settings menu. Keybind remapping only applies to keyboard keys, so showing it while the player is navigating with a controller is confusing and useless.

## Affected files

- `lua/game/scenes/settings_menu.lua`

## What changes

- `_visible_items` currently takes one argument (`opaque`) and filters out "Save Game" (item 5) when opaque. It will also accept the current input mode and filter out "Keybinds" (item 4) when mode is `"gamepad"`.
- `SettingsMenu:update()` and `SettingsMenu:draw()` both call `_visible_items`. They will pass `self._input._mode` so the list is computed dynamically on each frame.
- `_confirm()` selects actions by item index (1–7). With item 4 removed from the visible list, navigation skips straight from item 3 ("Music Volume") to item 5 ("Save Game") — no index renumbering needed because `_visible_items` already returns original indices.

## What stays the same

- Item indices in `ITEMS` are unchanged. `_confirm()` still dispatches on those same indices.
- The keybinds subscreen itself (`self._subscreen == "keybinds"`) is unchanged — it remains accessible via keyboard in the future if mode switches, or for any direct code path.
- All other settings items and their behavior are unaffected.
- `_opaque` filtering (hides "Save Game" at the start screen) is unchanged.

## Open questions

None — hide trigger confirmed as `input._mode == "gamepad"` (dynamic, per-frame check).
