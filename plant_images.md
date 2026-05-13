# Plant Images Instead of Tinting

Replace color tinting on plant sprites with per-stage images. Also update the PC store and customer request bubbles.

---

## Step 1 — Remove tint from plant sprites

**File:** `lua/game/items/plant.lua` lines 23–30

Currently each stage sprite gets a color tint from `PLANT_DATA`:
```lua
local colors = PLANT_DATA[self.plant_type].colors
local ss = SpriteSet.new()
for i = 1, 3 do
    local s       = Sprite.new(0, 0, ITEM_SIZE, ITEM_SIZE)
    s.color       = colors[i]   -- <-- tint applied here
    s.image       = A["plant_" .. self.plant_type][i]
    ss:add(tostring(i), s)
end
```

Remove the `colors` lookup and the `s.color` assignment (or set it to `{1,1,1,1}`):
```lua
local ss = SpriteSet.new()
for i = 1, 3 do
    local s       = Sprite.new(0, 0, ITEM_SIZE, ITEM_SIZE)
    s.image       = A["plant_" .. self.plant_type][i]
    ss:add(tostring(i), s)
end
```

Each stage now renders its image as-is. The stage-1/2/3 PNGs provide the visual difference instead of the tint.

---

## Step 2 — Clean up plant_data.lua (optional)

**File:** `lua/game/data/plant_data.lua`

Each plant entry has a `colors` table with 3 RGBA values. After Step 1, these are no longer needed for plant sprites. They are still used in Step 3 (customer bubble) until that step is also done.

Once Step 3 is complete, delete the `colors = { ... }` block from every plant entry.

---

## Step 3 — Show plant image in customer request bubble

**File:** `lua/game/customer.lua`

### 3a — Add a plant sprite to the customer

In `Customer.new()` (around line 72, after the existing bubble sprites), add a new sprite for the requested plant:
```lua
self.plant_request_sprite         = Sprite.new(0, 0, BW, BH)
self.plant_request_sprite.visible = false
```

### 3b — Update the sprite on show()

In `Customer:show()` (line 109), replace the bubble color tint:
```lua
-- remove this line:
self.bubble.color = PLANT_DATA[self.plant_type].colors[3]

-- add these lines:
self.plant_request_sprite.image   = A["plant_" .. self.plant_type][3]
self.plant_request_sprite.visible = false
```

The bubble image (`A.customer_bubble`) should be neutral white — if it currently has color baked into the PNG you may want to replace it with a plain white/grey frame so the plant image shows through clearly. Set `self.bubble.color = {1,1,1,1}` to stop tinting the frame.

### 3c — Position the plant sprite in update()

In `Customer:update()` (around line 219 where `self.bubble.x/y` are set), mirror the bubble position to the plant sprite:
```lua
self.plant_request_sprite.x       = self.bubble.x
self.plant_request_sprite.y       = self.bubble.y
self.plant_request_sprite.visible = self.bubble.visible
```

### 3d — Draw the plant sprite

In `Customer:draw_bubble()` (around line 238), draw the plant sprite on top of the bubble frame:
```lua
if self.bubble.visible then
    self.bubble:draw()
    self.plant_request_sprite:draw()
end
```

The plant image will be drawn at the same size as the bubble (BW × BH = 120×120). Scale it down if it needs to be smaller than the bubble frame — adjust `self.plant_request_sprite.width/height` in `new()` as needed.

---

## Step 4 — PC store preview image

**File:** `lua/game/scenes/buy_scene.lua` line 184

The store already draws the plant image without tinting. Currently it shows **stage 3**:
```lua
local img = A["plant_" .. ent.plant_type][3]
```

If you want the store to show **stage 1** (what the player is actually buying), change the index:
```lua
local img = A["plant_" .. ent.plant_type][1]
```

Also remove the leftover `color` field from plant entries in the CATALOGUE table (lines 14–21) since it is only used by the non-plant rectangle fallback and is no longer meaningful for plants:
```lua
-- remove this line from plant entries:
color = pd.colors[1],
```

---

## Asset checklist

Make sure all 18 plant PNGs exist and look distinct at every stage:
- `assets/plant_1_1.png` → `plant_1_3.png`
- `assets/plant_2_1.png` → `plant_2_3.png`
- `assets/plant_3_1.png` → `plant_3_3.png`
- `assets/plant_4_1.png` → `plant_4_3.png`
- `assets/plant_5_1.png` → `plant_5_3.png`
- `assets/plant_6_1.png` → `plant_6_3.png`

They are all already loaded in `lua/game/assets.lua` lines 24–29 — no asset loading changes needed.
