# Checklist: Default Interact Key → Space

- [ ] `lua/game/settings_state.lua` — change `interact="p"` → `interact="space"` in `SettingsState.new()`
- [ ] `lua/game/input.lua` — change `interact = {"p"}` → `interact = {"space"}` in the startup key map
- [ ] `lua/game/scenes/settings_menu.lua` — change four `or "p"` fallback strings → `or "space"` (open snapshot, keybind nav confirm, main nav confirm, keybind sub-confirm)
- [ ] `lua/game/scenes/store_scene.lua` — change `or "p"` fallback in `_hud_labels` → `or "space"`
- [ ] `lua/game/scenes/buy_scene.lua` — change `or "p"` fallback in draw → `or "space"`
