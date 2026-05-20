math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local Grafter    = require("lua/game/items/grafter")

-- Test: grafter: rejects stage-2 plant
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

-- Test: grafter: clones stage-3 plant
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

-- Test: grafter: source plant reset to stage 1 after clone
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

-- Test: grafter: unload clears loaded_plant
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

-- Test: grafter: place clone into empty slot
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

-- Test: grafter: cloned plant has correct type
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

print("ALL TESTS PASSED")
