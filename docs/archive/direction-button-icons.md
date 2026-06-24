## Direction Button Icons Checklist

- [x] Task A — `assets/images/dpad_up.png`, `dpad_down.png`, `dpad_left.png`, `dpad_right.png` — generate 4 new 16×16 PNG icon files using Python (PIL/Pillow) to match the size of `btn_a.png`; simple arrow shapes on transparent background
- [x] Task B — `lua/game/assets.lua` — register the 4 new images: `A.dpad_up`, `A.dpad_down`, `A.dpad_left`, `A.dpad_right` each loaded with `img("assets/images/dpad_XYZ.png")`
- [x] Task C — `lua/core/input.lua` — add `move_up = "dpad_up"`, `move_down = "dpad_down"`, `move_left = "dpad_left"`, `move_right = "dpad_right"` entries to `_PAD_ICON_KEYS`
- [x] Task D — `lua/game/scenes/start_scene.lua` — replace lines 167–175 (the single concatenated direction text string `ku/kl/kd/kr`) with 4 individual entries in the `hints` table using `make_label("move_up")` etc., spaced in a horizontal row centered at x≈950
