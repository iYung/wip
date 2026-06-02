## Goal

Prevent the player from dismissing a customer during `talking_after` (the post-sale chat). Once the sale has been completed, the customer must finish their after-messages before walking out — the player can no longer cut them off early with the pick-up/down key.

## Affected files

- `lua/game/scenes/store_scene.lua` — `_handle_pick_up_down()`, `_hud_labels()`
- `tests/test_customer_scripts.lua` — add a test covering the new guard

## What changes

### `store_scene.lua` — `_handle_pick_up_down()`

Currently, when the player presses the pick-up/down key in the cashier zone, the code has two branches:

1. `arrived()` (state == `"waiting"`) → dismiss + cooldown (pre-sale dismiss, correct)
2. `talking_after` → dismiss, no cooldown (post-sale dismiss, **to remove**)

Remove branch 2 entirely. During `talking_after`, pressing the key in the cashier zone does nothing.

### `store_scene.lua` — `_hud_labels()`

The `e_label` ("E: DISMISS") already only appears when `arrived()` is true, so it is already absent during `talking_after`. No change needed.

## What stays the same

- Pre-sale dismiss (state `"waiting"`) is unaffected — cooldown logic unchanged.
- Advancing through after-messages with the interact key (`F`) is unaffected.
- `Customer:dismiss()` itself is unchanged; it simply becomes unreachable from `_handle_pick_up_down` during `talking_after`.
- Random (non-scripted) customers have no `after_messages` and so never enter `talking_after`; they are unaffected.

## Open questions

None.
