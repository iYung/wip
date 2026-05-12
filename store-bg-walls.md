# Store Background Walls

## Goal

Draw background wall art behind the store slots. The store currently shows a flat
rectangle. Replace it with a mix of wall tiles and window panels placed according
to a group-of-4 rule. Windows have parallax backgrounds (same technique as the
cashier zone) visible through a transparent cutout in the window PNG.

## Assets

| File | Size | Description |
|------|------|-------------|
| `assets/store_wall.png` | 200 × 720 | Repeating wall tile, one slot wide |
| `assets/store_window.png` | 400 × 720 | Window frame with transparent cutout, two slots wide |
| `assets/store_bg_far.png` | 400 × 720 | Far parallax layer shown behind each window (p = 0.05) |
| `assets/store_bg_mid.png` | 400 × 720 | Mid parallax layer (p = 0.20) |
| `assets/store_bg_near.png` | 400 × 720 | Near parallax layer (p = 0.45) |

Height = 720 (canvas height). `store_window.png` works like `cashier_wall.png` — the
frame is opaque, the window opening is transparent so the parallax layers show through.
The parallax layer PNGs are loaded conditionally (missing files silently skipped).

## Placement Rule

Think of slots in groups of 4. Within each group:

- **Left half (slots 1–2 of the group):** always draw `store_wall.png` once per slot
- **Right half (slots 3–4 of the group):** draw parallax layers then `store_window.png`
  (spanning both slots) **only if** both slots exist AND the rightmost slot is not the
  last slot in the store; otherwise fall back to `store_wall.png` per slot

### Window condition (0-indexed, n = total slots)

```
r0 = group * 4 + 2   -- first slot of right half (left edge of window)
r1 = group * 4 + 3   -- second slot of right half

use_window = (r1 < n) and (r1 < n - 1)
```

### Examples

| Store size | Windows at (1-indexed slot pairs) |
|------------|-----------------------------------|
| 6 slots  | 3–4 |
| 7 slots  | 3–4 |
| 8 slots  | 3–4 |
| 9 slots  | 3–4, 7–8 |
| 10 slots | 3–4, 7–8 |
| 11 slots | 3–4, 7–8 |
| 12 slots | 3–4, 7–8 |

Slot 8 in an 8-slot store is the last slot → no window at 7–8.
Slot 12 in a 12-slot store is the last slot → no window at 11–12.

## Window Parallax Formula

Each window is anchored to its own world position. For a window whose left edge is at
world x = `wx` (= `r0 * slot_width`), and camera at `cx`:

```
draw_x = wx + (cx - (wx + 200)) * (1 - p)
```

- When the camera is centered on the window (`cx = wx + 200`): layer sits at `wx` ✓
- `p = 0`: layer is pinned to its screen position as camera moves (far, slow)
- `p = 1`: layer tracks the window's world position exactly (near, same speed)

This is the same principle as the cashier zone parallax, re-anchored per window.

## Steps

### 1. Load assets in `assets.lua`

```lua
A.store_wall   = img("assets/store_wall.png")
A.store_window = img("assets/store_window.png")

local function try_img(path)
    if love.filesystem.getInfo(path) then return love.graphics.newImage(path) end
end
A.store_bg_far  = try_img("assets/store_bg_far.png")
A.store_bg_mid  = try_img("assets/store_bg_mid.png")
A.store_bg_near = try_img("assets/store_bg_near.png")
```

### 2. Add `Store:draw_bg(A, cx)` in `store.lua`

```lua
local PARALLAX_LAYERS = {
    { key = "store_bg_far",  p = 0.05 },
    { key = "store_bg_mid",  p = 0.20 },
    { key = "store_bg_near", p = 0.45 },
}

function Store:draw_bg(A, cx)
    local n  = #self.slots
    local sw = self.slot_width  -- 200
    local g  = 0
    while g * 4 < n do
        -- left half: two wall tiles
        for i = g * 4, g * 4 + 1 do
            if i < n then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(A.store_wall, i * sw, 0)
            end
        end
        -- right half: window (with parallax) or wall tiles
        local r0, r1 = g * 4 + 2, g * 4 + 3
        if r1 < n and r1 < n - 1 then
            local wx = r0 * sw
            -- parallax layers behind the window
            love.graphics.setColor(1, 1, 1, 1)
            for _, layer in ipairs(PARALLAX_LAYERS) do
                local img = A[layer.key]
                if img then
                    local draw_x = wx + (cx - (wx + 200)) * (1 - layer.p)
                    love.graphics.draw(img, draw_x, 0)
                end
            end
            -- window frame on top
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(A.store_window, wx, 0)
        else
            for i = r0, r1 do
                if i < n then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(A.store_wall, i * sw, 0)
                end
            end
        end
        g = g + 1
    end
end
```

### 3. Call it in `StoreScene:draw()`

Pass `self.camera.x` so the parallax has access to cx:

```lua
self.camera:attach()

-- cashier zone background
love.graphics.setColor(0.10, 0.09, 0.14, 1)
love.graphics.rectangle("fill", -ZONE_WIDTH, 0, ZONE_WIDTH, 720)

-- cashier zone parallax layers ...

-- store background walls (includes window parallax)
local A = require("lua/game/assets")
gs.store:draw_bg(A, self.camera.x)

self.drawer:draw()
self.camera:detach()
```

Remove the flat rectangle from `Store:draw()` once `draw_bg` is in place.
