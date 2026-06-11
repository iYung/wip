## Goal

Replace the dedicated `pick_up_down` button (O) with directional intent: pressing **up** (W) picks up, pressing **down** (S) puts down. Both directions trigger swaps. The `pick_up_down` action is removed entirely.

## Affected files

- `lua/game/input.lua`
- `lua/game/settings_state.lua`
- `lua/game/scenes/store_scene.lua`
- `lua/game/scenes/buy_scene.lua`
- `lua/game/scenes/start_scene.lua`
- `lua/game/scenes/settings_menu.lua`

## What changes

### Input action removal
`pick_up_down` is deleted from `lua/game/input.lua` and from `SettingsState` defaults. The existing `move_up`/`move_down` actions absorb the pick/put logic; no new actions are added.

### Why this works without conflict
The player only moves left/right — `is_down("move_up")` and `is_down("move_down")` are never read in `player.lua`. The `pressed()` edge (first frame only) fires pick/put; subsequent held frames do nothing in the store zone.

### Store scene — new split logic (store_scene.lua)

`update()` replaces the single `pick_up_down` check with two:

```
move_up  pressed → _handle_pick_up()
move_down pressed → _handle_put_down()
```

**Cashier zone (player.x < 0):** either `move_up` or `move_down` dismisses the customer (same as before, just triggered by either key).

**Plant zone (player.x >= 0):**

| State | Up pressed | Down pressed |
|---|---|---|
| Not holding, carriable in slot | Pick up from slot | Nothing |
| Holding, slot empty | Nothing | Put down into slot |
| Holding, carriable in slot | Swap (pick up slot item) | Swap (put down held item) |
| Holding, non-carriable in slot | Nothing | Nothing |

Both directions produce a swap when holding over a carriable slot item — this matches the user requirement.

### HUD labels (store_scene.lua `_hud_labels`)

The single `e_label` becomes two entries — one for up and one for down — only shown when relevant:

- `up_key .. ": PICK UP"` — when not holding and slot has carriable item
- `down_key .. ": PUT DOWN"` — when holding and slot is empty
- `up_key .. "/" .. down_key .. ": SWAP"` — when holding and slot has carriable item
- `up_key .. "/" .. down_key .. ": DISMISS"` — when in cashier zone with customer

The HUD box already stacks multiple labels so no layout changes are needed.

### Buy scene (buy_scene.lua)

`pick_up_down` pressed → replaced with `move_down` pressed (down = "back", putting the item back / exiting the shop).

### Start scene (start_scene.lua)

- Remove `pick_up_down` as an alternative confirm action (interact / P alone confirms).
- Remove the `kp` key display at the bottom of the start screen (the pick_up_down indicator).

### Settings menu (settings_menu.lua)

- Remove `pick_up_down` from `_ACTION_LIST` / `_ACTION_LABELS` (6 → 5 rebindable actions).
- Remove `pick_up_down` from all `confirm` key checks in the menu (only `interact` + return/space confirm).
- Update `_sub_btn_y0` row-centering to use 5 rows instead of 6.
- Update `_all_bound` check (already iterates `_ACTION_LIST`, so no change needed there).

### Save compatibility

`settings.dat` files that have a saved `pick_up_down` keybind are safe. `SettingsState.from_save` guards each keybind with `if self.keybinds[action] ~= nil` — since `pick_up_down` won't exist in the new defaults, it is silently skipped. All other keybinds restore normally. `to_save` iterates `self.keybinds`, so new saves simply won't include `pick_up_down`.

`_all_bound` in `settings_menu.lua` iterates `_ACTION_LIST`. After removing `pick_up_down` it checks 5 actions (`move_up`, `move_down`, `move_left`, `move_right`, `interact`) — all of which have defaults, so the "all keys must be bound" guard still works.

## What stays the same

- `move_up` / `move_down` key defaults (W / S) are unchanged.
- `interact` (P) is unchanged.
- All menu navigation using up/down is unchanged (settings_menu.lua reads `move_up`/`move_down` keybinds for navigation — the same bindings now also drive pick/put in gameplay).
- Sound effects `pick_up` and `put_down` are still played on the appropriate action.
- Swap behaviour is identical to before, just reachable from both directions.

## Open questions

None — player movement is left/right only so up/down keys are free for context actions.
