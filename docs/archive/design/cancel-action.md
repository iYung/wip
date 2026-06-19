## Goal

Split the overloaded `pick_up_down` action into two distinct actions:
- `pick_up_down` — pick up / put down / swap items in the store
- `cancel` — dismiss a customer dialogue, or exit the buy screen

On gamepad this moves pick-up/put-down from B to Y; cancel/dismiss stays on B where it already feels natural. On keyboard, cancel gets a new default binding (`i`).

## Affected files

- `lua/core/input.lua` — pad label for new `cancel` action; remap `pick_up_down` pad to `y`, add `cancel` pad to `b`
- `lua/game/input.lua` — add `cancel = {"i"}` keyboard binding
- `lua/game/settings_state.lua` — add `cancel = "i"` to default keybinds
- `lua/game/scenes/store_scene.lua` — dismiss logic moves from `pick_up_down` handler to a new `cancel` handler; update HUD hint
- `lua/game/scenes/buy_scene.lua` — change cancel-back-to-store from `pick_up_down` to `cancel`; update HUD hint
- `lua/game/scenes/settings_menu.lua` — add `cancel` row to the keybinds sub-screen (`_ACTION_LIST` / `_ACTION_LABELS`)

## What changes

### `lua/core/input.lua`
- `_PAD_LABELS`: change `pick_up_down` from `"[B]"` to `"[Y]"`, add `cancel = "[B]"`
- gamepad `pad` table: `pick_up_down = joy:isGamepadDown("y")`, `cancel = joy:isGamepadDown("b")`

### `lua/game/input.lua`
- Add `cancel = {"i"}` entry

### `lua/game/settings_state.lua`
- Add `cancel = "i"` to default keybinds
- `key_map()` must include `cancel` so it feeds through to `Input`

### `lua/game/scenes/store_scene.lua`
- Remove dismiss branch from `_handle_pick_up_down` (the `if player.x < 0` block)
- Add `if input:pressed("cancel") then self:_handle_cancel() end` in `update()`
- New `StoreScene:_handle_cancel()` contains the dismiss logic (was the left-side branch of `_handle_pick_up_down`)
- In `_hud_labels()`: introduce `cancel_key = (self.input:key_for("cancel") or "i"):upper()` alongside the existing `carry_key`; the `DISMISS` hint uses `cancel_key`, while `PICK UP`, `PUT DOWN`, and `SWAP WITH X` continue to use `carry_key`

### `lua/game/scenes/buy_scene.lua`
- Change `if input:pressed("pick_up_down") then` → `if input:pressed("cancel") then`
- HUD hint: rename `e_key` to `cancel_key` and read from `key_for("cancel")` (default `"i"`); label stays `: CANCEL`

### `lua/game/scenes/settings_menu.lua`
- Append `"cancel"` to `_ACTION_LIST` and `"Cancel"` to `_ACTION_LABELS`
- `_all_bound` already iterates `_ACTION_LIST`, so adding the entry there is sufficient

## What stays the same

- Gamepad A = interact (unchanged)
- Keyboard `o` = pick_up_down (unchanged)
- Keyboard `escape` = toggle settings menu (unchanged, handled separately in `main.lua`)
- `SettingsMenu` escape/B-button navigation logic is untouched — it uses its own local gamepad reads, not the action map
- All other keybinds and defaults unchanged

## Open questions

None — keyboard default confirmed as `i`, gamepad B = cancel, gamepad Y = pick_up_down.
