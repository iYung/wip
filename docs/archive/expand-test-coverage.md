## Expand Test Coverage Checklist

- [x] Task 1 — `tests/test_plant_growth.lua` — plant growth unit tests
- [x] Task 2 — `tests/test_grafter.lua` — grafter clone-tool unit tests
- [x] Task 3 — `tests/test_selling.lua` — cashier-zone sale integration tests
- [x] Task 4 — `tests/test_customer_scripts.lua` — scripted customer trigger, tracking, and cooldown tests
- [x] Task 5 — `tests/test_shop.lua` — BuyScene purchase logic tests
- [x] Task 6 — `tests/test_carrying.lua` — item pick-up / put-down tests

---

### Task 1 — `tests/test_plant_growth.lua`

Create `tests/test_plant_growth.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")
```

**Slot / position constants** (derived from config: `U=20`, `slot_width = 10*U = 200`):
- Slot 1 center x = 100 (watering can)
- Slot 4 center x = 700 (plant slot used in StoreScene tests)
- Player starts at x = `slot_width / 2 = 100`

**How `runner.fast_forward_until` works:** takes `(ctx, condition_fn, elapsed, cap)` and advances 1 second per tick (dt=1.0) until the condition is true. Errors after `cap` (default 600) iterations.

**Test: `plant: stage-1 cooldown triggers ready`**

Create a standalone plant (no runner needed) and call `plant:update(dt)` directly. Grass (type 1) has `cooldowns[1] = 1` second.

```lua
local p = Plant.new(1)
assert(p.ready == false)
assert(p.bubble.visible == false)
p:update(1.0)   -- tick exactly 1 second
assert(p.ready == true, "expected ready after 1s")
assert(p.bubble.visible == true, "expected bubble visible after ready")
print("PASS: plant: stage-1 cooldown triggers ready")
```

**Test: `plant: water advances stage 1→2`**

```lua
local p = Plant.new(1)
p:update(1.0)   -- make ready
assert(p.ready == true)
p:water()
assert(p.stage == 2, "expected stage 2 after water")
assert(p.ready == false, "expected ready=false after water")
assert(p.bubble.visible == false, "expected bubble hidden after water")
print("PASS: plant: water advances stage 1->2")
```

**Test: `plant: stage-2 cooldown triggers ready`**

Grass stage-2 cooldown is `PLANT_DATA[1].cooldowns[2] = 1` second.

```lua
local p = Plant.new(1)
p:update(1.0)   -- stage-1 ready
p:water()       -- advance to stage 2
p:update(1.0)   -- stage-2 cooldown fires
assert(p.ready == true, "expected ready after stage-2 cooldown")
assert(p.bubble.visible == true)
print("PASS: plant: stage-2 cooldown triggers ready")
```

**Test: `plant: water advances stage 2→3`**

```lua
local p = Plant.new(1)
p:update(1.0); p:water()   -- stage 2
p:update(1.0); p:water()   -- stage 3
assert(p.stage == 3, "expected stage 3")
print("PASS: plant: water advances stage 2->3")
```

**Test: `plant: stage-3 plant is not ready and cannot be watered`**

Stage-3 plants have no cooldown entry; `plant:update` skips timer because `stage < 3` is false.

```lua
local p = Plant.new(1)
p:update(1.0); p:water()   -- stage 2
p:update(1.0); p:water()   -- stage 3
-- tick a long time: stage-3 should never go ready
for _ = 1, 100 do p:update(1.0) end
assert(p.ready == false, "stage-3 should never be ready")
p:water()  -- should be no-op
assert(p.stage == 3, "stage-3 water is a no-op")
print("PASS: plant: stage-3 plant is not ready and cannot be watered")
```

**Test: `plant: cooldowns match plant_data for all 6 types`**

For each plant type 1–6, tick exactly `PLANT_DATA[pt].cooldowns[1]` seconds and assert `ready == true`. This confirms the cooldown values in `plant_data.lua` are wired to `Plant._cooldown`.

```lua
for pt = 1, 6 do
    local p  = Plant.new(pt)
    local cd = PLANT_DATA[pt].cooldowns[1]
    p:update(cd)
    assert(p.ready == true,
        "plant type " .. pt .. " should be ready after " .. cd .. "s")
end
print("PASS: plant: cooldowns match plant_data for all 6 types")
```

**Test: `plant: stage3_counts incremented in StoreScene`**

