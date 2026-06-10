## Goal

Change the default keybinds for `pick_up_down` (pick up / put down) and `interact` from **E / F** to **O / P**.

## Affected files

- `lua/game/settings_state.lua` — canonical default keybind table
- `lua/game/input.lua` — hardcoded fallback defaults used when no settings are loaded
- `lua/game/scenes/settings_menu.lua` — several `or "e"` / `or "f"` guard fallbacks
- `lua/game/scenes/store_scene.lua` — HUD display fallback strings
- `lua/game/scenes/buy_scene.lua` — HUD display fallback strings
- `tests/test_hud_labels.lua` — hardcodes `{"e"}` / `{"f"}` in the input map
- `web/controls.js` — on-screen buttons dispatch `e`/`KeyE` and `f`/`KeyF`; labels, class names, and key codes all hardcoded

## What changes

| Location | Old | New |
|---|---|---|
| `settings_state.lua:11` | `pick_up_down="e", interact="f"` | `pick_up_down="o", interact="p"` |
| `input.lua:8-9` | `pick_up_down={"e"}, interact={"f"}` | `pick_up_down={"o"}, interact={"p"}` |
| `settings_menu.lua` (5 guard fallbacks) | `or "e"` / `or "f"` | `or "o"` / `or "p"` |
| `store_scene.lua:446-447` | `or "e"`, `or "f"` | `or "o"`, `or "p"` |
| `buy_scene.lua:404-405` | `or "f"`, `or "e"` | `or "p"`, `or "o"` |
| `tests/test_hud_labels.lua:13` | `{"e"}`, `{"f"}` | `{"o"}`, `{"p"}` |
| `web/controls.js:185-193` | `btn-e`/`"E"`/`KeyE`, `btn-f`/`"F"`/`KeyF` | `btn-o`/`"O"`/`KeyO`, `btn-p`/`"P"`/`KeyP` |

The action names (`pick_up_down`, `interact`) and all game logic are untouched — only the default letter values change.

## What stays the same

- Action names and all keybind infrastructure
- Player-configured keybinds (loaded from `settings.dat`) are unaffected; only fresh installs or resets see the new defaults
- All other default keys (WASD)
- Test logic — tests use action names, not raw key letters (except the one noted above)

## Open questions

None.
