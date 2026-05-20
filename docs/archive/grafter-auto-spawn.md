## Grafter Auto-Spawn Checklist

- [x] Task A — `lua/game/assets.lua` — Register `grafter_no_space_bubble` using `try_img` (same pattern as other optional assets like `sneakers`). Key: `A.grafter_no_space_bubble`. File path: `assets/grafter_no_space_bubble.png`.

- [x] Task B — `lua/game/items/grafter.lua` — Rewrite the grafter:
  - Remove `self.loaded_plant`, the `unload()` method, and the `grafter_loaded` image swap from `interact()`.
  - Add `self.bubble` (Sprite, 3*U × 3*U, image = `A.grafter_no_space_bubble`, visible = false), `self._bubble_timer = 0`.
  - Add `Grafter:update(dt)` — counts `_bubble_timer` down; sets `bubble.visible = false` when it reaches zero.
  - Add `Grafter:draw_bubble()` — guards on `bubble.visible`; positions bubble above the grafter sprite (same offset as `Plant:draw_bubble`: centered horizontally, `height + 10` px above); draws it.
  - Rewrite `Grafter:interact(player, store, scene_manager)`: find the store slot nearest to the player's current slot (by `math.abs(slot.index - player_slot.index)`; ties go to lower index) where `slot.item == nil`. If found: reset source plant to stage 1 (existing logic), place `Plant.new(plant.plant_type)` into that slot. If not found: do nothing to source plant, set `self.bubble.visible = true`, `self._bubble_timer = 1.5`.
  - Rewrite `Grafter:draw()` — draw only `self.sprite` (remove the `if self.loaded_plant` branch).

- [x] Task C — `lua/game/player.lua` — At the end of `Player:update(dt, input, store)`, add:
  ```lua
  if self.held_item and self.held_item.update then
      self.held_item:update(dt)
  end
  ```
  In `Player:draw()`, after drawing the held item, add:
  ```lua
  if self.held_item and self.held_item.draw_bubble then
      self.held_item:draw_bubble()
  end
  ```

- [x] Task D — `lua/game/scenes/store_scene.lua` — Three removals:
  1. In `_handle_pick_up_down`: delete the loaded-grafter branch (`if player.held_item and player.held_item.loaded_plant ...`).
  2. In `_handle_interact` (garbage bin section): remove the `if held.loaded_plant then held:unload() else` wrapper — simplify to always `player.held_item = nil`.
  3. In `_hud_labels`: remove the `"E: PLACE CLONE"` branch (`if held and held.loaded_plant and slot and not slot_item`).

- [x] Task E — `tests/test_grafter.lua` — Rewrite all tests for new behavior. Keep: rejects stage-2 plant; source resets to stage 1 after clone; cloned plant has correct type. Replace/add: clone auto-places into nearest empty slot (verify slot contents, grafter stays unloaded and in hand); if all slots occupied, grafter bubble becomes visible and source plant is untouched; nearest-slot tie-breaking prefers lower index.
