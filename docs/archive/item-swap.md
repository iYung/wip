# Item Swap Checklist

- [x] Task A — `lua/core/input.lua` — Add `key_for(action)` method that returns `self._map[action] and self._map[action][1]`. Insert after the `pressed()` method (line 34), before `return Input`.

- [x] Task B — `lua/game/scenes/store_scene.lua` — Two changes (same file, do together):
  1. In `_handle_pick_up_down()` (line 359): inside the `if player.held_item` branch, add an `elseif` arm after the put-down case — if `slot and slot.item and slot.item.carriable`, swap `player.held_item` ↔ `slot.item` and call `Sound.play("pick_up")`.
  2. In `_hud_labels()` (line 434): compute `e_key = (self.input:key_for("pick_up_down") or "e"):upper()` and `f_key = (self.input:key_for("interact") or "f"):upper()` at the top of the function, then replace every hardcoded `"E:"` prefix with `e_key .. ":"` and every `"F:"` prefix with `f_key .. ":"` throughout all label strings. Also add a new `elseif` arm to the `e_label` block: when `held and slot_item and slot_item.carriable`, set `e_label = e_key .. ": SWAP WITH " .. held.name:upper()`. This arm goes after the existing `elseif not held and slot_item` arm. **Depends on Task A.**

- [x] Task C — `tests/test_ui.lua` — Add two tests at the bottom (before the final `print("ALL TESTS PASSED")`):
  1. A test that constructs a minimal `Input`-like stub with a `key_for` method returning `"g"` and verifies that `_hud_labels` (or a direct string-building equivalent) produces `"G: PICK UP"` rather than `"E: PICK UP"` — use a plain function test, not a full StoreScene instantiation.
  2. A test that verifies the swap label text `"G: SWAP WITH WATERING CAN"` is produced when holding an item named `"Watering Can"` and hovering a carriable item, using the same stub approach. **Depends on Tasks A and B.**
