## Block Pick-Up-Down in Cashier Zone Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — add `if player.x < 0 then return end` as the first line of `_handle_pick_up_down()` (after the local declarations), matching the guard already present in `_handle_interact()` and `_handle_cancel()`
- [x] Task B — `tests/test_carrying.lua` — add a test that places the player in the cashier zone (player.x = -100), puts a plant in slot 1 of the store, presses pick_up_down, and asserts the plant stays in the slot and the player's held_item remains nil
