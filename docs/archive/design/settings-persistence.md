# Settings Persistence

## Goal

Save and restore user settings (volume, keybinds, fullscreen) across sessions.
Right now `SettingsState` is always created with hardcoded defaults — every launch resets SFX/music to 100 and keybinds to `wasd`/`e`/`f`.

## Affected files

- `lua/game/settings_state.lua` — add `to_save()` and `from_save(data)` methods
- `lua/game/save.lua` — add `Save.write_settings(data)` and `Save.read_settings()` helpers targeting `settings.dat`
- `main.lua` — load settings at startup; write settings on quit and when leaving the settings menu

## What changes

### `settings_state.lua`

Add two methods:

- `SettingsState:to_save()` — returns a plain table: `{ sfx_volume, music_volume, fullscreen, keybinds }`
- `SettingsState.from_save(data)` — constructs a `SettingsState`, copies fields from `data`, calls the real setters so Sound and the window are updated immediately, and returns the object

### `save.lua`

Add two functions alongside the existing `Save.read` / `Save.write`:

- `Save.write_settings(data)` — writes to `settings.dat` using the same serializer
- `Save.read_settings()` — reads and evals `settings.dat`; returns `nil` if missing or corrupt

### `main.lua`

1. At startup, after `SettingsState` is required, call `Save.read_settings()`. If it returns data, use `SettingsState.from_save(data)`; otherwise fall back to `SettingsState.new()`.
2. On quit (`love.quit`), write settings via `Save.write_settings(ss:to_save())`.
3. In `_on_leave` (the callback fired when the player exits the settings menu back to the title), write settings immediately after `_on_save()`.

## What stays the same

- `save.dat` and game-progress persistence are untouched
- The serializer in `save.lua` is reused as-is — no new format
- `SettingsState` constructor (`SettingsState.new()`) keeps its defaults; `from_save` is additive
- Settings menu UI and interaction logic are unchanged

## Open questions

None — user confirmed: separate `settings.dat`, save on quit + on leaving settings menu.
