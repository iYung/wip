# Bubble Updates

Two changes: larger plant bubbles, and a heart bubble on customer walkout.

---

## Step 1 — Plant bubble 120×120

Currently `plant_bubble` is 60×60 (3U). Resize to 120×120 (6U) to match items.

In `plant.lua`, change the bubble sprite size:

```lua
-- old
self.bubble = Sprite.new(0, 0, 3 * U, 3 * U)  -- 60x60

-- new
self.bubble = Sprite.new(0, 0, 6 * U, 6 * U)  -- 120x120
```

Update `generate_assets.py` plant_bubble line:

```python
# old
rect("plant_bubble.png", 60, 60, 1, 1, 1)

# new
rect("plant_bubble.png", 120, 120, 1, 1, 1)
```

Tell user to make `assets/plant_bubble.png` at **120×120** (white, tinted yellow at runtime).

---

## Step 2 — Heart bubble asset

Add to `assets.lua`:

```lua
A.heart_bubble = img("assets/heart_bubble.png")
```

Tell user to make `assets/heart_bubble.png` at **120×120** (white — tinted pink at runtime).

```python
rect("heart_bubble.png", 120, 120, 1, 1, 1)
```

---

## Step 3 — Heart bubble in `Customer`

In `customer.lua`, add the heart bubble sprite in `Customer.new()` after the existing bubble:

```lua
self.heart_bubble         = Sprite.new(0, 0, BW, BH)
self.heart_bubble.image   = A.heart_bubble
self.heart_bubble.color   = {1.0, 0.55, 0.75, 1}
self.heart_bubble.visible = false
```

In `Customer:serve()`, show it:

```lua
function Customer:serve()
    self.state              = "walking_out"
    self.bubble.visible     = false
    self.heart_bubble.visible = true
end
```

In `Customer:update()`, position it above the head (same as existing bubble), and hide on exit:

```lua
self.heart_bubble.x = self.x - BW / 2
self.heart_bubble.y = self.sprite.y - BH - 4

-- inside the walking_out arrival check:
self.heart_bubble.visible = false
```

In `Customer:draw_bubble()`, draw it:

```lua
if self.heart_bubble.visible then
    self.heart_bubble:draw()
end
```
