## First Quest No-Dismiss Checklist

- [x] Task A — `lua/game/data/customer_scripts.lua` — Add `no_dismiss = true` to the sage chapter 1 entry (around line 262). No other scripts get this flag.

- [x] Task B — `lua/game/scenes/store_scene.lua` — Track active script object alongside the key. Wherever `self._active_script_key` is set (line 186), also set `self._active_script = script`. Wherever it is cleared (lines 190, 269, 311), also set `self._active_script = nil`. Initialize `self._active_script = nil` near line 93 where `self._active_script_key = nil` is initialized.

- [x] Task C — `lua/game/scenes/store_scene.lua` — In `_handle_pick_up_down()` (line 264), guard the dismiss block: only call `self._customer:dismiss()` (and set the cooldown) if `not (self._active_script and self._active_script.no_dismiss)`. If no_dismiss is true, return early without doing anything in the cashier zone.

- [x] Task D — `lua/game/scenes/store_scene.lua` — In `_hud_labels()` (line 359), suppress the `"E: DISMISS"` label when the active script has `no_dismiss = true`. Change the condition from `e_label = "E: DISMISS"` to only set it when `not (self._active_script and self._active_script.no_dismiss)`.

- [x] Task E — `tests/test_quest_timing.lua` — Add a test asserting that when sage:1 is the active script, pressing E (pick_up_down) in the cashier zone leaves the customer in the arrived/talking state (not dismissed). Run it as part of the existing test flow.
