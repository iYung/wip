## Goal

Replace `os.time()` wall-clock measurements with accumulated in-game `dt` time so that
AFK, pausing, or closing the game does not inflate the "You bought the idol in X"
display on the Win Scene.

## Affected files

- `lua/game/game_state.lua`
- `lua/game/scenes/store_scene.lua`
- `lua/game/scenes/buy_scene.lua`
- `lua/game/scenes/win_scene.lua`
- `tests/test_save.lua`
- `tests/test_win_scene.lua`

## What changes

**`GameState`**
- Remove `started_at` entirely (was `os.time()`; no longer used anywhere).
- Add `play_time = 0`: accumulated in-game seconds, incremented by `dt` each frame,
  persisted in save/load (defaults to `0` on old saves).
- `first_idol_at` keeps its name but changes meaning: was a Unix epoch, now stores the
  value of `gs.play_time` at the moment of first idol purchase.

**`StoreScene:update(dt)` and `BuyScene:update(dt)`**
- Add `gs.play_time = gs.play_time + dt` so all time in both scenes accrues.

**`BuyScene._confirm` (golden_idol branch)**
- Change `gs.first_idol_at = gs.first_idol_at or os.time()`
  to    `gs.first_idol_at = gs.first_idol_at or gs.play_time`.

**`win_scene.lua`**
- Replace the `first_idol_at - started_at` calculation with
  `local elapsed = math.floor(gs.first_idol_at)`.
  Since `play_time` starts at 0 for every new game, `first_idol_at` is already the
  elapsed in-game duration — no subtraction needed.

**Tests**
- `test_save.lua`: remove all `started_at` tests; add `play_time` round-trip tests
  (`new()` → 0, persists through save/load, old save without field defaults to 0).
- `test_win_scene.lua`: remove `started_at` setup; set `first_idol_at` to a plain
  in-game duration (e.g. 125 for 2m 5s).

## What stays the same

- `first_idol_at = nil` on new game.
- Save format version stays at 1 (both changes are backward-compatible with `or`
  defaults).
- All other `GameState` fields, scenes, and tests are untouched.

## Open questions

None.
