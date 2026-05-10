# Store Appearance

Goal: close the gap between the slot row and the screen bottom; faintly highlight the slot the player is hovering over.

Current layout (world → screen with camera.y = 500):
- Slot top:    world y 600 → screen y 460
- Slot bottom: world y 800 → screen y 660
- Screen bottom: 720 — leaving a 60px gap

---

## Step 1 — Lower the scene to close the gap

- [ ] Reduce `CAMERA_Y` in `store_scene.lua` from `500` to `460`

`CAMERA_Y` in `store_scene.lua` controls the vertical lock. Decreasing it shifts all world content downward on screen (counter-intuitive: lower camera y = content appears lower).

Change `CAMERA_Y` from `500` to `460`:

```lua
-- store_scene.lua
local CAMERA_Y = 460   -- was 500; brings slot bottom to ~screen y 700
```

This moves the slot bottom from screen y 660 → 700, leaving ~20px of breathing room at the bottom. Adjust further if needed — each unit of decrease moves content down by the same amount on screen.

No other files need changing: player y, customer y, and slot y are all world-space constants that stay where they are; the camera shift moves them all together.

---

## Step 2 — Highlight the hovered slot

- [ ] Add `self.highlighted = false` to `Slot.new()` in `slot.lua`
- [ ] Draw a faint white overlay in `Slot:draw()` when `self.highlighted` is true
- [ ] Clear all highlights and set the active slot's each frame in `StoreScene:update()`

### Add `highlighted` to Slot

In `slot.lua`, add the field in `Slot.new()`:

```lua
self.highlighted = false
```

In `Slot:draw()`, after drawing the background image, draw a faint overlay when highlighted:

```lua
function Slot:draw()
    self.bg:draw()
    if self.highlighted then
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.rectangle("fill", self.x, self.y, self.slot_width, SLOT_HEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
    end
    if self.item then
        self.item:draw()
    end
end
```

### Set the highlight each frame from StoreScene

In `store_scene.lua`, inside `StoreScene:update(dt)`, after updating the store and player, clear all highlights then set the active one. Only highlight when the player is in the store zone (not the cashier zone):

```lua
-- clear all
for _, slot in ipairs(gs.store.slots) do
    slot.highlighted = false
end
-- set active
if gs.player.x >= 0 then
    local active = gs.player:active_slot(gs.store)
    if active then active.highlighted = true end
end
```