This test uses a full StoreScene context to exercise the `_handle_interact` watering path, which increments `gs.stage3_counts` when a plant transitions from stage 2 → stage 3. The WateringCan is in slot 1 (x≈100), the plant goes in slot 4 (x≈700). Use `runner.fast_forward_until` (1 s/tick) to wait for ready states; use `runner.tick(ctx.input, ctx.sm, 1, 1/60)` after each single-frame input press.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
-- place a Grass plant (type 1) in slot 4
local plant_type = 1
ctx.gs.store.slots[4].item = Plant.new(plant_type)

local elapsed = 0

-- pick up watering can from slot 1 (player starts at x=100 = slot 1 center)
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

-- walk to slot 4 (x=700)
while math.abs(ctx.gs.player.x - 700) > 5 do
    ctx.input:hold("move_right")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
end
ctx.input:release("move_right")

-- wait for stage-1 ready, then water (stage 1 → 2)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.gs.store.slots[4].item ~= nil and ctx.gs.store.slots[4].item.ready
end, elapsed)
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

-- wait for stage-2 ready, then water (stage 2 → 3)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.gs.store.slots[4].item ~= nil and ctx.gs.store.slots[4].item.ready
end, elapsed)
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.store.slots[4].item.stage == 3,
    "plant should be stage 3")
assert((ctx.gs.stage3_counts[plant_type] or 0) == 1,
    "stage3_counts[1] should be 1, got " .. tostring(ctx.gs.stage3_counts[plant_type]))
print("PASS: plant: stage3_counts incremented in StoreScene")
```

End the file with `print("ALL TESTS PASSED")`.

---

### Task 2 — `tests/test_grafter.lua`

Create `tests/test_grafter.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local Grafter    = require("lua/game/items/grafter")
```

**Setup pattern for all tests:** Each test calls `runner.setup` with a `StoreScene` factory. The grafter is NOT placed by `StoreScene._setup_store`; tests must either put it in a slot and have the player pick it up, or set `player.held_item = Grafter.new()` directly. **Set `player.held_item` directly** (simpler, avoids carry mechanics tested in Task 6).

**Slot and position constants:**
- `slot_width = 200`, slot N has x range `[(N-1)*200, N*200)`, center `(N-1)*200 + 100`
- Player at x=700 is in slot 4 (range 600–800)
- `player:active_slot(store)` calls `store:slot_at(player.x)` = `floor(x/200)+1`

**How to position the player over slot 4:** Set `ctx.gs.player.x = 700` directly, then call `runner.tick(ctx.input, ctx.sm, 1, 1/60)` once to let the scene update (slot highlight, etc.).

**How `Grafter:interact` works:** Checks `player.held_item == self`, `loaded_plant == nil`, active slot has an item with `plant_type`, and `slot.item.stage == 3`. If all pass: resets original plant to stage 1, creates `self.loaded_plant = Plant.new(plant.plant_type)`. If any check fails: returns without doing anything.

**Test: `grafter: rejects stage-2 plant`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)   -- stage 1 by default
plant:update(1.0); plant:water()  -- advance to stage 2
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(grafter.loaded_plant == nil,
    "grafter should not load a stage-2 plant")
print("PASS: grafter: rejects stage-2 plant")
```

**Test: `grafter: clones stage-3 plant`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(2)  -- Cactus type 2
-- advance to stage 3 directly
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(grafter.loaded_plant ~= nil,
    "grafter should load a stage-3 plant")
assert(grafter.loaded_plant.plant_type == 2,
    "loaded plant type should match source plant type")
print("PASS: grafter: clones stage-3 plant")
```

**Shortcut for setting stage 3 directly:** Because growing a Cactus to stage 3 takes 20 simulated seconds, just set `plant.stage = 3` directly on the Plant object. This is valid — the grafter only checks `slot.item.stage`, it does not verify how the stage was reached.

**Test: `grafter: source plant reset to stage 1 after clone`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

local source = ctx.gs.store.slots[4].item
assert(source.stage == 1, "source plant should reset to stage 1, got " .. tostring(source.stage))
assert(source.ready == false, "source plant should not be ready after reset")
print("PASS: grafter: source plant reset to stage 1 after clone")
```

**Test: `grafter: unload clears loaded_plant`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1); plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
assert(grafter.loaded_plant ~= nil, "precondition: grafter should be loaded")

