# Start Menu Button Hints

## Goal

The start menu's bottom hint bar only shows two hints: movement keys (w/a/s/d) and the interact key. Add the other two action keys — cancel and pick_up_down — as text hints to the left and right of the interact hint, matching the existing text style.

## Affected files

- `lua/game/scenes/start_scene.lua` — draw() method, hint bar section (lines 166–178)

## What changes

- The hint bar gains two additional key labels flanking the existing interact label.
- Layout (left → right): pick_up_down key | interact key | cancel key
- Each label is drawn the same way the interact label is currently drawn: `input:key_for(action)` → text centered at its x position.
- No action is wired up for cancel or pick_up_down in `StartScene:update()` — these are display-only hints for now.
- The three keys are spaced evenly across the bottom-right area (roughly x=1060, x=1150, x=1240 at y=630).

## What stays the same

- `input:key_for()` already returns the correct text for both keyboard ("i", "o") and gamepad ("[B]", "[Y]") modes — no input.lua changes needed.
- The movement-key hint at x=950 is untouched.
- No PNG icon rendering — text only, matching the existing interact hint style.
- No new functionality added to the start scene update loop.

## Open questions

None.
