## Slot Item Sway Checklist

- [x] Task A — `lua/game/slot.lua` — Add `require("lua/game/shaders/sway")` at the top. Add a local constant `ITEM_SWAY_AMPLITUDE = 0.004`. Change `Slot:draw()` to accept a `sway_time` parameter. Before `self.item:draw()`, if `sway_time` is non-nil and `item.ready ~= true`, call `Sway.apply(sway_time, ITEM_SWAY_AMPLITUDE)`. After `self.item:draw()`, call `Sway.clear()` under the same condition.

- [x] Task B — `lua/game/store.lua` — Change `Store:draw()` to pass `self.sway_time` to each `slot:draw()` call: `slot:draw(self.sway_time)`. No other changes — `self.sway_time` will be nil until StoreScene sets it, which is safe because `Slot:draw()` guards on the nil check.

- [x] Task C — `lua/game/scenes/store_scene.lua` — In `StoreScene:draw()`, immediately before the `self.drawer:draw()` call, add `gs.store.sway_time = self._sway_time`. This writes the accumulated sway time onto the store each frame so `Store:draw()` can forward it to slots.
