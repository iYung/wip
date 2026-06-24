## Goal

Fix a one-frame visual flicker when the grafter clones a plant: the new plant briefly appears at the top of the screen before snapping to the correct shelf position.

## Affected files

- `lua/game/items/grafter.lua` — where the new plant is spawned

## What changes

**Root cause:** In `StoreScene:update()`, `store:update()` runs first. This calls `slot:update(dt)` on every slot, which positions each slot item's sprite to the correct world coordinates. Input handling fires afterward. When `Grafter:interact()` places `Plant.new()` into `best_slot.item`, the new plant's sprite is at `(0, 0)`. Since `slot:update()` already ran this frame, the sprite won't be repositioned until the next frame — but `slot:draw()` still runs this frame, showing the plant at `(0, 0)` (the top of the world).

**Fix:** After placing the new plant in `best_slot.item`, call `best_slot:update(0)` immediately. This re-runs the slot's positioning logic (setting `spr.x`/`spr.y`) with `dt=0` so no growth timers advance. The sprite reaches its correct position before `draw()` runs this frame.

## What stays the same

- All game logic (clone type, source plant reset, nearest-slot selection, no-space bubble) is unchanged.
- `Slot:update()` and `Plant:update()` are unchanged — only the grafter interact calls `best_slot:update(0)` as a one-time positioning step.
- No other item spawning paths are affected; the grafter is the only place a brand-new item is created mid-game into a slot after that slot's update has already run.

## Open questions

None.
