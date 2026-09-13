# Two-Button Actions Checklist

- [x] Task A — `lua/game/settings_state.lua` — remove `cancel` from the default keybinds table in `SettingsState.new()`
- [x] Task B — `lua/game/input.lua` — remove the `cancel = {"i"}` fallback entry
- [x] Task C — `lua/game/scenes/store_scene.lua` — merge cancel into pick_up_down: (1) remove the `input:pressed("cancel")` branch in `update`; (2) at the top of `_handle_pick_up_down`, when `player.x < 0` call `_handle_cancel()` and return; (3) in `_hud_labels`, remove `cancel_key`/`cancel_icon` locals and change the DISMISS label to use `carry_icon`/`carry_key`
- [x] Task D — `lua/game/scenes/buy_scene.lua` — change `input:pressed("cancel")` to `input:pressed("pick_up_down")`; update the CANCEL display key/icon locals to use `pick_up_down` instead of `cancel`
- [x] Task E — `lua/game/scenes/win_scene.lua` — change `input:pressed("cancel")` to `input:pressed("pick_up_down")`; update the display key/icon locals to use `pick_up_down`
- [x] Task F — `lua/game/scenes/settings_menu.lua` — remove `"cancel"` from `_ACTION_LIST` and `"Cancel"` from `_ACTION_LABELS` (both parallel arrays, same index)
- [x] Task G — `lua/game/scenes/start_scene.lua` — remove the `cancel` hint entry from the bottom-row controls display
