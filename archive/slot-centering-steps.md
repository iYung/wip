# Slot Item Centering

Goal: center items both horizontally and vertically within their slot.

Current positioning in `Slot:update()`:
- `spr.x = self.x + 3 * U` — 60px from left, but items are 120px wide in a 120px slot, so they should start at 0 offset
- `spr.y = self.y + 2 * U` — 40px from top, which is correct: (200 - 120) / 2 = 40

---

## Step 1 — Center items in `Slot:update()`

- [ ] Replace hardcoded offsets with centered calculation using `spr.width` and `spr.height`

In `slot.lua`, change the item positioning block:

```lua
-- old
spr.x = self.x + 3 * U
spr.y = self.y + 2 * U

-- new
spr.x = self.x + (self.slot_width - spr.width)  / 2
spr.y = self.y + (SLOT_HEIGHT     - spr.height) / 2
```

`spr.width` and `spr.height` come from `Sprite.new(x, y, w, h)` so they reflect each item's actual size.