grafter:unload()
assert(grafter.loaded_plant == nil, "unload should clear loaded_plant")
print("PASS: grafter: unload clears loaded_plant")
```

**Test: `grafter: place clone into empty slot`**

`_handle_pick_up_down` checks: `player.held_item.loaded_plant ~= nil AND slot ~= nil AND slot.item == nil` → places clone, calls `grafter:unload()`. Player must be at x ≥ 0 (not in cashier zone).

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

-- load the grafter by cloning from slot 4
local plant = Plant.new(1); plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
assert(grafter.loaded_plant ~= nil, "precondition: grafter should be loaded")

-- move to slot 5 (x=900), which is empty
ctx.gs.player.x = 900
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.store.slots[5].item ~= nil,
    "slot 5 should now contain the cloned plant")
assert(ctx.gs.store.slots[5].item.plant_type == 1,
    "cloned plant type should be 1")
assert(grafter.loaded_plant == nil,
    "grafter should be unloaded after placing clone")
assert(ctx.gs.player.held_item == grafter,
    "grafter should stay in player hand after placing clone")
print("PASS: grafter: place clone into empty slot")
```

**Test: `grafter: cloned plant has correct type`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(2)  -- Cactus, type 2
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(grafter.loaded_plant ~= nil, "precondition: grafter should be loaded")
assert(grafter.loaded_plant.plant_type == 2,
    "cloned plant should be type 2 (Cactus)")
print("PASS: grafter: cloned plant has correct type")
```

End the file with `print("ALL TESTS PASSED")`.

---

### Task 3 — `tests/test_selling.lua`

Create `tests/test_selling.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")
```

**How the sale path works (read `store_scene.lua` `_handle_interact`):**

1. Player must be at `x < 0` (cashier zone).
2. `customer:arrived()` must be true (state == "waiting").
3. On `interact` press: if `customer:on_last_message()` AND `held.plant_type == customer.plant_type` AND `held.stage == 3`: sale fires, `gs.currency += plant_sell_value(held)`, `player.held_item = nil`, `customer:serve()` (sets state to "walking_out").
4. Otherwise: advances dialog (or skips reveal).

**How to bypass the spawn timer:** Call `ctx.sm.current._customer:show(cfg)` directly on the Customer object, then tick a few frames until `arrived()` is true (the customer walks in over a short distance). Alternatively, tick 1 second at dt=1.0 to ensure the walking-in animation completes (SPEED=80 px/s, distance from exit_x to target_x ≈ 200–400 px, so 3–5 seconds suffices). Use `runner.fast_forward_until` for this.

**How to construct a `cfg` for `customer:show`:**
```lua
local cfg = {
    plant_type      = 1,
    name            = "Test Customer",
    messages        = { "Hello." },  -- one message; after advancing past it done_talking=true
    primary_color   = {1,1,1,1},
    secondary_color = {1,1,1,1},
}
```
After `show(cfg)`, call `runner.fast_forward_until(ctx, function() return ctx.sm.current._customer:arrived() end, elapsed)` to wait until the customer reaches the counter.

**`plant_sell_value` (private in store_scene.lua):** Returns `PLANT_DATA[pt].sell` for stage-3 plants. `PLANT_DATA[1].sell = 5`, `PLANT_DATA[6].sell = 40`.

**How to advance through dialog to `done_talking`:** After customer arrives, `done_talking` starts false (because `messages` is non-empty). Call `customer:skip_reveal()` to finish the reveal, then `ctx.input:press("interact") + runner.tick(...)` to advance. After advancing past the last message, `done_talking = true` and `on_last_message()` returns true.

**Shortcut for tests that only need the sale check (not dialog):** Manually set `ctx.sm.current._customer.done_talking = true` after `show` and `arrived()`. This skips the dialog advance and puts the customer in the state where the sale fires immediately on the next `interact`. Use this shortcut for the "wrong type", "stage-1", "stage-2" tests.

**Test: `sell: correct plant type accepted, currency increases`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.currency = 0

local plant = Plant.new(1); plant.stage = 3
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200  -- cashier zone

local cfg = {
    plant_type = 1, name = "Test",
    messages = { "Hi." }, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
}
ctx.sm.current._customer:show(cfg)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

-- advance past dialog to done_talking
ctx.sm.current._customer.done_talking = true

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.currency == PLANT_DATA[1].sell,
    "currency should be " .. PLANT_DATA[1].sell .. ", got " .. tostring(ctx.gs.currency))
print("PASS: sell: correct plant type accepted, currency increases")
```

**Test: `sell: wrong plant type not accepted`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
local plant = Plant.new(2); plant.stage = 3  -- Cactus
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200

