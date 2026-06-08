## Goal

Prevent the player from leaving the keybinds sub-screen until every action has a key assigned. Binding one key to a new action steals it from the previous one, which can leave actions unbound. The validation makes this impossible to exit in a broken state.

## Affected files

- `lua/game/scenes/settings_menu.lua`
- `tests/test_settings_menu.lua`

## What changes

### Helper: `_all_bound()`

Add a module-local (or inline) helper that returns `true` when every entry in `_ACTION_LIST` has a non-nil value in `self._state.keybinds`.

### Block leaving the sub-screen

Two exit paths exist: confirming the Return row and pressing escape (while not capturing). Both must be gated by the helper.

- In `update()` keybinds branch: when `confirm` fires on the Return row (`self._subscreen_selected == sub_count`), only set `self._subscreen = nil` if `_all_bound`. Otherwise play an error sound (or do nothing).
- In `update()` keybinds branch: when `escape` fires, only close if `_all_bound`. Otherwise do nothing.
- In `keypressed()`: when `self._subscreen == "keybinds"` and `self._capturing == nil` and `key == "escape"`, only set `self._subscreen = nil` if `_all_bound`.

### Disabled-state visuals for Return button

When not all keys are bound:
- Draw the Return button using `self._img_btn` (unselected image) even when it is the selected row, tinted to 0.4 alpha — `love.graphics.setColor(1, 1, 1, 0.4)` — matching how `start_scene.lua` renders the disabled Continue button.
- Draw the "Return" label at the same 0.4 alpha.
- Draw a small hint line below the Return button: `"all keys must be bound"` centered over `BTN_W` at `ry + BTN_H + 6`, using a smaller font (e.g. `self._font_vol`), tinted red `(1, 0.35, 0.35, 1)`.

When all keys are bound, Return renders exactly as before (normal or selected image, full alpha, no hint text).

## What stays the same

- The escape key while in **capture mode** (`self._capturing ~= nil`) cancels the capture without closing the sub-screen — this behaviour is unchanged.
- All navigation (up/down within the sub-screen, selecting individual actions, capture flow) is unchanged.
- `SettingsState` and `settings_state.lua` are not touched.
- The main settings menu and all other sub-screens are not touched.

## Open questions

None.
