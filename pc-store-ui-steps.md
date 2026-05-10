# PC Store UI Fixes

Goal: plant previews in the shop show real plant images instead of colored rectangles; buying an upgrade (Expand Slot, Speed Boost) stays in the shop instead of closing it.

---

## Step 1 — Use real plant images in the preview

- [ ] Add `local A = require("lua/game/assets")` to `buy_scene.lua`
- [ ] Replace the colored rectangle preview with the stage-3 plant image for plant entries

Currently `buy_scene.lua` draws a colored rectangle for each catalogue entry using `ent.color`. For plant entries, replace this with the actual stage-3 plant image from `assets`.

In `BuyScene:draw()`, the preview block currently:
```lua
love.graphics.setColor(ent.color)
love.graphics.rectangle("fill",
    CENTER_X - PREVIEW_SIZE / 2,
    CENTER_Y - 140 - PREVIEW_SIZE / 2,
    PREVIEW_SIZE, PREVIEW_SIZE)
```

Change to draw the image when available, falling back to the colored rectangle for non-plant entries:
```lua
if ent.kind == "plant" then
    local img = A["plant_" .. ent.plant_type][3]
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img,
        CENTER_X - PREVIEW_SIZE / 2,
        CENTER_Y - 140 - PREVIEW_SIZE / 2,
        0,
        PREVIEW_SIZE / img:getWidth(),
        PREVIEW_SIZE / img:getHeight())
else
    love.graphics.setColor(ent.color)
    love.graphics.rectangle("fill",
        CENTER_X - PREVIEW_SIZE / 2,
        CENTER_Y - 140 - PREVIEW_SIZE / 2,
        PREVIEW_SIZE, PREVIEW_SIZE)
end
```

Add `local A = require("lua/game/assets")` at the top of `buy_scene.lua`.

---

## Step 2 — Expand Slot and Speed Boost stay in the shop after purchase

- [ ] Remove `scene_manager:switch` from the speed boost branch
- [ ] Remove `scene_manager:switch` from the expand branch; keep it only for hand items (plant, watering can, grafter)

In `BuyScene:_confirm()`, every successful purchase currently ends with `self.scene_manager:switch(self.store_scene)`. Expand Slot and Speed Boost are upgrades — they should apply and stay in the shop so the player can buy another or browse. Only items that go into the player's hand (plants, watering can, grafter) should close the shop.

Current speed boost block:
```lua
if ent.kind == "speed_boost" then
    ...
    self.scene_manager:switch(self.store_scene)  -- remove this
    return
end
```

Current expand block (inside the general branch):
```lua
elseif kind == "expand" then
    gs.store:grow()
end
self.scene_manager:switch(self.store_scene)  -- keep only for hand items
```

New structure:
```lua
function BuyScene:_confirm()
    local gs  = self.game_state
    local ent = CATALOGUE[self.selected]

    if ent.kind == "speed_boost" then
        if gs.speed_level >= #SPEED_TIERS then return end
        local tier = SPEED_TIERS[gs.speed_level + 1]
        if gs.currency < tier.cost then return end
        gs.currency    = gs.currency - tier.cost
        gs.speed_level = gs.speed_level + 1
        gs.player.speed = tier.speed
        return   -- stay in shop
    end

    if gs.currency < ent.cost then return end
    gs.currency = gs.currency - ent.cost

    local kind = ent.kind
    if kind == "plant" then
        gs.player.held_item = Plant.new(ent.plant_type)
        gs.unlocked_plants[ent.plant_type] = true
        self.scene_manager:switch(self.store_scene)
    elseif kind == "tool_watering_can" then
        gs.player.held_item = WateringCan.new()
        self.scene_manager:switch(self.store_scene)
    elseif kind == "tool_grafter" then
        gs.player.held_item = Grafter.new()
        self.scene_manager:switch(self.store_scene)
    elseif kind == "expand" then
        gs.store:grow()
        -- stay in shop
    end
end
```
