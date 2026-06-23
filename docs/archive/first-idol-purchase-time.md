## First Idol Purchase Time Checklist

- [x] Task A — `lua/game/game_state.lua` — add `first_idol_at = nil` in `GameState.new()`; serialize in `to_save()` as `first_idol_at = gs.first_idol_at`; restore in `from_save()` as `self.first_idol_at = data.first_idol_at`
- [x] Task B — `lua/game/scenes/buy_scene.lua` — in `_confirm()`, inside the `kind == "golden_idol"` branch, add `gs.first_idol_at = gs.first_idol_at or os.time()` before the `Sound.play` line
- [x] Task C — `tests/test_save.lua` — add three tests: (1) new `GameState` has `first_idol_at == nil`, (2) `first_idol_at` round-trips through `to_save`/`from_save`, (3) old save without `first_idol_at` loads with nil
- [x] Task D — `architecture.md` — add `first_idol_at` to the Shared state bullet under GameState
