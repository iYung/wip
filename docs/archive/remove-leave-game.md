## Remove Leave Game Checklist

- [ ] Task A — `lua/game/scenes/settings_menu.lua` — In `_visible_items(opaque, mode)`, add `not (opaque and i == 7)` to the filter condition so item 7 ("Leave Game") is hidden when the menu is opened from the start screen (`opaque=true`), but still visible in-game (`opaque=false`) where it shows as "Main Menu"

- [ ] Task B — `tests/test_settings_menu.lua` — Update navigation wrap tests that assume 7 visible items when menu is opened without `opaque=true`: "up from 1 wraps to 7" should now wrap to 6, and the "7 downs from 1 wraps back to 1" test should now use 6 downs. Test 15 ("Leave Game calls quit") is unaffected since it opens the menu without opaque.
