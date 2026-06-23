## Goal

Prevent the player from swapping or placing plants into the first store slot ("slot zero") while standing in the cashier zone.

## Affected files

- `lua/game/scenes/store_scene.lua`
- `tests/test_carrying.lua` (new test)

## What changes

`_handle_pick_up_down()` is missing the cashier-zone guard that both `_handle_interact()` (line 447) and `_handle_cancel()` (line 368) already have.

`store:slot_at(x)` clamps any negative x to slot index 1 (the leftmost store slot). This means pressing the pick-up key while standing at x < 0 silently resolves to slot 1 and allows swaps/placements there.

**Fix:** add `if player.x < 0 then return end` at the top of `_handle_pick_up_down()`, matching the existing pattern in the other two handlers.

## What stays the same

- All pick-up, swap, and put-down behaviour in the store (x ≥ 0) is unchanged.
- Cashier-zone interactions (interact, cancel/dismiss) are unchanged.
- `store:slot_at()` clamping logic is unchanged — it is correct for all callers that already enforce zone boundaries before calling it.

## Open questions

None.
