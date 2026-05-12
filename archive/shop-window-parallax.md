# Shop Window Parallax Background

## Goal

The cashier zone (x = -400 to 0) currently draws only the cashier wall PNG and the customer. Add PNG background layers behind the customer that parallax as the player (and camera) moves left/right, giving the window a sense of depth.

## How Parallax Works Here

The camera follows the player on x. Each layer is drawn at a world-x offset scaled by a parallax factor `p` (0 = pinned to screen, 1 = moves fully with the world). Layers farther "back" get smaller `p`, so they drift less as the camera moves.

```
draw_x = layer_origin_x + camera.x * (1 - p)
```

Three layers suggested (adjust count/factors to taste):

| Layer | File | Factor `p` | Moves with camera |
|-------|------|-----------|-------------------|
| Far   | `assets/shop_bg_far.png`  | 0.05 | barely |
| Mid   | `assets/shop_bg_mid.png`  | 0.20 | gently |
| Near  | `assets/shop_bg_near.png` | 0.45 | noticeably |

## Art Specs

- Each PNG should be **400 × 800** (matches ZONE_WIDTH × screen height)
- Transparent or dark — they sit behind the customer
- Far layer: sky / distant shapes
- Mid layer: mid-distance shapes / shelves / scenery
- Near layer: foreground silhouettes / window frame elements

## Draw Order (updated)

```
0   store (slots + items)
1   customer
2   wall (cashier_wall.png)        ← parallax layers go BEHIND this
2.5 cashier_floor
3   plant_bubbles
4   player
5   customer_bubble
```

Parallax layers draw before layer `1` (customer), so behind everything in the cashier zone. Insert them at priority `-1` in the drawer (or draw manually in `StoreScene:draw()` before `self.drawer:draw()`).

Since the layers are in world space (inside `camera:attach()`/`camera:detach()`), the draw call goes between those two calls — but before the drawer renders anything.

## Steps

### 1. Create assets

Make three PNGs at 400 × 800 and drop them in `assets/`:
- `shop_bg_far.png`
- `shop_bg_mid.png`
- `shop_bg_near.png`

### 2. Load in `assets.lua`

```lua
A.shop_bg_far  = img("assets/shop_bg_far.png")
A.shop_bg_mid  = img("assets/shop_bg_mid.png")
A.shop_bg_near = img("assets/shop_bg_near.png")
```

### 3. Add parallax draw in `StoreScene:draw()`

Replace the manual background rectangle and drawer call with:

```lua
function StoreScene:draw()
    self.camera:attach()

    -- zone background
    love.graphics.setColor(0.10, 0.09, 0.14, 1)
    love.graphics.rectangle("fill", -ZONE_WIDTH, 0, ZONE_WIDTH, 800)

    -- parallax layers (world space, clipped to cashier zone visually by the wall on top)
    local cx = self.camera.x
    local layers = {
        { img = A.shop_bg_far,  p = 0.05 },
        { img = A.shop_bg_mid,  p = 0.20 },
        { img = A.shop_bg_near, p = 0.45 },
    }
    love.graphics.setColor(1, 1, 1, 1)
    for _, layer in ipairs(layers) do
        local draw_x = -ZONE_WIDTH + cx * (1 - layer.p)
        love.graphics.draw(layer.img, draw_x, 0)
    end

    self.drawer:draw()
    self.camera:detach()

    -- HUD ...
end
```

The cashier wall PNG draws on top (priority 2 in the drawer), masking the layers to just the window area.

## Notes

- No animations
- Each layer PNG uses transparency — upper layers reveal lower layers through cutouts
- No tiling; layers are sized to the window and stay within it
