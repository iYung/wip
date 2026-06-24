## Goal
Prevent a scripted character from appearing twice in a row within a single play session. Cross-session repeats are fine; no save changes needed.

## Affected files
- `lua/game/scenes/store_scene.lua`

## What changes
- Add `self._last_script_id = nil` alongside the other `_active_script_*` fields in `on_enter()` initialization.
- In `_next_customer_cfg()`, after building `qualified`, filter out entries where `script.id == self._last_script_id`. If the filtered list is non-empty, pick from it. If it's empty (only the last character qualifies), fall through to generic customer.
- When a scripted customer is picked, set `self._last_script_id = script.id`.

## What stays the same
- `_script_cooldowns` (dismiss-based, per `id:chapter` key) — untouched.
- `seen_scripts` (permanent save) — untouched.
- Generic customer fallback path — untouched; also now used when the only qualified script is the last-seen character.

## Open questions
None.
