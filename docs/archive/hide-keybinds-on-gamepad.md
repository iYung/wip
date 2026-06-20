## Hide Keybinds on Gamepad Checklist

- [x] Task A — `lua/game/scenes/settings_menu.lua` — Add `mode` parameter to `_visible_items(opaque, mode)` and filter out item 4 ("Keybinds") when `mode == "gamepad"`. Update all three call sites (`update()` and `draw()`) to pass `self._input._mode`.
