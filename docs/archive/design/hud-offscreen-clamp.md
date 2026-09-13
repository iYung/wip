# Design: HUD Floating Prompt Off-Screen Clamp

## Goal

Prevent the floating prompt HUD box from rendering outside the visible screen when the player is standing at the rightmost store slot.

## Affected files

- `lua/game/scenes/store_scene.lua` — `_draw_floating_prompts()` (lines ~622–651)

## What changes

The prompt box is currently anchored so its left edge sits `slot_width/4` to the right of slot center:
```lua
bx = slot.x + slot.slot_width * 3 / 4
```

When the box would overflow the camera's right edge, flip it symmetrically so its right edge sits `slot_width/4` to the left of slot center:
```lua
local cam_right = self.camera.x + config.LOGICAL_W / 2
if bx + box_w > cam_right then
    bx = slot.x + slot.slot_width / 4 - box_w
end
```

No clamping — a clean flip to the mirrored position.

## What stays the same

- All HUD label content and ordering
- `by` (vertical position) unchanged
- The customer-side path (`player.x < 0`) unchanged
- Everything else in the scene

## Open questions

None — the coordinate system and camera clamping are clear from the code.
