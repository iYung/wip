## Autosave Checklist

- [x] Add autosave after plant sale — `lua/game/scenes/store_scene.lua` — require `Save` and `GameState` at the top of the file, add a module-level `_autosave(gs)` helper that calls `Save.write(GameState.to_save(gs))`, then call it at the end of the successful-serve block in `_handle_interact` (after currency is added, held item cleared, and seen_scripts optionally updated)