-- customer wants Grass (type 1)
ctx.sm.current._customer:show({
    plant_type = 1, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
-- messages={} means done_talking starts true immediately
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

local before = ctx.gs.currency
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.currency == before, "currency should not change for wrong plant type")
assert(ctx.gs.player.held_item ~= nil, "player should still hold the plant")
print("PASS: sell: wrong plant type not accepted")
```

**Note:** Passing `messages = {}` to `customer:show` causes `done_talking = (#messages == 0) = true` immediately — the customer arrives already in the "show item" state. Use this pattern for any test that does not need to test dialog.

**Test: `sell: stage-1 plant not accepted`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
local plant = Plant.new(1)  -- stage 1
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.sm.current._customer:show({
    plant_type = 1, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

local before = ctx.gs.currency
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.currency == before, "stage-1 plant should not sell")
print("PASS: sell: stage-1 plant not accepted")
```

**Test: `sell: stage-2 plant not accepted`**

Same as above but `plant.stage = 2`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
local plant = Plant.new(1); plant.stage = 2
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.sm.current._customer:show({
    plant_type = 1, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

local before = ctx.gs.currency
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.currency == before, "stage-2 plant should not sell")
print("PASS: sell: stage-2 plant not accepted")
```

**Test: `sell: customer currency is direct sell value (not 2×)`**

Documents that `plant_sell_value` returns `PLANT_DATA[6].sell = 40` for Golden Lotus, not 80.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.currency = 0
local plant = Plant.new(6); plant.stage = 3
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.sm.current._customer:show({
    plant_type = 6, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.currency == PLANT_DATA[6].sell,
    "Golden Lotus sale should yield " .. PLANT_DATA[6].sell .. " (not 2x), got " .. tostring(ctx.gs.currency))
print("PASS: sell: customer currency is direct sell value (not 2x)")
```

**Test: `sell: player held_item cleared after sale`**

Reuse the "correct plant accepted" setup and assert `player.held_item == nil` after the sale.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
local plant = Plant.new(1); plant.stage = 3
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.sm.current._customer:show({
    plant_type = 1, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.player.held_item == nil,
    "held_item should be nil after sale")
print("PASS: sell: player held_item cleared after sale")
```

**Test: `sell: customer enters walking_out state after sale`**

After the sale, `customer:serve()` is called which sets `state = "walking_out"`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
local plant = Plant.new(1); plant.stage = 3
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.sm.current._customer:show({
    plant_type = 1, name = "Test",
    messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
})
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.sm.current._customer.state == "walking_out",
    "customer state should be walking_out after sale, got " .. tostring(ctx.sm.current._customer.state))
print("PASS: sell: customer enters walking_out state after sale")
```

End the file with `print("ALL TESTS PASSED")`.

---

### Task 4 — `tests/test_customer_scripts.lua`

Create `tests/test_customer_scripts.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")
```

**Key facts from `customer_scripts.lua`:**
- Old Pete ch1: trigger `{ plant_type=1, count=1 }`, buys `plant_type=2` (Cactus)
- Old Pete ch2: trigger `{ plant_type=2, count=3 }`, requires `seen_scripts["old_pete:1"] == true`
- `_next_customer_cfg()` is a private method on the StoreScene table. Access it as `ctx.sm.current:_next_customer_cfg()`. This is valid Lua — it is just a regular function field, no wrapper needed.
- `_next_customer_cfg()` returns the script table directly (with `id`, `chapter`, `plant_type`, `messages`, etc.) or a random cfg table. It also sets `self._active_script_key` as a side effect when a scripted customer is returned.
- `_script_cooldowns` is a table on the scene: `scene._script_cooldowns[key] = count`.
- `DISMISS_COOLDOWN_SALES = 3` is the value set when a scripted customer is dismissed.

**Open question 3 resolution (inline):** Tests that only check `_next_customer_cfg()` output call it directly. The "cooldown decrements per sale" test must drive the full tick loop (3 full sell cycles) to exercise the decrement path in `_handle_interact`.

**Test: `scripts: scripted customer spawned when trigger met`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.stage3_counts[1] = 1   -- Old Pete ch1 trigger: plant_type=1, count=1
local cfg = ctx.sm.current:_next_customer_cfg()
assert(cfg ~= nil, "should return a cfg")
assert(cfg.id == "old_pete", "expected id 'old_pete', got " .. tostring(cfg.id))
assert(cfg.chapter == 1, "expected chapter 1, got " .. tostring(cfg.chapter))
print("PASS: scripts: scripted customer spawned when trigger met")
```

**Test: `scripts: scripted customer not spawned before trigger count`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.stage3_counts[1] = 0   -- trigger count not met
ctx.gs.unlocked_plants = {}   -- also disable random customers (no unlocked plants)
local cfg = ctx.sm.current:_next_customer_cfg()
assert(cfg == nil or cfg.id == nil,
    "should not return a scripted customer when trigger not met")
print("PASS: scripts: scripted customer not spawned before trigger count")
```

**Note:** With `unlocked_plants = {}`, the random-customer fallback in `_next_customer_cfg` also returns `nil` (the `keys` table is empty). Clearing `unlocked_plants` prevents a random customer cfg from masking the scripted-customer logic.

**Test: `scripts: chapter 2 not available before chapter 1 seen`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.stage3_counts[2] = 3   -- Old Pete ch2 trigger: plant_type=2, count=3
ctx.gs.seen_scripts = {}      -- ch1 not seen
ctx.gs.unlocked_plants = {}
local cfg = ctx.sm.current:_next_customer_cfg()
-- ch2 should NOT qualify because seen_scripts["old_pete:1"] is nil
local is_pete_ch2 = cfg and cfg.id == "old_pete" and cfg.chapter == 2
assert(not is_pete_ch2,
    "Old Pete ch2 should not be available before ch1 is seen")
print("PASS: scripts: chapter 2 not available before chapter 1 seen")
```

**Test: `scripts: chapter 2 available after chapter 1 seen`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.stage3_counts[1] = 1   -- ch1 trigger also met, mark as seen
ctx.gs.stage3_counts[2] = 3   -- ch2 trigger met
ctx.gs.seen_scripts = { ["old_pete:1"] = true }  -- ch1 has been seen
ctx.gs.unlocked_plants = {}
local cfg = ctx.sm.current:_next_customer_cfg()
assert(cfg ~= nil and cfg.id == "old_pete" and cfg.chapter == 2,
    "Old Pete ch2 should be available after ch1 seen, got " .. tostring(cfg and cfg.id))
print("PASS: scripts: chapter 2 available after chapter 1 seen")
```

**Test: `scripts: seen_scripts written on sale, not on spawn`**

Call `_next_customer_cfg()` to qualify the script (sets `_active_script_key`). Then simulate a sale with the correct plant (Cactus = type 2 for Old Pete) and confirm `seen_scripts["old_pete:1"]` is set.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.stage3_counts[1] = 1

-- spawning alone should NOT write seen_scripts
local cfg = ctx.sm.current:_next_customer_cfg()
assert(cfg and cfg.id == "old_pete", "precondition: Old Pete ch1 qualified")
assert(ctx.gs.seen_scripts["old_pete:1"] == nil,
    "seen_scripts should NOT be written on spawn")

-- show the customer and complete a sale
ctx.sm.current._customer:show(cfg)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

-- complete dialog
while not ctx.sm.current._customer:on_last_message() do
    ctx.sm.current._customer:skip_reveal()
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
end

-- make the sale
local plant = Plant.new(2); plant.stage = 3
ctx.gs.player.held_item = plant
ctx.gs.player.x = -200
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.seen_scripts["old_pete:1"] == true,
    "seen_scripts['old_pete:1'] should be true after sale")
print("PASS: scripts: seen_scripts written on sale, not on spawn")
```

**Test: `scripts: seen_scripts not written on dismiss`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.stage3_counts[1] = 1

local cfg = ctx.sm.current:_next_customer_cfg()
ctx.sm.current._customer:show(cfg)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

-- dismiss: player presses pick_up_down in cashier zone (x < 0)
ctx.gs.player.x = -200
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.seen_scripts["old_pete:1"] == nil,
    "seen_scripts should NOT be written on dismiss")
print("PASS: scripts: seen_scripts not written on dismiss")
```

**Test: `scripts: dismiss sets cooldown`**

After dismissing, `_script_cooldowns["old_pete:1"]` must equal `DISMISS_COOLDOWN_SALES = 3`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.stage3_counts[1] = 1

local cfg = ctx.sm.current:_next_customer_cfg()
ctx.sm.current._customer:show(cfg)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)

ctx.gs.player.x = -200
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 3,
    "dismiss should set cooldown to 3, got " .. tostring(ctx.sm.current._script_cooldowns["old_pete:1"]))
print("PASS: scripts: dismiss sets cooldown")
```

**Test: `scripts: cooldown decrements per sale, customer returns after 3 sales`**

**This test uses the full tick loop** (not direct `_next_customer_cfg` bypass) because it must drive 3 complete sell cycles to verify the decrement. Use Grass (type 1, sells for $5) as the filler customers.

Setup: dismiss Old Pete (cooldown=3), then drive 3 grass sale cycles. After each sale, `_script_cooldowns["old_pete:1"]` decrements by 1. After 3 sales the key is removed. Then call `_next_customer_cfg()` to verify Old Pete is eligible again.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local elapsed = 0
ctx.gs.stage3_counts[1] = 1
ctx.gs.unlocked_plants = { [1] = true }  -- for random-customer fallback

-- qualify and dismiss Old Pete to set cooldown
local pete_cfg = ctx.sm.current:_next_customer_cfg()
assert(pete_cfg and pete_cfg.id == "old_pete", "precondition")
ctx.sm.current._customer:show(pete_cfg)
elapsed = runner.fast_forward_until(ctx, function()
    return ctx.sm.current._customer:arrived()
end, elapsed)
ctx.gs.player.x = -200
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 3, "precondition: cooldown=3")

-- helper: do one grass sale (bypasses spawn timer, uses direct show)
local function do_grass_sale()
    -- reset _active_script_key so the cooldown decrement applies to our cooldown key
    ctx.sm.current._active_script_key = nil
    local grass_cfg = {
        plant_type = 1, name = "Grass Customer",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }
    ctx.sm.current._customer:show(grass_cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
end

do_grass_sale()
assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 2, "cooldown should be 2 after sale 1")
do_grass_sale()
assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 1, "cooldown should be 1 after sale 2")
do_grass_sale()
assert(ctx.sm.current._script_cooldowns["old_pete:1"] == nil, "cooldown should be removed after sale 3")

