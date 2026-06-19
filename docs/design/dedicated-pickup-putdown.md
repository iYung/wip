# Dedicated Pick Up / Put Down Key

## Goal
Replace the two-key carry scheme (W = pick up, S = put down) with a single dedicated carry key (default O) that is rebindable and separate from `interact`.

## Context
The `up-down-pickup-putdown` feature moved carry actions onto `move_up` (W) and `move_down` (S) — the same keys used for menu navigation. "Dedicated" means one key that is only for carrying, not shared with navigation or interact. The single key works context-sensitively: pick up when empty-handed, put down when holding, swap when both hands and slot are occupied.

## Affected files
- `lua/game/input.lua` — add `pick_up_down = {"o"}`; add `pick_up_down = "[B]"` to `_PAD_LABELS`; add `pick_up_down` to the gamepad `pad` table in `update()` mapped to the B button
- `lua/game/settings_state.lua` — add `pick_up_down = "o"` to default keybinds
- `lua/game/scenes/store_scene.lua` — replace the two `move_up`/`move_down` pressed checks with one `pick_up_down` check; merge `_handle_pick_up()` and `_handle_put_down()` into a single `_handle_pick_up_down()`; update `_hud_labels()` to use the new action name
- `lua/game/scenes/buy_scene.lua` — replace `input:pressed("move_down")` (cancel) with `input:pressed("pick_up_down")`; update bottom-left HUD key label to read `key_for("pick_up_down")`
- `lua/game/scenes/settings_menu.lua` — replace `move_up` / `move_down` rows with a single "Pick Up / Put Down" row; remove B button as "back" from `_joy_nav` and all `_prev_back` / `_prev_sub_back` usages throughout

## What changes

### `lua/game/input.lua`
Add:
```lua
pick_up_down = {"o"},
```

### `lua/game/settings_state.lua`
Add to `self.keybinds`:
```lua
pick_up_down="o"
```
The existing `from_save` guard handles old saves automatically.

### `lua/game/scenes/store_scene.lua` — `update()`
Replace:
```lua
if input:pressed("move_up") then
    self:_handle_pick_up()
elseif input:pressed("move_down") then
    self:_handle_put_down()
end
```
With:
```lua
if input:pressed("pick_up_down") then
    self:_handle_pick_up_down()
end
```

### `lua/game/scenes/store_scene.lua` — merge handlers
Merge `_handle_pick_up()` and `_handle_put_down()` into one `_handle_pick_up_down()`:
- Cashier zone (player.x < 0): dismiss customer if arrived and dismissible
- Holding + carriable slot item: swap
- Not holding + carriable slot item: pick up
- Holding + empty slot: put down

### `lua/game/scenes/store_scene.lua` — `_hud_labels()`
Replace `up_key`/`down_key` (from `move_up`/`move_down`) with a single `carry_key` (from `pick_up_down`):
```lua
local carry_key = (self.input:key_for("pick_up_down") or "o"):upper()
```
Update labels to use `carry_key` alone:
- `carry_key .. ": PICK UP"` when not holding, carriable slot
- `carry_key .. ": PUT DOWN"` when holding, empty slot
- `carry_key .. ": SWAP WITH " .. name` when holding, carriable slot
- `carry_key .. ": DISMISS"` in cashier zone with customer

### `lua/game/scenes/settings_menu.lua`
Replace `move_up` and `move_down` rows with a single `pick_up_down` row:
```lua
local _ACTION_LIST   = {"pick_up_down","move_left","move_right","interact"}
local _ACTION_LABELS = {"Pick Up / Put Down","Left","Right","Interact"}
```
Update `_sub_btn_y0` centering formula to `#_ACTION_LIST` (4 rows).

Also replace `move_up` / `move_down` key snapshot reads in `open()` and `update()` — the settings menu uses W/S to scroll through its own rows. Those references stay as `move_up`/`move_down` since that navigation is still on W/S; only the carry action changes.

## What stays the same
- `move_up` and `move_down` (W/S) remain in the input map and settings state — Start screen and Settings menu navigation still uses them
- All carry logic (swap, pick up, put down, dismiss) is unchanged — just consolidated into one handler
- `interact` (Space / A button) is untouched
- Settings menu Start button and Escape to close remain — only B as a "back" shortcut is removed

## Save compatibility
`SettingsState.from_save` guards with `if self.keybinds[action] ~= nil` — it only loads a saved keybind if that action exists in the defaults. Adding `pick_up_down` back to the defaults means: old saves with a custom `pick_up_down` binding restore correctly; saves without it fall back to "o". No migration needed.

## Open questions
None.
