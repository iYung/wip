# Code Cleanup

## Steps

### 1. Fix grafter timer reset bug — `lua/game/items/grafter.lua:35`

`plant.cooldown = ...` writes to a nonexistent field. Plant stores its timer as `_cooldown` (a Timer object). After grafting, the timer is never reset, so the original plant can become ready almost immediately on the next frame.

**Verify:** Confirm `plant._cooldown` is the real field and `plant.cooldown` is never defined:
```
grep -n "cooldown" lua/game/items/plant.lua
```
Expect `_cooldown` throughout, no bare `cooldown` field.

Replace:
```lua
plant.cooldown = PLANT_DATA[plant.plant_type].cooldowns[1]
```
With:
```lua
plant._cooldown:reset(PLANT_DATA[plant.plant_type].cooldowns[1])
```

---

### 2. Remove dead color constants — `lua/game/items/grafter.lua:11-12`

`COLOR_EMPTY` and `COLOR_LOADED` were used when the grafter drew colored rectangles. Grafter now uses PNG images. Both constants are unused.

**Verify:** Confirm neither constant is referenced anywhere:
```
grep -rn "COLOR_EMPTY\|COLOR_LOADED" lua/
```
Expect only the two definition lines in `grafter.lua`, no other hits.

Delete:
```lua
local COLOR_EMPTY  = {1.0, 0.5, 0.0, 1}
local COLOR_LOADED = {1.0, 0.9, 0.0, 1}
```

---

### 3. Remove dead `target_slot` parameter — `lua/game/scenes/buy_scene.lua:71`

`target_slot` is passed to `BuyScene.new()` and stored as `self.target_slot` but never read anywhere in the file. Remove the parameter from the constructor signature and the assignment.

**Verify:** Confirm `target_slot` / `self.target_slot` is never read after assignment:
```
grep -n "target_slot" lua/game/scenes/buy_scene.lua
```
Expect exactly two hits: the constructor parameter and the `self.target_slot = target_slot` assignment — nothing else.

---

### 4. Fix redundant condition — `lua/game/store.lua:47`

`r1 < n and r1 < n - 1` — the first check is always true when the second is, making it dead logic.

**Verify:** Confirm the condition is as described:
```
grep -n "r1 < n" lua/game/store.lua
```
Expect the line `if r1 < n and r1 < n - 1 then` — both checks present on the same line.

Replace:
```lua
if r1 < n and r1 < n - 1 then
```
With:
```lua
if r1 < n - 1 then
```

---

### 5. Remove unused camera methods — `lua/core/camera.lua:33-38`

`Camera:to_world(sx, sy)` and `Camera:to_screen(wx, wy)` are defined but never called anywhere in the codebase.

**Verify:** Confirm no callers exist:
```
grep -rn "to_world\|to_screen" lua/
```
Expect only the two definition lines in `camera.lua`, no other hits.