-- Old Pete should now be eligible again
local cfg2 = ctx.sm.current:_next_customer_cfg()
assert(cfg2 and cfg2.id == "old_pete",
    "Old Pete should be eligible after cooldown expires, got " .. tostring(cfg2 and cfg2.id))
print("PASS: scripts: cooldown decrements per sale, customer returns after 3 sales")
```

End the file with `print("ALL TESTS PASSED")`.

---

### Task 5 — `tests/test_shop.lua`

Create `tests/test_shop.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local BuyScene   = require("lua/game/scenes/buy_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")
local config     = require("lua/game/config")
local SPEED_TIERS  = require("lua/game/data/speed_tiers")
local GROWTH_TIERS = require("lua/game/data/growth_tiers")
```

**How `BuyScene` works:**

`BuyScene.new(gs, input, sm, store_scene)` — `store_scene` is the 4th argument (used to switch back on cancel/buy). Pass `ctx.sm.current` (the StoreScene instance) as `store_scene`. **Open question 1 resolution:** This is confirmed correct — no special changes to BuyScene needed.

`BuyScene._confirm()` reads `self.selected` (1-based index into `CATALOGUE`). Set `scene.selected` before calling `scene:_confirm()` to control which item is purchased.

**CATALOGUE order** (built at module load time in `buy_scene.lua`):
- Indices 1–6: plant types 1–6 (Grass, Cactus, Rose, Tulip, Daisy, Golden Lotus)
- Index 7: Watering Can (cost 0)
- Index 8: Grafter (cost 0)
- Index 9: Expand Slot (cost = `config.SLOT_COST = 1`)
- Index 10: Sneakers (speed_boost) — cost from `SPEED_TIERS[gs.speed_level + 1].cost`
- Index 11: Heat Lamps (growth_boost) — cost from `GROWTH_TIERS[gs.growth_level + 1].cost`

**How to construct a BuyScene for testing:**
```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
-- ctx.sm.current is the StoreScene
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
```
Do NOT call `ctx.sm:switch(buy)` — test `_confirm()` directly without switching. This avoids triggering `on_enter`/`on_exit` side effects.

**Test: `shop: buy plant unlocks it`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
buy.selected = 2   -- Cactus = index 2, cost = PLANT_DATA[2].cost = 3
buy:_confirm()
assert(ctx.gs.unlocked_plants[2] == true,
    "Cactus should be unlocked after purchase")
print("PASS: shop: buy plant unlocks it")
```

