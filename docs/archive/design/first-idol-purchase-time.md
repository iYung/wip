## Goal
Record the timestamp of the first Golden Idol purchase in `GameState`, mirroring how `started_at` records the new-game time.

## Affected files
- `lua/game/game_state.lua` — add `first_idol_at` field; serialize/deserialize it
- `lua/game/scenes/buy_scene.lua` — set `first_idol_at` on the first idol purchase
- `tests/test_save.lua` — add round-trip and backwards-compat tests
- `architecture.md` — document the new field under Shared state

## What changes
- `GameState.new()` initialises `self.first_idol_at = nil`.
- `GameState.to_save()` serialises `first_idol_at = gs.first_idol_at`.
- `GameState.from_save()` restores `self.first_idol_at = data.first_idol_at` (nil-safe, same as `started_at`).
- `BuyScene:_confirm()`, inside the `kind == "golden_idol"` branch, adds:
  `gs.first_idol_at = gs.first_idol_at or os.time()` — records only the first purchase.

## What stays the same
- `started_at` is untouched.
- Golden Idol purchase flow (cost check, `held_item` assignment, scene switch) is unchanged.
- Old saves without `first_idol_at` load with `nil` — no migration needed.

## Open questions
_(none)_
