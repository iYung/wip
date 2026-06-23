## Goal

Record the wall-clock time at which the player starts a brand-new game so it can be used later (analytics, leaderboards, future UI). No display changes in this feature.

## Affected files

- `lua/game/game_state.lua` — add `started_at` field, serialize/deserialize it

## What changes

- `GameState.new()` sets `self.started_at = os.time()` (Unix timestamp, integer seconds).
- `GameState.to_save()` includes `started_at` in the serialized table.
- `GameState.from_save()` reads `started_at` from the save data; defaults to `nil` for old saves that lack it.
- Nothing else changes — no UI, no scene logic, no extra files.

## What stays the same

- "Continue" loads the existing `started_at` from the save file unchanged — it is never overwritten on load.
- All other `GameState` fields and save/load logic are untouched.
- The save file format version stays at `1` (the field is additive and backwards-compatible; old saves load fine with `started_at = nil`).

## Open questions

None.
