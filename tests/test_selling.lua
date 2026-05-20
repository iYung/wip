math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local PLANT_DATA = require("lua/game/data/plant_data")

-- helper: show a customer and wait until arrived
local function show_customer(ctx, cfg, elapsed)
    ctx.sm.current._customer:show(cfg)
    return runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
end

-- Test: correct plant type accepted, currency increases
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.currency = 0

    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.currency == PLANT_DATA[1].sell,
        "currency should be " .. PLANT_DATA[1].sell .. ", got " .. tostring(ctx.gs.currency))
    print("PASS: sell: correct plant type accepted, currency increases")
end

-- Test: wrong plant type not accepted
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    local plant = Plant.new(2); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    local before = ctx.gs.currency
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.currency == before, "currency should not change for wrong plant type")
    assert(ctx.gs.player.held_item ~= nil, "player should still hold the plant")
    print("PASS: sell: wrong plant type not accepted")
end

-- Test: stage-1 plant not accepted
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    local plant = Plant.new(1)  -- stage 1
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    local before = ctx.gs.currency
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.currency == before, "stage-1 plant should not sell")
    print("PASS: sell: stage-1 plant not accepted")
end

-- Test: stage-2 plant not accepted
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    local plant = Plant.new(1); plant.stage = 2
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    local before = ctx.gs.currency
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.currency == before, "stage-2 plant should not sell")
    print("PASS: sell: stage-2 plant not accepted")
end

-- Test: currency is direct sell value (not 2x)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.currency = 0
    local plant = Plant.new(6); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 6, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.currency == PLANT_DATA[6].sell,
        "Golden Lotus sale should yield " .. PLANT_DATA[6].sell .. " (not 2x), got " .. tostring(ctx.gs.currency))
    print("PASS: sell: customer currency is direct sell value (not 2x)")
end

-- Test: player held_item cleared after sale
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.player.held_item == nil, "held_item should be nil after sale")
    print("PASS: sell: player held_item cleared after sale")
end

-- Test: customer enters walking_out state after sale
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200

    elapsed = show_customer(ctx, {
        plant_type = 1, name = "Test",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    }, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "walking_out",
        "customer state should be walking_out after sale, got " .. tostring(ctx.sm.current._customer.state))
    print("PASS: sell: customer enters walking_out state after sale")
end

print("ALL TESTS PASSED")
