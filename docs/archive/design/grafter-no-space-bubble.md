# Grafter No-Space Bubble

## Goal

When the grafter fails because all slots are full, the no-space indicator should appear
inside a white speech bubble (with tail) — the same visual treatment as the customer's
desired-plant bubble. The existing `grafter_no_space_bubble.png` asset is kept as-is
and drawn inside the bubble container.

## Affected files

- `lua/game/items/grafter.lua` — `draw_bubble()` rewrite only

## What changes

**Code — `Grafter:draw_bubble()`:** Wrap the existing icon in a composited white speech
bubble, the same way `Customer:draw_bubble()` shows the desired-plant icon:

1. Compute box position centred horizontally above the grafter sprite.
2. `love.graphics.setColor(1,1,1,1)` then `UI.draw9(A.speech_bubble, box_x, box_y, BOX_W, BOX_H, BUBBLE_MARGIN)`.
3. Draw `A.speech_bubble_tail` centred below the box.
4. Draw `A.grafter_no_space_bubble` scaled to `IMG_SIZE` and centred inside the box.

Constants to match customer style:
- `PD = 12` (padding inside box)
- `IMG_SIZE = 80`
- `BOX_W = IMG_SIZE + PD * 2` → 104
- `BOX_H = IMG_SIZE + PD * 2` → 104
- `BUBBLE_MARGIN = { top=12, right=12, bottom=12, left=12 }` (same as customer)
- `TAIL_H` = height of `speech_bubble_tail` image (same constant as customer)

The `self.bubble` Sprite is kept for its `visible` flag but no longer drawn directly.

## What stays the same

- `grafter_no_space_bubble.png` — no asset changes.
- Trigger logic: no-space condition, 1.5 s timer, `Sound.play("fail")` — unchanged.
- Positioning anchor: centred horizontally above the grafter sprite.
- `Grafter:draw()` — unchanged.
- All other scenes and items — unchanged.

## Open questions

None.
