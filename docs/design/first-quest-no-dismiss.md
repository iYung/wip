## Goal

Make the first scripted quest (sage chapter 1 / Sir Moneyton) non-dismissable — the player cannot press E to skip the customer early. The "E: DISMISS" label in the bottom-left HUD must also be hidden for this quest.

## Affected files

- `lua/game/data/customer_scripts.lua` — add `no_dismiss = true` to the sage chapter 1 entry
- `lua/game/scenes/store_scene.lua` — store the active script object (not just key), gate dismiss on `no_dismiss`, hide HUD label accordingly
- `tests/test_quest_timing.lua` (or a new test file) — add a test covering the no-dismiss behavior

## What changes

1. **customer_scripts.lua**: sage chapter 1 gets `no_dismiss = true`.

2. **store_scene.lua**:
   - Add `self._active_script` alongside `self._active_script_key`. Set it whenever `_active_script_key` is set; clear it when the key is cleared.
   - `_handle_pick_up_down`: before calling `_customer:dismiss()`, check `not (self._active_script and self._active_script.no_dismiss)`. If no_dismiss is true, do nothing (no dismiss, no return-early swallowing of input either — the E press is simply ignored in the cashier zone).
   - `_hud_labels`: the `e_label = "E: DISMISS"` branch gains the same guard, so the label is suppressed when the active quest is non-dismissable.

3. **tests**: add a test asserting that with sage:1 as the active script, calling `_handle_pick_up_down()` leaves the customer in its arrived state (not dismissed).

## What stays the same

- All other quests remain dismissable.
- The cooldown logic on dismiss is unchanged — it simply won't be reached for no_dismiss quests.
- The F-key sell/advance flow is unaffected.
- No new public API on Customer.

## Open questions

None — scope is clear.
