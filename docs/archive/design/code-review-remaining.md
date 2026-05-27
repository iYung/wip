## Goal

Fix the 6 remaining items from the code review checklist (`docs/checklists/code-review.md`). These are all code-quality and consistency issues — no new behaviour is introduced.

## Affected files

- `lua/game/scenes/buy_scene.lua` — variable shadowing fix
- `lua/game/scenes/settings_menu.lua` — instance fields moved to `new()`
- `lua/game/scenes/store_scene.lua` — remove per-frame `require`

## What changes

1. **`buy_scene.lua:304`** — `local y = 652` shadows the outer `local y = math.floor(...)` at line 225. Rename to `local hint_y = 652` and update the two references inside the loop body.

2. **`settings_menu.lua:22-27`** — `is_open`, `selected`, `_prev_up`, `_prev_down`, `_prev_confirm`, `_prev_escape` are declared on the class table (shared across all instances). Move them into `new()` as per-instance fields to match the pattern used by every other scene.

3. **`store_scene.lua:402`** — `require("lua/game/assets")` is called inside `_draw_parallax()`, which runs every frame. Add `local A = require("lua/game/assets")` at the top of the file alongside the other requires and remove the per-frame call.

## What stays the same

- No behaviour changes. All fixes are purely structural.
- Public APIs for all scenes remain unchanged.

## Open questions

None — all items are well-specified in the checklist.
