# HUD Box Design

## Goal

Wrap the bottom-left context HUD labels (E/F/HOVER hints) in a rounded box that reuses the existing 9-slice dialogue bubble rendering.

## Affected files

- `lua/game/customer.lua` — source of `draw9` and `BUBBLE_MARGIN`; `draw9` will be extracted from here
- `lua/game/ui.lua` *(new)* — shared UI utility module; will house `draw9` and a `draw_hud_box` helper
- `lua/game/scenes/store_scene.lua` — draws the HUD labels; will call `draw_hud_box`

## What changes

### Extract `draw9` to a shared module

`draw9` is currently a local function inside `customer.lua`. It will be moved to `lua/game/ui.lua` and exported so both `customer.lua` and `store_scene.lua` can require it.

`BUBBLE_MARGIN` stays in `customer.lua` (it is specific to speech bubbles). `lua/game/ui.lua` will define its own margin constant for the HUD box.

### New `draw_hud_box(labels, font)` helper in `lua/game/ui.lua`

Accepts the ordered list of label strings and the current font. Computes:

- `content_w` = widest label string (via `font:getWidth`)
- `content_h` = `#labels * line_height`
- Box position: anchored to the bottom-left corner, 10 px from left, 10 px from bottom
- Draws the 9-slice box (`A.speech_bubble`) around the computed area with consistent padding
- Returns nothing; draws immediately

The box is only drawn when `#labels > 0`.

### Update `StoreScene:draw()`

Replace the bare `love.graphics.print` loop with a call to `ui.draw_hud_box(labels, font)` followed by the existing text draws (so text renders on top of the box).

## What stays the same

- `customer.lua` bubble rendering behaviour is unchanged (just swaps its local `draw9` call for the shared one)
- Label generation logic (`_hud_labels`) is untouched
- No new assets needed — reuses `A.speech_bubble`
- No tail is drawn (this is a static UI panel, not a speech bubble)
- Box is invisible when no labels are active

## Open questions

*None — all resolved before writing this doc.*
