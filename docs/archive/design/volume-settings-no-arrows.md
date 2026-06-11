## Goal
Remove the `<` and `>` arrow characters from the SFX Volume and Music Volume rows in the settings menu, and render the percentage value at the same font size as the label text.

## Affected files
- `lua/game/scenes/settings_menu.lua`

## What changes
- The `<` and `>` `love.graphics.printf` calls on the value bar (lines 364–365 and 378–379) are deleted.
- The percentage value (`tostring(vol) .. "%"`) switches from `_font_vol` (size 15) to `_font_btn` (size 22), matching the label text.
- The vertical centering offset `vty` for the value bar recalculates against `_font_btn` height instead of `_font_vol` height (i.e. it just reuses `ty`, the same `y` offset used by the label).
- `_font_vol` and the `ARROW_PAD` constant are no longer used in the volume draw path (they remain in the file for the keybinds "UNBOUND" label, which still uses `_font_vol`).

## What stays the same
- Left/right key handling to increment/decrement volume is unchanged.
- The two-bar layout (label bar + value bar) is unchanged.
- `_font_vol` is kept because the keybinds subscreen still uses it for the "UNBOUND" label.
- All other settings rows are unchanged.

## Open questions
None.
