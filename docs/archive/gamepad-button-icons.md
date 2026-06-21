## Gamepad Button Icons Checklist

- [x] Task A — `assets/images/btn_a.png`, `btn_b.png`, `btn_y.png` — Generate three 16×16 PNG icons using a Python script (Pillow). Each is a filled circle with a white letter centered on it. Colors: A = green (80,160,80), B = red (200,70,70), Y = yellow (200,170,50). Background is transparent. Write the script inline (don't save it), run it, confirm the three files exist.

- [x] Task B — `lua/game/assets.lua` — Load the three new button icons. Find where other small UI images are loaded (e.g. `coin`, `speech_bubble`) and add `btn_a`, `btn_b`, `btn_y` using the same `img()` pattern pointing to `assets/images/btn_a.png` etc.

- [x] Task C — `lua/core/input.lua` — Add a `_PAD_ICON_KEYS` table (parallel to `_PAD_LABELS`) that maps `interact → "btn_a"`, `pick_up_down → "btn_y"`, `cancel → "btn_b"`. Add method `Input:icon_key_for(action)` that returns `_PAD_ICON_KEYS[action]` if `self._mode == "gamepad"`, else nil. Do not change `_PAD_LABELS` or `key_for`.

- [x] Task D — `lua/game/ui.lua` — Update `draw_hud_box` so it measures entry widths correctly when entries are `{icon, text}` tables. Add a local constant `ICON_SIZE = 16` and a local helper `entry_width(entry, font)` that returns `font:getWidth(entry)` for plain strings, or `ICON_SIZE + 2 + font:getWidth(entry.text)` for tables. Replace the inline `font:getWidth(label)` call in the width loop with `entry_width(label, font)`. No other changes to this file.

- [x] Task E — `lua/game/scenes/store_scene.lua` — Two changes in this file (do both together):
  1. In `_hud_labels()`: replace the three `key .. ": ACTION"` string concatenations for `f_label`, `up_label`, and `down_label` with a local helper `make_label(icon_key, key_text, action_text)` that returns `{icon=icon_key, text=": "..action_text}` when `icon_key` is non-nil, else `key_text..": "..action_text`. Call `self.input:icon_key_for("interact")`, `icon_key_for("pick_up_down")`, and `icon_key_for("cancel")` to get the icon keys. `slot_label` stays a plain string.
  2. In the draw loop (lines ~580-586): replace the single `love.graphics.print(label, 10+14, y)` with logic that checks `type(entry) == "table" and entry.icon`. If so: draw `A[entry.icon]` at `(10+14, floor(y+(20-16)/2))` with color `(1,1,1,1)`, then print `entry.text` at `(10+14+16+2, y)` with color `(0,0,0,1)`. Otherwise print the plain string as before. Add `local A = require("lua/game/assets")` at the top of the file if not already present. **Depends on Tasks C and D being complete.**
