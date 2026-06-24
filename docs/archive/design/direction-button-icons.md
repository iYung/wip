# Direction Button Icons

## Goal
In gamepad mode the start screen shows direction labels as unicode arrows (`↑/←/↓/→`). This change applies the same icon treatment already used for interact/pick_up_down/cancel — swapping text for 16×16 sprite icons when a gamepad is active. All 4 directions are shown in the hint row.

## Affected files
- `assets/images/dpad_up.png` — new 16×16 icon
- `assets/images/dpad_down.png` — new 16×16 icon
- `assets/images/dpad_left.png` — new 16×16 icon
- `assets/images/dpad_right.png` — new 16×16 icon
- `lua/game/assets.lua` — register the 4 new images
- `lua/core/input.lua` — add `move_up/down/left/right` entries to `_PAD_ICON_KEYS`
- `lua/game/scenes/start_scene.lua` — replace the single direction text string with 4 individual `make_label` hints in a row

## What changes
- 4 new 16×16 dpad icon PNGs are added to `assets/images/`
- `_PAD_ICON_KEYS` in `lua/core/input.lua` gains entries for all 4 move actions, pointing to the new asset keys (`dpad_up`, `dpad_down`, `dpad_left`, `dpad_right`)
- `lua/game/assets.lua` loads all 4 new images under those keys
- `start_scene.lua` replaces the single concatenated direction text block (lines 167–175) with 4 individual `make_label` hints rendered in a horizontal row centered at x≈950, matching the style of the existing action button hints
- Keyboard mode: each slot shows the key letter as before
- Gamepad mode: each slot shows the corresponding dpad icon

## What stays the same
- The action button hints (interact/pick_up_down/cancel) are untouched
- The direction hint area stays centered at x≈950, y=630
- `make_label` is reused as-is — no changes to that helper
- `key_for` keyboard behavior is unaffected

## Open questions
None — 4 new 16×16 placeholder icons will be generated to match the `btn_a`/`btn_b`/`btn_y` style; user can replace with final art later.
