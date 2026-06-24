## In-Game Play Time Checklist

- [x] Task A — `lua/game/game_state.lua` — remove `started_at` from `new()`, `to_save`, and `from_save`; add `play_time = 0` to `new()`, `to_save` (key `play_time`), and `from_save` (default `data.play_time or 0`)
- [x] Task B — `lua/game/scenes/store_scene.lua` — add `gs.play_time = gs.play_time + dt` at the top of `StoreScene:update(dt)`
- [x] Task C — `lua/game/scenes/buy_scene.lua` — in `_confirm`, change `gs.first_idol_at = gs.first_idol_at or os.time()` to `gs.first_idol_at = gs.first_idol_at or gs.play_time`; also add `gs.play_time = gs.play_time + dt` at the top of `BuyScene:update(dt)`
- [x] Task D — `lua/game/scenes/win_scene.lua` — replace the `elapsed` line with `local elapsed = math.floor(gs.first_idol_at)`
- [x] Task E — `tests/test_save.lua` — remove all `started_at` tests; add `play_time` tests: `new()` yields 0, round-trips through `to_save`/`from_save`, old save without field loads as 0
- [x] Task F — `tests/test_win_scene.lua` — remove `ctx.gs.started_at = 1000`; change `ctx.gs.first_idol_at = 1125` to `ctx.gs.first_idol_at = 125` (2m 5s in-game seconds)
