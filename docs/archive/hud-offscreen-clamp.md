## HUD Offscreen Clamp Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — In `_draw_floating_prompts()`, after computing `bx` and `box_w` for the slot path, add a flip: if `bx + box_w > self.camera.x + config.LOGICAL_W / 2`, set `bx = slot.x + slot.slot_width / 4 - box_w` to mirror the offset to the left of slot center.

- [x] Task B — `tests/test_hud_labels.lua` — Add a test that places the player at the rightmost slot of a store wide enough that the default right-anchor would overflow the screen (camera clamped to right edge), and assert that the computed `bx + box_w` fits within the camera's visible right boundary.
