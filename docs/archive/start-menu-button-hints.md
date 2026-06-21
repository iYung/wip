## Start Menu Button Hints Checklist

- [x] Task A — `lua/game/scenes/start_scene.lua` — In `draw()`, replace the single interact-key hint (lines 176–178) with three horizontally spaced labels: pick_up_down key (~x=1060), interact key (~x=1150), cancel key (~x=1240), all at y=630. Use `input:key_for(action)` for each, centered on its x position, in the same black font and style as the existing interact hint.
