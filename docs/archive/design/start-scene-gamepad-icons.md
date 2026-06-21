## Goal

Replace the text-only button labels in the start scene hint bar with gamepad button PNGs when a controller is active, matching the behaviour already in BuyScene and StoreScene.

## Affected files

- `lua/game/scenes/start_scene.lua` — the only file that needs to change

## What changes

Lines 176–186 of `start_scene.lua` draw three button hints using plain `key_for()` text: pick_up_down (x=1070), interact (x=1150), and cancel (x=1230). In gamepad mode these currently show "[Y]", "[A]", "[B]" as text strings.

The change mirrors the `make_label()` + icon-draw pattern already used in BuyScene (`buy_scene.lua` lines 409–439) and StoreScene:

1. Call `self.input:icon_key_for(action)` for each of the three actions.
2. Build a label that is either:
   - A table `{ icon = "btn_y", text = ": navigate" }` when in gamepad mode, or
   - A plain string like `"Y: navigate"` when on keyboard.
3. Render: if the label is a table, draw the PNG from `A[label.icon]` then `label.text` beside it (icon is 16×16); otherwise just `love.graphics.print` the string.

The movement-key cluster (x=950) has no icon equivalents, so it stays text-only in all modes.

## What stays the same

- All hint positions (x=950/1070/1150/1230, y=630)
- The font, colour, and centering of the movement-key cluster
- Everything else in StartScene (background, menu buttons, credit line)
- No new assets needed — btn_a, btn_b, btn_y PNGs are already loaded in `assets.lua`

## Open questions

None.
