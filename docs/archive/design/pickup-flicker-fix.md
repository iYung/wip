# pickup-flicker-fix

## Goal

Fix a one-frame flicker when picking up (or swapping) an item, where the item briefly appears at the slot position instead of the held position above the player's head.

## What causes it

`StoreScene:update()` runs in this order each frame:

```
1. gs.store:update()          -- positions item sprite at slot coordinates
2. gs.player:update()         -- updates held_item sprite position (but held_item is nil here on the pickup frame)
3. _handle_pick_up_down()     -- assigns player.held_item = slot.item
4. [draw phase]               -- item drawn at stale slot coords
```

On the pickup frame, `player:update()` runs while `held_item` is still `nil`, so it never repositions the sprite. Then `_handle_pick_up_down()` assigns the item to `held_item` — but the sprite's `x/y` are still at the slot position. The draw phase then renders the item at the wrong place for exactly one frame.

The same issue affects the swap case (`held ↔ slot`): the newly-grabbed item also has a stale position.

## What changes

Add `Player:_snap_held_item()` — a small helper that does the same position math as the existing block in `Player:update()` (lines 87–92). Call it from `StoreScene:_handle_pick_up_down()` after every assignment that puts something into `player.held_item`.

```lua
-- player.lua
function Player:_snap_held_item()
    if self.held_item and self.held_item.sprite then
        local spr = self.held_item.sprite
        spr.x = self.x - spr.width  / 2
        spr.y = self.y - H / 2 - spr.height
    end
end
```

Call sites in `_handle_pick_up_down()`:
- after `player.held_item = slot.item` (pick up)
- after `player.held_item = slot.item` (swap — the tmp-swap branch)

## What stays the same

- The overall update order in `StoreScene:update()` is unchanged.
- `Player:update()` keeps its own position block (it still runs every frame to track the player as they move).
- No changes to draw priorities, slot logic, or any other scene.

## Affected files

- `lua/game/player.lua` — add `_snap_held_item()`
- `lua/game/scenes/store_scene.lua` — call `player:_snap_held_item()` in `_handle_pick_up_down()`

## Open questions

None — cause and fix are unambiguous.
