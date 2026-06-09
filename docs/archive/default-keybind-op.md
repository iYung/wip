## Default Keybind O/P Checklist

- [x] Task 1 — `lua/game/settings_state.lua` — change default keybinds: `pick_up_down="e"` → `"o"` and `interact="f"` → `"p"` on line 11
- [x] Task 2 — `lua/game/input.lua` — change hardcoded fallback defaults: `pick_up_down={"e"}` → `{"o"}` and `interact={"f"}` → `{"p"}` on lines 8-9
- [x] Task 3 — `lua/game/scenes/settings_menu.lua` — update all `or "e"` nil-guard fallbacks to `or "o"` and all `or "f"` to `or "p"` (5 occurrences on lines 97, 98, 121, 122, 163, 164, 229, 230)
- [x] Task 4 — `lua/game/scenes/store_scene.lua` — update HUD display fallback strings on lines 446-447: `or "e"` → `or "o"` and `or "f"` → `or "p"`
- [x] Task 5 — `lua/game/scenes/buy_scene.lua` — update HUD display fallback strings on lines 404-405: `or "f"` → `or "p"` and `or "e"` → `or "o"`
- [x] Task 6 — `tests/test_hud_labels.lua` — update hardcoded input map on line 13: `{"e"}` → `{"o"}` and `{"f"}` → `{"p"}`
- [x] Task 7 — `web/controls.js` — update on-screen buttons: change `btn-e`/`"E"`/`'e'`/`'KeyE'` → `btn-o`/`"O"`/`'o'`/`'KeyO'` and `btn-f`/`"F"`/`'f'`/`'KeyF'` → `btn-p`/`"P"`/`'p'`/`'KeyP'` on lines 185-193
