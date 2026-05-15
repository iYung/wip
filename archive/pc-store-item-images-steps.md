# PC Store Item Images

Goal: replace the colored rectangle placeholders for non-plant items in the buy scene with actual images.

Current system recap:
- Plant items use `A["plant_N"][3]` (stage-3 image)
- All other items (watering can, grafter, expand slot, sneakers) draw a solid `ent.color` rectangle
- Item color is defined inline in the `CATALOGUE` table in `buy_scene.lua`

---

## Step 1 — Add new art

Create two new images:

| File | Item |
|------|------|
| `assets/sneakers.png` | Speed boost item |
| `assets/expand_slot.png` | Expand slot item |

Watering can and grafter already have usable images (`assets/watering_can.png`, `assets/grafter_empty.png`).

---

## Step 2 — Load new images in `assets.lua`

Add the two new images using `try_img` so missing files don't crash:

```lua
A.sneakers    = try_img("assets/sneakers.png")
A.expand_slot = try_img("assets/expand_slot.png")
```

---

## Step 3 — Add `image` field to catalogue entries in `buy_scene.lua`

Replace the `color` field on tool/upgrade entries with an `image` reference:

```lua
-- watering can
image = A.watering_can,

-- grafter
image = A.grafter_empty,

-- expand slot
image = A.expand_slot,

-- sneakers
image = A.sneakers,
```

Remove the `color` fields from these entries once images are in place.

---

## Step 4 — Update the draw block in `buy_scene.lua`

Replace the `else` branch (colored rectangle) with image drawing, falling back to the rectangle only if the image is missing:

```lua
if ent.kind == "plant" then
    local img = A["plant_" .. ent.plant_type][3]
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img,
        CENTER_X - PREVIEW_SIZE / 2, y, 0,
        PREVIEW_SIZE / img:getWidth(),
        PREVIEW_SIZE / img:getHeight())
elseif ent.image then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ent.image,
        CENTER_X - PREVIEW_SIZE / 2, y, 0,
        PREVIEW_SIZE / ent.image:getWidth(),
        PREVIEW_SIZE / ent.image:getHeight())
else
    love.graphics.setColor(ent.color)
    love.graphics.rectangle("fill", CENTER_X - PREVIEW_SIZE / 2, y, PREVIEW_SIZE, PREVIEW_SIZE)
end
```

The fallback keeps existing behaviour while new art is being made.
