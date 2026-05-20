math.randomseed(42)
local runner       = require("lua/headless/runner")
local StoreScene   = require("lua/game/scenes/store_scene")
local BuyScene     = require("lua/game/scenes/buy_scene")
local PLANT_DATA   = require("lua/game/data/plant_data")
local config       = require("lua/game/config")
local SPEED_TIERS  = require("lua/game/data/speed_tiers")
local GROWTH_TIERS = require("lua/game/data/growth_tiers")

-- CATALOGUE indices (matches buy_scene.lua build order):
-- 1-6: plant types 1-6
-- 7:   Watering Can
-- 8:   Grafter
-- 9:   Expand Slot
-- 10:  Sneakers (speed_boost)
-- 11:  Heat Lamps (growth_boost)

local function make_buy(ctx)
    return BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
end

-- Test: buy plant unlocks it
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = 2   -- Cactus, cost = PLANT_DATA[2].cost = 3
    buy:_confirm()
    assert(ctx.gs.unlocked_plants[2] == true,
        "Cactus should be unlocked after purchase")
    print("PASS: shop: buy plant unlocks it")
end

-- Test: buy plant deducts correct cost
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = 2   -- Cactus, cost = 3
    buy:_confirm()
    assert(ctx.gs.currency == 97,
        "currency should be 97 after buying Cactus ($3), got " .. tostring(ctx.gs.currency))
    print("PASS: shop: buy plant deducts correct cost")
end

-- Test: buy plant gives player the plant
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = 2   -- Cactus
    buy:_confirm()
    assert(ctx.gs.player.held_item ~= nil,
        "player should hold a plant after purchase")
    assert(ctx.gs.player.held_item.plant_type == 2,
        "held item should be plant_type 2 (Cactus), got " .. tostring(ctx.gs.player.held_item and ctx.gs.player.held_item.plant_type))
    print("PASS: shop: buy plant gives player the plant")
end

-- Test: cannot buy if insufficient currency
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 0
    buy.selected = 2   -- Cactus costs $3
    buy:_confirm()
    assert(ctx.gs.currency == 0, "currency should be unchanged when broke")
    assert(ctx.gs.player.held_item == nil,
        "player should not receive plant when broke")
    print("PASS: shop: cannot buy if insufficient currency")
end

-- Test: speed upgrade cost and speed value
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    ctx.gs.speed_level = 0   -- tier 1 costs 15, speed = 320
    buy.selected = 10        -- Sneakers
    buy:_confirm()
    assert(ctx.gs.currency == 85,
        "currency should be 85 after Sneakers ($15), got " .. tostring(ctx.gs.currency))
    assert(ctx.gs.player.speed == 320,
        "speed should be 320 after tier-1 upgrade, got " .. tostring(ctx.gs.player.speed))
    assert(ctx.gs.speed_level == 1,
        "speed_level should be 1, got " .. tostring(ctx.gs.speed_level))
    print("PASS: shop: speed upgrade cost and speed value")
end

-- Test: growth upgrade cost and multiplier value
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    ctx.gs.growth_level = 0
    buy.selected = 11        -- Heat Lamps
    buy:_confirm()
    assert(ctx.gs.currency == 80,
        "currency should be 80 after Heat Lamps ($20), got " .. tostring(ctx.gs.currency))
    assert(ctx.gs.growth_mult == 1.25,
        "growth_mult should be 1.25, got " .. tostring(ctx.gs.growth_mult))
    assert(ctx.gs.growth_level == 1,
        "growth_level should be 1, got " .. tostring(ctx.gs.growth_level))
    print("PASS: shop: growth upgrade cost and multiplier value")
end

-- Test: expand slot adds one slot
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    local before_count = #ctx.gs.store.slots
    buy.selected = 9   -- Expand Slot
    buy:_confirm()
    assert(#ctx.gs.store.slots == before_count + 1,
        "store should have one more slot after Expand Slot, before=" .. before_count .. " after=" .. #ctx.gs.store.slots)
    print("PASS: shop: expand slot adds one slot")
end

-- Test: expand slot costs SLOT_COST
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = 9
    buy:_confirm()
    assert(ctx.gs.currency == 100 - config.SLOT_COST,
        "currency should decrease by SLOT_COST=" .. config.SLOT_COST .. ", got " .. tostring(ctx.gs.currency))
    print("PASS: shop: expand slot costs SLOT_COST")
end

-- Test: cannot buy speed at max level
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 9999
    ctx.gs.speed_level = #SPEED_TIERS   -- max (3)
    buy.selected = 10
    buy:_confirm()
    assert(ctx.gs.speed_level == #SPEED_TIERS,
        "speed_level should remain at max, got " .. tostring(ctx.gs.speed_level))
    assert(ctx.gs.currency == 9999,
        "currency should be unchanged at max speed, got " .. tostring(ctx.gs.currency))
    print("PASS: shop: cannot buy speed at max level")
end

-- Test: cannot buy growth at max level
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 9999
    ctx.gs.growth_level = #GROWTH_TIERS   -- max (3)
    buy.selected = 11
    buy:_confirm()
    assert(ctx.gs.growth_level == #GROWTH_TIERS,
        "growth_level should remain at max, got " .. tostring(ctx.gs.growth_level))
    assert(ctx.gs.currency == 9999,
        "currency should be unchanged at max growth, got " .. tostring(ctx.gs.currency))
    print("PASS: shop: cannot buy growth at max level")
end

print("ALL TESTS PASSED")
