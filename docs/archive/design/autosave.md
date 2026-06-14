# Autosave Design

## Goal

Automatically save `GameState` at key gameplay moments in `StoreScene` so progress is not lost if the game crashes or is force-quit. The save is silent — no UI feedback. The existing `love.quit()` save is kept as a final safety net.

## Affected files

- `lua/game/scenes/store_scene.lua` — the only autosave site

## What changes

### Save trigger

One moment in `StoreScene` triggers a write:

**Plant sale** — after `_handle_interact` completes a successful customer serve (currency increments, optional `seen_scripts` key set). Both mutations happen inside the same `if` block; one save after the block captures both.

### Implementation

`StoreScene` will directly require `Save` and `GameState` (both are already used elsewhere in the codebase) and call a module-level helper:

```lua
local function _autosave(gs)
    Save.write(GameState.to_save(gs))
end
```

Called with `_autosave(self.game_state)` at the two points above. No new parameters to `StoreScene.new`, no callback threading.

## What stays the same

- `love.quit()` save in `main.lua` — unchanged, still fires on clean exit
- Settings save (`Save.write_settings`) — unchanged, still in `_on_leave` and `love.quit()`
- `BuyScene` — no autosave added (per spec: StoreScene only)
- `StartScene`, `main.lua` — no changes
- No visual indicator of any kind

## Open questions

None — all answered before writing this doc.
