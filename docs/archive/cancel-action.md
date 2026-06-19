## Cancel Action Checklist

- [x] Task A — `lua/core/input.lua` + `lua/game/input.lua` — Wire up the new `cancel` action at the input layer. In `lua/core/input.lua`: add `cancel = "[B]"` to `_PAD_LABELS`; change `pick_up_down` from `"[B]"` to `"[Y]"`; in the gamepad `pad` table change `pick_up_down = joy:isGamepadDown("b")` to `joy:isGamepadDown("y")` and add `cancel = joy:isGamepadDown("b")`. In `lua/game/input.lua`: add `cancel = {"i"}` to the key map table.

- [x] Task B — `lua/game/settings_state.lua` — Add `cancel` to the keybind defaults and key map. In `self.keybinds` add `cancel = "i"`; in `key_map()` add `cancel = {self.keybinds.cancel}` (following the same pattern as the other actions).

- [x] Task C — `lua/game/scenes/store_scene.lua` — Split dismiss out of `_handle_pick_up_down` into a dedicated `_handle_cancel()`. Remove the `if player.x < 0 then … return end` dismiss block from `_handle_pick_up_down`. Add a new `StoreScene:_handle_cancel()` that contains that exact dismiss logic. In `update()`, add `if input:pressed("cancel") then self:_handle_cancel() end` alongside the existing `pick_up_down` press check. In `_hud_labels()`, introduce `local cancel_key = (self.input:key_for("cancel") or "i"):upper()` and change the `DISMISS` hint from `carry_key .. ": DISMISS"` to `cancel_key .. ": DISMISS"`; `carry_key` continues to drive `PICK UP`, `PUT DOWN`, and `SWAP WITH X` hints.

- [x] Task D — `lua/game/scenes/buy_scene.lua` — Switch the cancel-back-to-store action from `pick_up_down` to `cancel`. Change `if input:pressed("pick_up_down") then self.scene_manager:switch(self.store_scene)` to use `input:pressed("cancel")`. In `draw()`, rename `e_key` to `cancel_key` and change it to read `self.input:key_for("cancel") or "i"` (default `"i"`); the hint label stays `": CANCEL"`.

- [x] Task E — `lua/game/scenes/settings_menu.lua` — Add `cancel` as a rebindable action in the keybinds sub-screen. Append `"cancel"` to `_ACTION_LIST` and `"Cancel"` to `_ACTION_LABELS`. No other changes needed — `_all_bound` already iterates `_ACTION_LIST`, and the draw loop already renders all rows.
