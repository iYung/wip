## Goal

Add an **Intercom** item purchasable from the PC store. When placed in a slot (or held), the intercom displays the current customer's plant request bubble so the player can see what plant type is needed without walking to the cashier zone.

## Affected files

- `assets/intercom.png` — new placeholder art asset (needs artist pass)
- `lua/game/items/intercom.lua` — new item class
- `lua/game/assets.lua` — load `A.intercom`
- `lua/game/scenes/buy_scene.lua` — add intercom to CATALOGUE; handle `kind = "tool_intercom"` in `_confirm()`
- `lua/game/game_state.lua` — serialize/deserialize intercom in `_item_to_data` / `_item_from_data`
- `lua/game/scenes/store_scene.lua` — add `_wire_intercom()` (rewires customer getter on load); call from `_setup_store()` when `_from_save`

## What changes

### New item: Intercom

`Intercom.new(customer_getter)` — `customer_getter` is a zero-arg function returning the active `Customer` object.

Properties:
- `carriable = true` (can be picked up and put down into any slot)
- `name = "Intercom"` (default `sellable = true` — can be discarded in the garbage bin)

`Intercom:draw_bubble()`:
- Calls `customer_getter()` to get the current customer
- Shows the plant bubble only when the customer's own plant bubble would be visible: `customer.bubble.visible == true` and `customer.done_talking == true` and `customer.state ~= "talking_after"`
- Draws the same 9-slice speech-bubble box + tail + plant image that `Customer:draw_bubble()` draws in its "done talking" branch, positioned above the intercom sprite

### Buy scene

Add a new `CATALOGUE` entry:
```lua
{ label = "Intercom", description = "See the plant order\nfrom anywhere.", cost = 50, kind = "tool_intercom", image = A.intercom }
```

In `_confirm()`, handle `kind == "tool_intercom"`:
```lua
local scene = self.store_scene
gs.player.held_item = Intercom.new(function() return scene._customer end)
Sound.play("shop_buy")
self.scene_manager:switch(self.store_scene)
```

### Save / load

`_item_to_data`: intercom → `{ type = "intercom" }`

`_item_from_data`: `type == "intercom"` → `Intercom.new(nil)` (getter is nil until wired)

`StoreScene:_wire_intercom()` — iterates all slots and `gs.player.held_item`; for any item with `name == "Intercom"`, calls `item:set_customer_getter(function() return self._customer end)`. Called at the end of `_setup_store()` when `_from_save` is true.

The intercom needs a `set_customer_getter(fn)` method that assigns `self._customer_getter`.

## What stays the same

- Customer drawing logic in `customer.lua` is untouched
- `Store:draw_bubbles()` already calls `draw_bubble()` on any slot item that has it — no changes needed
- `Player:draw()` already calls `held_item:draw_bubble()` — no changes needed
- The cashier zone pick-up / dismiss logic in `StoreScene` is untouched

## Open questions

- **Art**: `intercom.png` will be a placeholder (solid-color rectangle or simple shape) until real art is drawn.
