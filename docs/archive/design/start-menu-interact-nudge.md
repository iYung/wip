## Goal
Move the interact key hint on the start menu 100px to the left.

## Affected files
- `lua/game/scenes/start_scene.lua`

## What changes
The interact key hint (`ki`) is currently centred at x=1200 (line 178). Change the draw x to `1100 - ki_w / 2` so it shifts 100px left.

## What stays the same
- The WASD/arrow key hint at x=950 is untouched.
- All other layout constants (`BTN_X`, `BTN_Y0`, logo positions, credit line) are unchanged.
- No new assets, fonts, or logic.

## Open questions
None.
