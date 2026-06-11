## Volume Settings No Arrows Checklist

- [x] Remove `<`/`>` arrows and upsize value font — `lua/game/scenes/settings_menu.lua` — delete the four `printf("<"` / `printf(">"` calls in the SFX and Music volume draw blocks; replace `_font_vol` with `_font_btn` for the percentage value; use `ty` for vertical centering instead of `vty`
