# Facing Direction Steps

Goal: player and customer sprites face the direction they are moving. Uses `scale_x = -1` to mirror the sprite in place — no extra images needed. Before wiring the logic, update the placeholder PNGs so the facing direction is actually visible.

---

## Step 1 — Update placeholder sprites to show facing

Add an asymmetric direction marker to `player_*` and `customer` PNGs in `generate_assets.py`. The marker makes it obvious which way the sprite is facing without real art.

Proposed marker: a small dark triangle on the right edge pointing right (the "nose"), drawn in the top-center area of the sprite where a face would be.

Player (120×240):
- Dark triangle at roughly x=85–115, y=30–60, pointing right

Customer (120×240):
- Same marker, adjusted for the rounder head region

Regenerate:
```
python3 generate_assets.py
```

---

## Step 2 — Fix `Sprite:draw()` for in-place horizontal flip

`scale_x = -1` currently flips around the sprite's left edge (x=0 in local space), sliding it off screen. Fix by translating right by `self.width` before applying a negative scale so the right edge becomes the pivot — the sprite mirrors in place.

In `lua/core/sprite.lua`, change the translate line:

```lua
-- before
love.graphics.translate(self.x, self.y)
love.graphics.scale(self.scale_x, self.scale_y)

-- after
local flip_ox = (self.scale_x < 0) and self.width or 0
love.graphics.translate(self.x + flip_ox, self.y)
love.graphics.scale(self.scale_x, self.scale_y)
```

With this, `sprite.scale_x = -1` mirrors the sprite within its declared bounding box with no position changes needed in the caller.

SpriteSet forwards `x`/`y` but not `scale_x` to individual sprites. Since individual sprites within a SpriteSet have their own `scale_x`, the flip needs to be set on the SpriteSet level and forwarded on draw.

Update `SpriteSet:draw()` in `lua/core/spriteset.lua` to also forward `scale_x`:

```lua
function SpriteSet:draw()
    if not self.visible then return end
    local s = self:_active()
    if not s then return end
    s.x       = self.x
    s.y       = self.y
    s.scale_x = self.scale_x
    s:draw()
end
```

Add `scale_x = 1` to `SpriteSet.new()` defaults.

---

## Step 3 — Player facing

In `lua/game/player.lua`:

Add a `facing` field, default `"right"`.

In `Player:update()`, after resolving movement:
- Moving right → `self.facing = "right"`
- Moving left → `self.facing = "left"`
- Not moving → keep last facing

After setting the animation frame, apply to the SpriteSet:

```lua
self.sprite.scale_x = self.facing == "left" and -1 or 1
```

---

## Step 4 — Customer facing

In `lua/game/customer.lua`:

In `Customer:update()`, set `sprite.scale_x` based on state:

| State | Direction | scale_x |
|-------|-----------|---------|
| `walking_in` | moving right (toward counter) | `1` |
| `waiting` | idle at counter, facing store | `1` |
| `walking_out` | moving left (exiting) | `-1` |

```lua
self.sprite.scale_x = (self.state == "walking_out") and -1 or 1
```

The bubble does not need to flip (it just shows the requested plant color).

---

## Notes

- `scale_x` is a per-Sprite property; in SpriteSet it should be at the set level and forwarded to the active sprite in `draw()` (Step 2)
- The bubble sprite in Customer is a plain square; no facing needed
- If real character art is added later, the same flip approach works — just make the art face right as the default
