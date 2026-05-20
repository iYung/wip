## Goal

When the player clones a stage-3 plant with the Grafter, the clone spawns immediately into the nearest empty slot instead of being stored inside the Grafter for later manual placement. If no empty slot exists, the Grafter emits a bubble sprite (user-supplied image) using the same pattern as the plant's water-ready bubble.

## Affected files

- `lua/game/items/grafter.lua` — core behavior change; remove loaded state; add bubble + update + draw_bubble
- `lua/game/assets.lua` — register `grafter_no_space_bubble` image
- `lua/game/player.lua` — call `held_item:update(dt)` and `held_item:draw_bubble()` each frame if the methods exist
- `lua/game/scenes/store_scene.lua` — remove clone-placement branch from `_handle_pick_up_down`; remove garbage-bin unload branch; remove "E: PLACE CLONE" HUD label
- `tests/test_grafter.lua` — rewrite tests to match new behavior

## What changes

### Grafter behavior

`Grafter:interact(player, store, scene_manager)` currently stores the clone in `self.loaded_plant`. New behavior:

1. Search all store slots by index distance from the player's current slot. Pick the closest one where `slot.item == nil`. On a tie (equidistant slots), prefer the lower index (leftmost).
2. **No empty slot found:** do nothing to the source plant. Trigger the "no space" bubble (set `self.bubble.visible = true`, reset `self._bubble_timer`).
3. **Empty slot found:** reset the source plant to stage 1 (existing logic), create a new `Plant.new(plant.plant_type)`, place it into that slot. The grafter shows no visual state change.

### "No space" bubble — same pattern as plant's water bubble

Grafter gains three new additions that mirror `Plant` exactly:

```
self.bubble         = Sprite at 3*U × 3*U (60×60, matching plant_bubble size)
self.bubble.image   = A.grafter_no_space_bubble   -- user-supplied PNG
self.bubble.visible = false
self._bubble_timer  = 0   -- seconds remaining; counts down in update()
```

**`Grafter:update(dt)`** — counts down `_bubble_timer`; sets `bubble.visible = false` when it reaches zero. Timer starts at 1.5 s on no-space trigger.

**`Grafter:draw_bubble()`** — positions the bubble above the grafter sprite (same offset formula as `Plant:draw_bubble()`), then draws it. Guards on `bubble.visible`.

### Player integration

`Player:update(dt, input, store)` gains a call at the end:
```lua
if self.held_item and self.held_item.update then
    self.held_item:update(dt)
end
```

`Player:draw()` gains a call after drawing the held item:
```lua
if self.held_item and self.held_item.draw_bubble then
    self.held_item:draw_bubble()
end
```

This is the minimal change that lets the grafter (or any future tool) own its own bubble without the scene knowing about it.

### StoreScene cleanup

Remove from `_handle_pick_up_down`:
```lua
-- loaded grafter + empty slot → place clone, grafter stays in hand
if player.held_item and player.held_item.loaded_plant and slot and not slot.item then
    slot.item = player.held_item.loaded_plant
    player.held_item:unload()
    return
end
```

Remove from `_handle_interact` (garbage bin branch):
```lua
if held.loaded_plant then
    held:unload()
else
```
(simplify to just `player.held_item = nil`)

Remove from `_hud_labels`:
```lua
if held and held.loaded_plant and slot and not slot_item then
    e_label = "E: PLACE CLONE"
```

### Asset

Add to `lua/game/assets.lua`:
```lua
A.grafter_no_space_bubble = love.graphics.newImage("assets/grafter_no_space_bubble.png")
```
Use `try_img` (same as other optional assets) so missing art degrades to nil and the bubble simply doesn't draw. The user will supply the PNG.

## What stays the same

- Grafter is still carriable; player picks it up and puts it down normally.
- Cloning still requires source stage == 3.
- Source plant still resets to stage 1 after a successful clone.
- `grafter_empty` is the only image the grafter ever shows (no `grafter_loaded` swap).
- `grafter_loaded` asset stays loaded in assets.lua but is no longer referenced by grafter code.
- All other tool interactions (WateringCan, GarbageBin, PCStore) unchanged.

## Open questions

None — all decisions resolved.
