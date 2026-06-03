## Goal
Split each settings row that currently shows a label and value on the same bar into two side-by-side bars: label bar on the left, value bar on the right. Applies to volume items on the main settings screen and action/key rows on the keybinds subscreen.

## Affected files
- `lua/game/scenes/settings_menu.lua` — all drawing logic + layout constants

## What changes

### Layout constants
Add:
- `LABEL_W = 180` — width of the label bar (px)
- `VAL_W = 110` — width of the value bar (px)
- `BAR_GAP = 10` — horizontal gap between the two bars
- `LABEL_SX = LABEL_W / BTN_W` — horizontal scale for label bar image (≈0.6)
- `VAL_SX = VAL_W / BTN_W` — horizontal scale for value bar image (≈0.367)

The combined span `LABEL_W + BAR_GAP + VAL_W = 300 = BTN_W`, so the pair stays centered the same way as the current single bar.

### Main settings draw (volume rows, i==2 and i==3)
Before (one bar):
```
[    SFX Volume        < 50% >    ]
```
After (two bars):
```
[  SFX Volume  ] [ ◄ 50% ► ]
```
- Draw `menu_btn` / `menu_btn_selected` scaled to `LABEL_W` for the label bar at `BTN_X`
- Draw `menu_btn` / `menu_btn_selected` scaled to `VAL_W` for the value bar at `BTN_X + LABEL_W + BAR_GAP`
- Both bars use the selected image when the item is selected
- Label text: `"SFX Volume"` / `"Music Volume"` — centered in label bar
- Value bar: draw `A.arrow_left` image on the left edge, `A.arrow_right` image on the right edge, percentage text centered between them; arrows scaled to fit `BTN_H` (60px natural → ~54px)
- Replace the old `< N% >` text approach entirely

### Keybinds subscreen draw
Before (one bar):
```
[  move up              [W]  ]
```
After (two bars):
```
[  move up  ]          [ [W] ]
```
- Same split: label bar at `BTN_X`, value bar at `BTN_X + LABEL_W + BAR_GAP`
- Both bars use the selected image when that row is selected
- Action label centered in label bar; key binding centered in value bar (no brackets — plain `KEY` not `[KEY]`)
- The "Return" row at the bottom stays as a single full-width bar (centered, no split)

### Fullscreen / Window row (i==1)
No change — it's a toggle with a single centered label; no split needed.

### Other rows (Keybinds, Exit Settings, Leave Game)
No change — single centered bars.

## What stays the same
- All input/update logic (left/right for volume, key capture for keybinds) — untouched
- BTN_X, BTN_GAP, BTN_H, font, background drawing — untouched
- Number of items and their positions along the vertical axis — untouched
- The button images themselves — scaled horizontally, not replaced

## Open questions
- Arrows confirmed: use `A.arrow_left` / `A.arrow_right` (60×60 from buy scene) for the volume value bar, scaled to BTN_H.
