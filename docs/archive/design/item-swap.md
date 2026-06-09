# Item Swap Design

## Goal

Two related improvements to the bottom-left HUD and pick-up/put-down logic:

1. **Item swap:** When the player is holding an item and presses pick-up/put-down (E by default) while hovering a slot that also contains a carriable item, swap the two items instead of doing nothing. The HUD should show `<key>: SWAP WITH <HELD ITEM>`.

2. **Dynamic key labels:** All HUD labels currently hardcode "E:" and "F:". They should display the actual bound key so remapped controls are reflected correctly.

## Affected files

- `lua/core/input.lua` — add `key_for(action)` helper
- `lua/game/scenes/store_scene.lua` — `_handle_pick_up_down()` and `_hud_labels()`
- `tests/test_ui.lua` — add tests for swap label and dynamic key label

## What changes

### `lua/core/input.lua`

Add a `key_for(action)` method that returns the first bound key string for an action, or `nil` if unbound:

```lua
function Input:key_for(action)
    local keys = self._map[action]
    return keys and keys[1]
end
```

### `_handle_pick_up_down()` in `store_scene.lua` (line 359)

Add a swap arm to the existing `if player.held_item` branch:

```lua
if player.held_item then
    if slot and not slot.item then          -- existing: put down
        ...
    elseif slot and slot.item and slot.item.carriable then   -- NEW: swap
        local tmp        = player.held_item
        player.held_item = slot.item
        slot.item        = tmp
        Sound.play("pick_up")
    end
else
    ...                                     -- existing: pick up
end
```

### `_hud_labels()` in `store_scene.lua` (line 434)

Replace every hardcoded `"E:"` / `"F:"` prefix with dynamic lookups:

```lua
local e_key = (self.input:key_for("pick_up_down") or "e"):upper()
local f_key = (self.input:key_for("interact")     or "f"):upper()
```

Then substitute `e_key` and `f_key` throughout all label strings. Also add the new swap case to the `e_label` block:

```lua
elseif held and slot_item and slot_item.carriable then
    e_label = e_key .. ": SWAP WITH " .. held.name:upper()
```

## What stays the same

- All existing pick-up, put-down, and dismiss logic is untouched.
- Swap only triggers when the hovered item is `carriable`.
- F-key label logic (sell, water, clone, discard, etc.) is unchanged beyond the key prefix.
- Sound system, GameState, Save — no changes.

## Open questions

None.
