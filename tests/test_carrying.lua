math.randomseed(42)
local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local Plant       = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")

-- StoreScene slot layout after _setup_store:
--   Slot 1 (x=0-200):   WateringCan (carriable=true)
--   Slot 2 (x=200-400): GarbageBin  (carriable=true)
--   Slot 3 (x=400-600): PCStore     (carriable=true, sellable=false)
--   Slots 4-10: empty
-- Player starts at x=100 (slot 1 center).

-- Test: pick up carriable item from slot
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    assert(ctx.gs.store.slots[1].item ~= nil, "precondition: slot 1 has watering can")
    local wc = ctx.gs.store.slots[1].item

    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.player.held_item == wc,
        "player should hold the watering can")
    assert(ctx.gs.store.slots[1].item == nil,
        "slot 1 should be empty after pick-up")
    print("PASS: carry: pick up carriable item from slot")
end

-- Test: put down held item into empty slot
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil
    ctx.gs.player.x = 700   -- slot 4 center (empty)

    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.store.slots[4].item == wc,
        "slot 4 should contain the watering can")
    assert(ctx.gs.player.held_item == nil,
        "player should not hold anything after putting down")
    print("PASS: carry: put down held item into empty slot")
end

-- Test: cannot pick up non-carriable item
do
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
end

-- Test: swaps held item with carriable item in occupied slot
do
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

    assert(ctx.gs.player.held_item == plant,
        "player should now hold the plant after swap")
    assert(ctx.gs.store.slots[4].item == wc,
        "slot 4 should now contain the watering can after swap")
    print("PASS: carry: swaps held item with carriable item in occupied slot")
end

-- Test: cannot open shop while holding item
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene = ctx.sm.current
    local wc = WateringCan.new()
    ctx.gs.player.held_item = wc
    ctx.gs.player.x = 500   -- slot 3 = PCStore (x range 400-600)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current == store_scene,
        "scene should remain StoreScene when interacting with PC Store while holding an item")
    print("PASS: carry: cannot open shop while holding item")
end

-- Test: held item sprite follows player position
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil

    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    local expected_x = ctx.gs.player.x - wc.sprite.width / 2
    assert(math.abs(wc.sprite.x - expected_x) < 1,
        "held item sprite.x should be player.x - sprite.width/2, expected " ..
        expected_x .. " got " .. tostring(wc.sprite.x))
    print("PASS: carry: held item sprite follows player position")
end

print("ALL TESTS PASSED")
