## Scene Controls Unification Checklist

- [x] Remove `menu_confirm` from `lua/game/input.lua` — it was a 7th undocumented action that got wiped from the input map on every rebind save
- [x] Update `lua/game/scenes/start_scene.lua` — replace `input:pressed("menu_confirm")` with `input:pressed("interact") or input:pressed("pick_up_down")` so both confirm buttons work on the start screen
- [x] Update `lua/game/scenes/settings_menu.lua` `open()` snapshot — replace hardcoded `"w"/"s"/"a"/"d"/"e"/"f"` with `keybinds.*` reads so the ghost-input prevention matches actual navigation keys
- [x] Update `lua/game/scenes/settings_menu.lua` main menu `update()` — same fix as above for the live polling block