**Test: `shop: buy plant deducts correct cost`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
buy.selected = 2  -- Cactus, cost=3
buy:_confirm()
assert(ctx.gs.currency == 97,
    "currency should be 97 after buying Cactus ($3), got " .. tostring(ctx.gs.currency))
print("PASS: shop: buy plant deducts correct cost")
```

**Test: `shop: buy plant gives player the plant`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
buy.selected = 2  -- Cactus
buy:_confirm()
assert(ctx.gs.player.held_item ~= nil, "player should hold a plant after purchase")
assert(ctx.gs.player.held_item.plant_type == 2,
    "held item should be plant_type 2 (Cactus)")
print("PASS: shop: buy plant gives player the plant")
```

**Test: `shop: cannot buy if insufficient currency`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 0
buy.selected = 2  -- Cactus costs $3
buy:_confirm()
assert(ctx.gs.currency == 0, "currency should be unchanged when broke")
assert(ctx.gs.player.held_item == nil, "player should not receive plant when broke")
print("PASS: shop: cannot buy if insufficient currency")
```

**Test: `shop: speed upgrade cost and speed value`**

Sneakers tier 1: `SPEED_TIERS[1] = { cost=15, speed=320 }`. Selected index = 10.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
ctx.gs.speed_level = 0   -- tier 1 costs 15
buy.selected = 10        -- Sneakers
buy:_confirm()
assert(ctx.gs.currency == 85,
    "currency should be 85 after buying Sneakers ($15), got " .. tostring(ctx.gs.currency))
assert(ctx.gs.player.speed == 320,
    "speed should be 320 after tier-1 upgrade, got " .. tostring(ctx.gs.player.speed))
assert(ctx.gs.speed_level == 1,
    "speed_level should be 1, got " .. tostring(ctx.gs.speed_level))
print("PASS: shop: speed upgrade cost and speed value")
```

