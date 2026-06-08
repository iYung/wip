## Settings Persistence Checklist

- [x] Task A — `lua/game/save.lua` — add `Save.write_settings(data)` and `Save.read_settings()` functions that target `settings.dat` using the existing serializer
- [x] Task B — `lua/game/settings_state.lua` — add `SettingsState:to_save()` returning a plain table of all settings fields, and `SettingsState.from_save(data)` that constructs a new SettingsState from saved data using the real setters so Sound/window state updates immediately
- [x] Task C — `main.lua` — at startup load settings via `Save.read_settings()` and use `SettingsState.from_save()` if data exists, else fall back to `SettingsState.new()`; write settings via `Save.write_settings(ss:to_save())` on quit (`love.quit`) and in `_on_leave` after `_on_save()`
- [x] Task D — `tests/test_settings_persistence.lua` — add tests covering: `to_save` round-trips all fields, `from_save` with missing/corrupt data falls back gracefully, `from_save` calls volume setters so Sound state is updated
