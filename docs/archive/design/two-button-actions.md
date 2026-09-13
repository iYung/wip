# Two-Button Non-Movement Actions

## Goal

Reduce non-movement action bindings from 3 (`interact`, `pick_up_down`, `cancel`) to 2 (`interact`, `pick_up_down`) by folding `cancel` into `pick_up_down`. The two actions are never needed simultaneously — `pick_up_down` is blocked in every context where `cancel` fires — so this is a clean context-sensitive merge with no ambiguity.

## Affected files

- `lua/game/settings_state.lua` — remove `cancel` from default keybinds
- `lua/game/input.lua` — remove `cancel` fallback key
- `lua/game/scenes/store_scene.lua` — route `cancel` press to `pick_up_down`, update HUD label lookup
- `lua/game/scenes/buy_scene.lua` — route `cancel` press to `pick_up_down`
- `lua/game/scenes/win_scene.lua` — route `cancel` press to `pick_up_down`, update display key lookup
- `lua/game/scenes/settings_menu.lua` — remove `cancel` from `_ACTION_LIST`
- `lua/game/scenes/start_scene.lua` — remove third action button from controls display

## What changes

**Keybind system:** `cancel` is deleted as a named action. Its default key (`i` / `l`) is dropped. `pick_up_down` keeps its own default (`o` / `k`) and absorbs all dismiss/back/exit behaviours.

**StoreScene input loop:** The `input:pressed("cancel")` branch is removed. `_handle_pick_up_down` gains a cashier-zone check at the top — when `player.x < 0`, it calls `_handle_cancel()` (the existing private function) instead of the item manipulation logic.

**StoreScene HUD:** The "DISMISS" label switches from `cancel_icon`/`cancel_key` to `carry_icon`/`carry_key`. The `cancel_*` locals are removed.

**BuyScene:** `input:pressed("cancel")` becomes `input:pressed("pick_up_down")`. The display key/icon for the CANCEL label switches to the `pick_up_down` binding.

**WinScene:** `input:pressed("cancel")` becomes `input:pressed("pick_up_down")`. The display key/icon switches likewise.

**SettingsMenu:** `cancel` removed from `_ACTION_LIST` and its parallel `_ACTION_LABELS` array (both must stay in sync). The rebind list shrinks by one row; `_sub_btn_y0` recalculates automatically from `#_ACTION_LIST`.

**StartScene:** The third controls hint (the `cancel` icon) is removed from the bottom-row display. The remaining two action hints (`interact`, `pick_up_down`) stay.

## What stays the same

- `_handle_cancel()` private function in StoreScene is kept as-is; it is just called from a different trigger.
- All sell, dialog, water, clone, open-shop flows remain on `interact`.
- `pick_up_down` item manipulation logic (pick up, put down, swap) is unchanged.
- Existing `pick_up_down` save data is unaffected (keybind key does not change, only the action name `cancel` is removed).

## Open questions

None — contexts are mutually exclusive and the merge was discussed with the user before writing this doc.