**Test: `shop: growth upgrade cost and multiplier value`**

Heat Lamps tier 1: `GROWTH_TIERS[1] = { cost=20, mult=1.25 }`. Selected index = 11.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
ctx.gs.growth_level = 0
buy.selected = 11        -- Heat Lamps
buy:_confirm()
assert(ctx.gs.currency == 80,
    "currency should be 80 after buying Heat Lamps ($20), got " .. tostring(ctx.gs.currency))
assert(ctx.gs.growth_mult == 1.25,
    "growth_mult should be 1.25, got " .. tostring(ctx.gs.growth_mult))
assert(ctx.gs.growth_level == 1,
    "growth_level should be 1, got " .. tostring(ctx.gs.growth_level))
print("PASS: shop: growth upgrade cost and multiplier value")
```

**Test: `shop: expand slot adds one slot`**

Expand Slot is index 9, cost = `config.SLOT_COST = 1`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
local before_count = #ctx.gs.store.slots
buy.selected = 9   -- Expand Slot
buy:_confirm()
assert(#ctx.gs.store.slots == before_count + 1,
    "store should have one more slot after Expand Slot")
print("PASS: shop: expand slot adds one slot")
```

**Test: `shop: expand slot costs SLOT_COST`**

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 100
buy.selected = 9
buy:_confirm()
assert(ctx.gs.currency == 100 - config.SLOT_COST,
    "currency should decrease by SLOT_COST=" .. config.SLOT_COST)
