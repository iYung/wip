## Cashier Hover Label Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_hud_labels()` (around line 449), add a cashier-side branch for `slot_label`: when `player.x < 0` and `self._customer` is active (state ≠ `"idle"`) and not moving (state ≠ `"walking_in"` and ≠ `"walking_out"`), set `slot_label` to `"HOVERING " .. self._customer.name:upper()`. This naturally handles both scripted customers (named) and generic ones (name defaults to `"Customer"`).
