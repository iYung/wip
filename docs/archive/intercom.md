## Intercom Checklist

- [x] Task A — `assets/intercom.png` — create a placeholder PNG (solid color rectangle, 120×120) to stand in for the intercom sprite until real art is drawn

- [x] Task B — `lua/game/items/intercom.lua` — create the Intercom item class: `Intercom.new(customer_getter)`, `carriable = true`, `name = "Intercom"`, `set_customer_getter(fn)` method, and `draw_bubble()` that mirrors the customer's plant request bubble (same 9-slice box + tail + plant image from `Customer:draw_bubble()`'s done-talking branch) when `customer.bubble.visible` and `customer.done_talking` and `customer.state ~= "talking_after"`; position bubble above the intercom sprite

- [x] Task C — `lua/game/assets.lua` — load `A.intercom = img("assets/intercom.png")`

- [x] Task D — `lua/game/scenes/buy_scene.lua` — add `require` for Intercom at the top; add `{ label = "Intercom", description = "See the plant order\nfrom anywhere.", cost = 50, kind = "tool_intercom", image = A.intercom }` to CATALOGUE; handle `kind == "tool_intercom"` in `_confirm()`: create `Intercom.new(function() return scene._customer end)` (where `scene = self.store_scene`), assign to `gs.player.held_item`, play `"shop_buy"`, switch to store scene

- [x] Task E — `lua/game/game_state.lua` — add `require` for Intercom; handle intercom in `_item_to_data` (`{ type = "intercom" }`) and `_item_from_data` (`Intercom.new(nil)`)

- [x] Task F — `lua/game/scenes/store_scene.lua` — add `require` for Intercom; add `StoreScene:_wire_intercom()` that iterates all slots and `gs.player.held_item`, calling `item:set_customer_getter(function() return self._customer end)` on any item with `name == "Intercom"`; call `_wire_intercom()` at the end of `_setup_store()` when `_from_save` is true
