math.randomseed(42)
local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local Plant       = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local PLANT_DATA  = require("lua/game/data/plant_data")

-- Slot layout: slot 1 occupies x=0..199 (slot_width=200).
-- Cashier zone: player.x < 0.
-- Grass (plant_type=1) cooldown stage-1 = 3 s.

local CD1 = PLANT_DATA[1].cooldowns[1]

-- Helper: build a fresh StoreScene ctx with a stage-ready Grass plant in slot 1
-- and the player holding a WateringCan.
local function make_ctx()
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local gs = ctx.gs

    -- Replace whatever is in slot 1 with a stage-ready Grass plant.
    local plant = Plant.new(1)
    plant:update(CD1)   -- advance cooldown so plant.ready = true
    assert(plant.ready == true, "precondition: plant should be ready")
    gs.store.slots[1].item = plant

    -- Give the player a WateringCan.
    gs.player.held_item = WateringCan.new()

    return ctx, plant
end

-- Test 1: player in cashier zone (x < 0) — Interact does NOT water the plant.
do
    local ctx, plant = make_ctx()
    local gs = ctx.gs

    gs.player.x = -50   -- cashier zone

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(plant.stage == 1,
        "stage should remain 1 when player is in cashier zone, got " .. tostring(plant.stage))
    assert(plant.ready == true,
        "plant should still be ready after no-op interact, got ready=" .. tostring(plant.ready))
    print("PASS: watering range: interact in cashier zone does NOT advance plant stage")
end

-- Test 2: player in store zone at slot 1 (x >= 0) — Interact DOES water the plant.
do
    local ctx, plant = make_ctx()
    local gs = ctx.gs

    gs.player.x = 100   -- slot 1 center (x=0..199)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(plant.stage == 2,
        "stage should advance to 2 when player is in store zone, got " .. tostring(plant.stage))
    assert(plant.ready == false,
        "plant should not be ready after watering, got ready=" .. tostring(plant.ready))
    print("PASS: watering range: interact in store zone DOES advance plant stage")
end

print("ALL TESTS PASSED")
