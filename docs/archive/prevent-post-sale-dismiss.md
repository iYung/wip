## Prevent Post-Sale Dismiss Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_handle_pick_up_down()`, remove the `elseif self._customer.state == "talking_after"` branch (the block that calls `self._customer:dismiss()` after sale). The cashier-zone block should only act when `self._customer:arrived()` is true.

- [x] Task B — `tests/test_customer_scripts.lua` — Add a test: serve a scripted customer that has `after_messages`, then call `_handle_pick_up_down()` while state is `talking_after`, and assert the customer is still in `talking_after` (not dismissed / walking out).
