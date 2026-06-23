## Game Start Time Checklist

- [x] Task A — `lua/game/game_state.lua` — add `self.started_at = os.time()` in `GameState.new()`, include `started_at` in `to_save()`, and read it back (defaulting to `nil`) in `from_save()`
