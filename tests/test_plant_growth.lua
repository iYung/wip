math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")

local CD1 = PLANT_DATA[1].cooldowns[1]
local CD2 = PLANT_DATA[1].cooldowns[2]

-- Test: plant: stage-1 cooldown triggers ready
do
    local p = Plant.new(1)
    assert(p.ready == false)
    assert(p.bubble.visible == false)
    p:update(CD1)
    assert(p.ready == true, "expected ready after stage-1 cooldown")
    assert(p.bubble.visible == true, "expected bubble visible after ready")
    print("PASS: plant: stage-1 cooldown triggers ready")
end

-- Test: plant: water advances stage 1→2
do
    local p = Plant.new(1)
    p:update(CD1)
    assert(p.ready == true)
    p:water()
    assert(p.stage == 2, "expected stage 2 after water")
    assert(p.ready == false, "expected ready=false after water")
    assert(p.bubble.visible == false, "expected bubble hidden after water")
    print("PASS: plant: water advances stage 1->2")
end

-- Test: plant: stage-2 cooldown triggers ready
do
    local p = Plant.new(1)
    p:update(CD1)   -- stage-1 ready
    p:water()       -- advance to stage 2
    p:update(CD2)   -- stage-2 cooldown fires
    assert(p.ready == true, "expected ready after stage-2 cooldown")
    assert(p.bubble.visible == true)
    print("PASS: plant: stage-2 cooldown triggers ready")
end

-- Test: plant: water advances stage 2→3
do
    local p = Plant.new(1)
    p:update(CD1); p:water()   -- stage 2
    p:update(CD2); p:water()   -- stage 3
    assert(p.stage == 3, "expected stage 3")
    print("PASS: plant: water advances stage 2->3")
end

-- Test: plant: stage-3 plant is not ready and cannot be watered
do
    local p = Plant.new(1)
    p:update(CD1); p:water()   -- stage 2
    p:update(CD2); p:water()   -- stage 3
    -- tick a long time: stage-3 should never go ready
    for _ = 1, 100 do p:update(1.0) end
    assert(p.ready == false, "stage-3 should never be ready")
    p:water()  -- should be no-op
    assert(p.stage == 3, "stage-3 water is a no-op")
    print("PASS: plant: stage-3 plant is not ready and cannot be watered")
end

-- Test: plant: cooldowns match plant_data for all 6 types
do
    for pt = 1, 6 do
        local p  = Plant.new(pt)
        local cd = PLANT_DATA[pt].cooldowns[1]
        p:update(cd)
        assert(p.ready == true,
            "plant type " .. pt .. " should be ready after " .. cd .. "s")
    end
    print("PASS: plant: cooldowns match plant_data for all 6 types")
end

-- Test: plant: stage3_counts incremented in StoreScene
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    -- place a Grass plant (type 1) in slot 4
    local plant_type = 1
    ctx.gs.store.slots[4].item = Plant.new(plant_type)

    local elapsed = 0

    -- pick up watering can from slot 1 (player starts at x=100 = slot 1 center)
    ctx.input:press("move_up")
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
end

-- Test: plant: water() returns false when not ready
do
    local p = Plant.new(1)
    assert(p:water() == false, "water() should return false when not ready")
    print("PASS: plant: water() returns false when not ready")
end

-- Test: plant: water() returns true on successful advance
do
    local p = Plant.new(1)
    p:update(CD1)
    assert(p:water() == true, "water() should return true on success")
    print("PASS: plant: water() returns true on successful advance")
end

-- Test: plant: water() returns false at stage 3
do
    local p = Plant.new(1)
    p:update(CD1); p:water()
    p:update(CD2); p:water()
    assert(p.stage == 3)
    assert(p:water() == false, "water() should return false at stage 3")
    print("PASS: plant: water() returns false at stage 3")
end

print("ALL TESTS PASSED")
