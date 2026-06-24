## Pickup Flicker Fix Checklist

- [x] Task A — `lua/game/player.lua` — add `Player:_snap_held_item()` method that replicates the held-item sprite position math from `Player:update()` (lines 87–92): set `spr.x = self.x - spr.width/2` and `spr.y = self.y - H/2 - spr.height`
- [x] Task B — `lua/game/scenes/store_scene.lua` — in `_handle_pick_up_down()`, call `player:_snap_held_item()` immediately after each assignment that sets `player.held_item` (the pick-up branch at line 419 and the swap branch at line 414)
