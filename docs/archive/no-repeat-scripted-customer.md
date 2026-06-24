## No-Repeat Scripted Customer Checklist

- [x] Task A — `lua/game/scenes/store_scene.lua` — add `self._last_script_id = nil` in `on_enter()` alongside the existing `_active_script_key` and `_active_script` initializations (~line 139)
- [x] Task B — `lua/game/scenes/store_scene.lua` — in `_next_customer_cfg()`, after `qualified` is built, filter it to exclude scripts whose `id` matches `self._last_script_id`; use the filtered list if non-empty, otherwise fall through to the generic customer path; set `self._last_script_id = script.id` when a script is selected
