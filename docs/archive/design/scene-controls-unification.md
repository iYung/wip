## Goal

Ensure every scene in the game uses exactly the same 6 rebindable actions — `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `pick_up_down` — so that a keybind change in Settings affects all scenes uniformly.

## Affected files

- `lua/game/input.lua`
- `lua/game/scenes/start_scene.lua`
- `lua/game/scenes/settings_menu.lua`

## What changes

**`lua/game/input.lua`**
Remove the `menu_confirm` action. It was a 7th action (`{"return", "space", "f"}`) that was never exposed in the keybind settings UI, and was silently wiped from the input map every time the player saved a rebind (because `SettingsState:key_map()` only emits the 6 bindable actions).

**`lua/game/scenes/start_scene.lua`**
Replace `input:pressed("menu_confirm")` with `input:pressed("interact") or input:pressed("pick_up_down")`. Start screen confirmation now uses the same two actions as every other confirm in the game.

**`lua/game/scenes/settings_menu.lua`**
The keybinds subscreen already read from `self._state.keybinds.*` for navigation. The main menu screen and the `open()` key-state snapshot still hardcoded `"w"/"s"/"a"/"d"/"e"/"f"`. Updated both to read from `keybinds.*` with arrow keys kept as permanent hardcoded fallbacks (so navigation always works even if keybinds are cleared).

## What stays the same

- `escape` remains hardcoded everywhere — intentionally not rebindable.
- `return` / `space` remain hardcoded as extra confirm fallbacks in the settings menu — reasonable since they are standard UI keys.
- Arrow keys remain hardcoded as navigation fallbacks in the settings menu — safety net for broken keybind states.
- `SettingsState:key_map()` emits exactly the 6 actions, unchanged.
- All other scenes (`store_scene`, `buy_scene`, `player`) already used the Input system correctly.

## Open questions

None — all decisions made during implementation.
