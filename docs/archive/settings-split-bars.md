## Settings Split Bars Checklist

- [x] Task A — `lua/game/scenes/settings_menu.lua` — Add layout constants `LABEL_W = 180`, `VAL_W = 110`, `BAR_GAP = 10`, and precompute `LABEL_SX` / `VAL_SX` as the horizontal scale factors (e.g. `LABEL_SX = LABEL_W / BTN_W`). Load `A.arrow_left` and `A.arrow_right` from `lua/game/assets.lua` in `SettingsMenu.new`.

- [x] Task B — `lua/game/scenes/settings_menu.lua` — Redraw the volume rows (i==2 and i==3) in the main settings `draw()`: replace the single bar with a label bar (scaled to `LABEL_W`) at `BTN_X` and a value bar (scaled to `VAL_W`) at `BTN_X + LABEL_W + BAR_GAP`. Both use selected image when that item is selected. Label bar shows centered text ("SFX Volume" / "Music Volume"). Value bar shows `A.arrow_left` on its left edge, `A.arrow_right` on its right edge (both scaled to `BTN_H`), and the percentage text centered between them.

- [x] Task C — `lua/game/scenes/settings_menu.lua` — Redraw the keybind action rows in the keybinds subscreen `draw()`: replace each single bar with the same label/value split. Label bar shows the action label centered; value bar shows the key name centered without brackets (plain `KEY`, not `[KEY]`; capturing state shows `press a key` centered). The "Return" row stays as a single full-width centered bar.
