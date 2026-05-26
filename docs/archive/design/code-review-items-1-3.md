## Goal

Fix two bugs and remove one piece of dead code identified in the code review checklist (items 1–3). No new behaviour is introduced — these are correctness and hygiene changes only.

## Affected files

- `lua/game/player.lua` (line 47)
- `lua/game/scenes/store_scene.lua` (line 73)
- `lua/game/assets.lua` (line 33)

## What changes

**Item 1 — `player.lua:47` — `set_speed_level` drops `level`**

`set_speed_level(level, color)` stores `color` into `self._speed_color` but silently discards `level`. The player has no use for `level` — `gs.speed_level` in `game_state` is the authoritative counter and `buy_scene` manages it exclusively. The player only ever uses `_speed_color` for a draw tint. Fix: rename to `set_speed_color(color)`, drop the `level` param, and update the call site at `buy_scene.lua:118` accordingly.

**Item 2 — `store_scene.lua:73` — extra `slot` arg passed to `BuyScene.new`**

`BuyScene.new` signature is `(game_state, input, scene_manager, store_scene)` — four params. The call at line 73 passes a fifth arg `slot` which Lua silently drops. The slot is not needed by `BuyScene` (it resolves the active slot itself via `gs`). Fix: remove `slot` from the call.

**Item 3 — `assets.lua:33` — `grafter_loaded` image is loaded but never used**

`A.grafter_loaded` is assigned once and referenced nowhere else in the codebase. Fix: delete the line to avoid loading an unused texture at startup.

## What stays the same

- `BuyScene` logic is unchanged — no signature update needed, just the call site.
- `Player` drawing logic and `_speed_color` usage are unchanged.
- `grafter_empty` is kept; only `grafter_loaded` is removed.
- All other assets, game state, and player behaviour are untouched.

## Open questions

None.
