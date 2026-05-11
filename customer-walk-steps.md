# Customer Walk Animation

Goal: animate the customer between idle and walk frames while moving, same pattern as the player.

---

## Step 1 — Asset

Make `assets/customer_walk.png` at **120×240** (white — tinted at runtime via `body_color`).

Add to `assets.lua`:

```lua
A.customer_walk = img("assets/customer_walk.png")
```

Add to `generate_assets.py`:

```python
rect_faced("customer_walk.png", 120, 240, 1, 1, 1)
```

---

## Step 2 — Switch `Customer` sprite to a `SpriteSet`

In `customer.lua`, require `SpriteSet`:

```lua
local SpriteSet = require("lua/core/spriteset")
```

In `Customer.new()`, replace the single sprite with a SpriteSet:

```lua
-- old
self.sprite       = Sprite.new(0, 0, CW, CH)
self.sprite.image = A.customer
self.sprite.color = {0.85, 0.55, 0.30, 1}
self.sprite.visible = false

-- new
local idle = Sprite.new(0, 0, CW, CH)
idle.image = A.customer
idle.color = {0.85, 0.55, 0.30, 1}

local walk = Sprite.new(0, 0, CW, CH)
walk.image = A.customer_walk
walk.color = {0.85, 0.55, 0.30, 1}

self.sprite = SpriteSet.new()
self.sprite:add("idle", idle)
self.sprite:add("walk", walk)
self.sprite:set("idle")
self.sprite.visible = true
```

---

## Step 3 — Tint both frames in `Customer:show()`

`Customer:show()` currently sets `self.sprite.color`. With a SpriteSet the color must be applied to each frame:

```lua
-- old
self.sprite.color = cfg.body_color or DEFAULT_COLOR

-- new
local color = cfg.body_color or DEFAULT_COLOR
self.sprite.sprites.idle.color = color
self.sprite.sprites.walk.color = color
```

Same for the reset to `DEFAULT_COLOR` in the else branch.

---

## Step 4 — Add animation timer and walk logic in `Customer:update()`

Add timer fields in `Customer.new()`:

```lua
self._anim_timer = 0
self._anim_frame = "idle"
```

In `Customer:update()`, after moving the x position, toggle the frame while walking:

```lua
local moving = self.state == "walking_in" or self.state == "walking_out"
if moving then
    self._anim_timer = self._anim_timer + dt
    if self._anim_timer >= 0.15 then
        self._anim_timer = 0
        self._anim_frame = (self._anim_frame == "idle") and "walk" or "idle"
        self.sprite:set(self._anim_frame)
    end
else
    self._anim_frame = "idle"
    self.sprite:set("idle")
end
```

---

## Step 5 — Fix `sprite.visible` references

`SpriteSet` has its own `visible` field. The existing code sets `self.sprite.visible = false/true` — that still works since `SpriteSet` has a `visible` field that gates `draw()`. No change needed there.

The accessory sprite syncs to `self.sprite.visible` in `update()`. With SpriteSet, `self.sprite.visible` is still a plain field on the SpriteSet table, so that also stays the same.
