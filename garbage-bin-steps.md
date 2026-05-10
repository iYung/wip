# Garbage Bin + Cashier Changes

Goal: money comes only from selling to customers. The bin disposes of unwanted items for free. Cashier pays face value, not 2×.

---

## Step 1 — Rename Sell Bin → Garbage Bin

- [ ] Rename `lua/game/items/sell_bin.lua` to `garbage_bin.lua`
- [ ] Rename class `SellBin` → `GarbageBin` and field `is_sell_bin` → `is_garbage_bin` throughout
- [ ] Update `self.name` to `"Garbage Bin"`
- [ ] Rename asset key `A.sell_bin` → `A.garbage_bin` in `assets.lua`
- [ ] Rename asset filename `assets/sell_bin.png` → `assets/garbage_bin.png` and update `generate_assets.py`
- [ ] Update `store_scene.lua` require and all references (`is_sell_bin`, `SellBin`)

---

## Step 2 — Bin no longer pays currency

- [ ] Remove currency grant from the garbage bin F-interact block in `store_scene.lua`

In `store_scene.lua`, the F-interact block that detects the garbage bin currently adds currency before discarding the item. Remove the currency grant — just discard.

Current behavior (in `_handle_interact`):
```lua
if player.held_item and player.held_item.sellable ~= false and slot and slot.item and slot.item.is_sell_bin then
    local held = player.held_item
    if held.loaded_plant then
        self.game_state.currency = self.game_state.currency + plant_sell_value(held.loaded_plant)
        held:unload()
    else
        local value = held.stage and plant_sell_value(held) or 0
        self.game_state.currency = self.game_state.currency + value
        player.held_item = nil
    end
    return
end
```

New behavior — discard only, no currency:
```lua
if player.held_item and player.held_item.sellable ~= false and slot and slot.item and slot.item.is_garbage_bin then
    local held = player.held_item
    if held.loaded_plant then
        held:unload()
    else
        player.held_item = nil
    end
    return
end
```

---

## Step 3 — Update context HUD label

- [ ] Change bin HUD label from `F: SELL ($X)` to `F: DISCARD` and remove the value calculation

The HUD currently shows `F: SELL ($X)` when hovering the bin with a sellable item. Change to `F: DISCARD`.

In `_hud_labels`, find the bin branch and replace the label:
```lua
-- old
f_label = "F: SELL ($" .. value .. ")"
-- new
f_label = "F: DISCARD"
```

Remove the `value` calculation in that branch — it's no longer needed.

---

## Step 4 — Remove 2× multiplier from cashier sale

- [ ] Remove `* 2` from the sale value in `_handle_interact`
- [ ] Update the matching HUD label to show the correct value

In `_handle_interact`, the cashier sale currently pays double:
```lua
local value = plant_sell_value(held) * 2
```

Change to face value:
```lua
local value = plant_sell_value(held)
```

The HUD label `F: SELL TO CUSTOMER ($X)` already reads from `plant_sell_value(held) * 2` — update that too:
```lua
-- old
f_label = "F: SELL TO CUSTOMER ($" .. plant_sell_value(held) * 2 .. ")"
-- new
f_label = "F: SELL TO CUSTOMER ($" .. plant_sell_value(held) .. ")"
```