print("PASS: shop: expand slot costs SLOT_COST")
```

**Test: `shop: cannot buy speed at max level`**

`#SPEED_TIERS = 3`. Set `gs.speed_level = 3`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 9999
ctx.gs.speed_level = 3  -- max
buy.selected = 10
buy:_confirm()
assert(ctx.gs.speed_level == 3, "speed_level should remain 3 at max")
assert(ctx.gs.currency == 9999, "currency should be unchanged at max speed")
print("PASS: shop: cannot buy speed at max level")
```

**Test: `shop: cannot buy growth at max level`**

`#GROWTH_TIERS = 3`. Set `gs.growth_level = 3`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local buy = BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
ctx.gs.currency = 9999
ctx.gs.growth_level = 3  -- max
buy.selected = 11
buy:_confirm()
assert(ctx.gs.growth_level == 3, "growth_level should remain 3 at max")
assert(ctx.gs.currency == 9999, "currency should be unchanged at max growth")
print("PASS: shop: cannot buy growth at max level")
```

End the file with `print("ALL TESTS PASSED")`.

---

### Task 6 — `tests/test_carrying.lua`

Create `tests/test_carrying.lua`. No other files are touched.

**Requires:**
```lua
math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local BuyScene   = require("lua/game/scenes/buy_scene")
```

**StoreScene slot layout after `_setup_store`:**
- Slot 1 (x=0–200): WateringCan (`carriable=true`)
- Slot 2 (x=200–400): GarbageBin (`carriable=true`)
- Slot 3 (x=400–600): PCStore (`carriable=true`, `sellable=false`, has `buy_scene_factory`)
- Slots 4–10: empty

Player starts at x=100 (slot 1 center). All tests position the player by setting `ctx.gs.player.x` directly and then ticking one frame.

**`_handle_pick_up_down` logic recap:**
- If `player.x < 0`: dismisses customer (or no-op if none); returns.
- If `player.held_item.loaded_plant != nil` and slot empty: places clone.
- If `player.held_item != nil` and slot is empty: puts item down.
- If `player.held_item == nil` and `slot.item.carriable`: picks up.
- If `player.held_item != nil` and slot is occupied: no-op (cannot swap).

**Test: `carry: pick up carriable item from slot`**

Pick up the WateringCan from slot 1.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
-- player starts at x=100 = slot 1 center
assert(ctx.gs.store.slots[1].item ~= nil, "precondition: slot 1 has watering can")
local wc = ctx.gs.store.slots[1].item

ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.player.held_item == wc,
    "player should hold the watering can")
assert(ctx.gs.store.slots[1].item == nil,
    "slot 1 should be empty after pick-up")
print("PASS: carry: pick up carriable item from slot")
```

**Test: `carry: put down held item into empty slot`**

Player holds the WateringCan; put it down in slot 4 (empty).

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local wc = ctx.gs.store.slots[1].item
ctx.gs.player.held_item = wc
ctx.gs.store.slots[1].item = nil
ctx.gs.player.x = 700   -- slot 4 center

ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.store.slots[4].item == wc,
    "slot 4 should contain the watering can")
assert(ctx.gs.player.held_item == nil,
    "player should not hold anything after putting down")
print("PASS: carry: put down held item into empty slot")
```

**Test: `carry: cannot pick up non-carriable item`**

There is no built-in non-carriable item, so set `carriable = false` on a Plant directly. This tests the guard in `_handle_pick_up_down`.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local plant = Plant.new(1)
plant.carriable = false
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.player.held_item == nil,
    "player should not pick up a non-carriable item")
assert(ctx.gs.store.slots[4].item == plant,
    "non-carriable item should remain in slot")
print("PASS: carry: cannot pick up non-carriable item")
```

**Test: `carry: cannot put down into occupied slot`**

Player holds WateringCan; slot already has a Plant — put-down should be a no-op.

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local wc = WateringCan.new()
ctx.gs.player.held_item = wc
local plant = Plant.new(1)
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700

ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.gs.player.held_item == wc,
    "player should still hold the watering can")
assert(ctx.gs.store.slots[4].item == plant,
    "occupied slot should still contain the plant")
print("PASS: carry: cannot put down into occupied slot")
```

**Test: `carry: cannot open shop while holding item`**

`PCStore:interact` returns early if `player.held_item ~= nil`. The scene should remain StoreScene (not switch to BuyScene).

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local store_scene = ctx.sm.current
local wc = WateringCan.new()
ctx.gs.player.held_item = wc
ctx.gs.player.x = 500   -- slot 3 = PCStore (x range 400–600)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(ctx.sm.current == store_scene,
    "scene should remain StoreScene when interacting with PC Store while holding an item")
print("PASS: carry: cannot open shop while holding item")
```

**Test: `carry: held item sprite follows player position`**

After picking up the WateringCan and ticking one frame, `held_item.sprite.x` should equal `player.x - sprite.width/2`. This is set by `Player:update` in `player.lua` (line: `spr.x = self.x - spr.width / 2`).

```lua
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local wc = ctx.gs.store.slots[1].item
ctx.gs.player.held_item = wc
ctx.gs.store.slots[1].item = nil
-- tick one frame so Player:update runs
runner.tick(ctx.input, ctx.sm, 1, 1/60)

local expected_x = ctx.gs.player.x - wc.sprite.width / 2
assert(math.abs(wc.sprite.x - expected_x) < 1,
    "held item sprite.x should be player.x - sprite.width/2, expected " ..
    expected_x .. " got " .. tostring(wc.sprite.x))
print("PASS: carry: held item sprite follows player position")
```

End the file with `print("ALL TESTS PASSED")`.
