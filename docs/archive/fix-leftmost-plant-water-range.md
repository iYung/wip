## Fix Leftmost Plant Water Range Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_handle_interact()`, add `if player.x < 0 then return end` immediately before the `local item = player.held_item or (slot and slot.item)` line (around line 460), after all existing cashier-zone dialog/sale early-return blocks. This is the only code change required.

- [x] Task B — `tests/test_watering_range.lua` (new file) — Create a headless test with two assertions: (1) player positioned at x < 0 (cashier zone) holding a watering can with a stage-ready plant in slot 1 — pressing Interact leaves the plant's stage unchanged; (2) player positioned at x >= 0 (inside store, slot 1) holding the same watering can with the same setup — pressing Interact advances the plant's stage. (Depends on Task A to pass.)
