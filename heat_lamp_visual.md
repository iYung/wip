# Heat Lamp Visual in Store Scene

## Goal

When the player has purchased Heat Lamps, show a transparent PNG hanging from the ceiling above the plant slots — one lamp spans **two slot columns**, similar to how `slot.png` tiles across the floor at the bottom of the store. A lamp is only drawn if both slots it covers exist (so an odd trailing slot gets no lamp). Each upgrade tier swaps in a different image (`heat_lamp_1/2/3.png`) so the lamps visually reflect the current level.

---

## Layout Reference

| Element | World Y | Note |
|---------|---------|------|
| Ceiling / wall | 0 | `store_wall.png` drawn from here |
| Heat lamp (target) | ~200–300 | Hang from ceiling, above slot midpoint |
| Slot top | 600 | `SLOT_Y = 30 * U` |
| Slot bottom | 800 | `SLOT_Y + SLOT_HEIGHT` |

The camera is fixed at world y = 440 on a 720-pixel-tall screen, so world y ≈ 80–800 is visible. The lamps should sit clearly in the upper half.

---

## Steps

### 1. Create `assets/heat_lamp_1.png`, `heat_lamp_2.png`, `heat_lamp_3.png`

- Transparent PNGs, roughly **two slot-widths wide (400px)**, however tall fits aesthetically
- Designed to look like they're mounted at the top and hanging down toward the plants
- Each tier should look visually distinct (e.g. tier 1 = dim/single bulb, tier 2 = brighter/more bulbs, tier 3 = full glow/dense)

### 2. Load the assets in `assets.lua`

Add after the existing `try_img` block ([assets.lua:61](lua/game/assets.lua#L61)):

```lua
A.heat_lamps = {}
for lvl = 1, 3 do
    A.heat_lamps[lvl] = try_img("assets/heat_lamp_" .. lvl .. ".png")
end
```

Use `try_img` so the game doesn't crash before the art exists.

### 3. Add `_heat_lamps` drawable in `StoreScene:_setup_store()`

After the `_cashier_floor` block in [store_scene.lua:111](lua/game/scenes/store_scene.lua#L111):

```lua
local gs_ref = gs
self._heat_lamps = {
    draw = function()
        local lvl = gs_ref.growth_level
        if lvl < 1 then return end
        local lamp = A.heat_lamps[lvl]
        if not lamp then return end
        love.graphics.setColor(1, 1, 1, 1)
        local lamp_y = -- choose world y (e.g. 200)
        local sw     = store_ref.slot_width
        local lamp_w = sw * 2
        local scale  = lamp_w / lamp:getWidth()
        local slots  = store_ref.slots
        local i = 1
        while i + 1 <= #slots do
            love.graphics.draw(lamp, slots[i].x, lamp_y, 0, scale, scale)
            i = i + 2
        end
    end
}
```

Decide the exact `lamp_y` once you see the art — target is somewhere in 200–300 world y so it hangs visually above the plants.

### 4. Register the drawable in `StoreScene:on_enter()`

Add to the `drawer:add` block ([store_scene.lua:46-53](lua/game/scenes/store_scene.lua#L46-L53)):

```lua
self.drawer:add(self._heat_lamps, 1.5)
```

Priority 1.5 puts heat lamps in front of the store slots (0) and customer NPC (1) but behind the wall overlay (2) and player (4).

### 5. No refresh needed

The drawable reads `gs.growth_level` live each frame, so upgrading in BuyScene takes effect immediately on the next `StoreScene:draw()`.

---

## Art Spec Summary

| File | Size | Notes |
|------|------|-------|
| `assets/heat_lamp_1.png` | ~400×300px | Transparent bg; tier 1 — dim/minimal |
| `assets/heat_lamp_2.png` | ~400×300px | Transparent bg; tier 2 — mid brightness |
| `assets/heat_lamp_3.png` | ~400×300px | Transparent bg; tier 3 — full glow |
