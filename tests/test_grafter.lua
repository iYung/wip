math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local Grafter    = require("lua/game/items/grafter")

-- Slot width is 200px (10*U, U=20). store:slot_at(x) = floor(x/200)+1.
-- StoreScene._setup_store fills slots 1,2,3 (WateringCan, GarbageBin, PCStore).
-- Slot N center: player.x = (N-1)*200 + 100

-- ── Test 1: grafter rejects stage-2 plant ────────────────────────────────────
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)   -- stage 1 by default
plant:update(1.0); plant:water()  -- advance to stage 2
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700        -- over slot 4

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

-- No clone should have been placed anywhere (slots 4+ still has original plant at stage 2)
for i = 5, #ctx.gs.store.slots do
    assert(ctx.gs.store.slots[i].item == nil,
        "slot " .. i .. " should be empty — stage-2 reject should spawn nothing")
end
assert(ctx.gs.store.slots[4].item == plant, "source slot should still hold original plant")
assert(plant.stage == 2, "source plant should still be stage 2")
assert(grafter.bubble.visible == false, "bubble should not be visible after stage-2 reject")
print("PASS: grafter: rejects stage-2 plant")

-- ── Test 2: source plant resets to stage 1 after a successful clone ───────────
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700        -- over slot 4; nearest empty is slot 5

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

local source = ctx.gs.store.slots[4].item
assert(source ~= nil, "source slot should still have a plant")
assert(source.stage == 1,
    "source plant should reset to stage 1, got " .. tostring(source.stage))
assert(source.ready == false, "source plant should not be ready after reset")
print("PASS: grafter: source plant resets to stage 1 after clone")

-- ── Test 3: cloned plant has correct type ─────────────────────────────────────
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(2)   -- Cactus, type 2
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700        -- over slot 4; clone lands in nearest empty (slot 5)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

local clone = ctx.gs.store.slots[5].item
assert(clone ~= nil, "a clone should appear in slot 5")
assert(clone.plant_type == 2,
    "cloned plant should be type 2 (Cactus), got " .. tostring(clone and clone.plant_type))
print("PASS: grafter: cloned plant has correct type")

-- ── Test 4: clone auto-places into nearest empty slot ────────────────────────
-- Slots 1,2,3 pre-filled by StoreScene. Source in slot 4. Slots 5-10 empty.
-- Nearest empty slot to slot 4 = slot 5 (distance 1).
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)
plant.stage = 3
ctx.gs.store.slots[4].item = plant
ctx.gs.player.x = 700        -- over slot 4

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

-- Clone should land in slot 5 (nearest empty)
assert(ctx.gs.store.slots[5].item ~= nil,
    "clone should appear in slot 5 (nearest empty)")
assert(ctx.gs.store.slots[5].item.plant_type == 1,
    "clone in slot 5 should have plant_type 1")
-- Slots 6-10 should remain empty
for i = 6, #ctx.gs.store.slots do
    assert(ctx.gs.store.slots[i].item == nil,
        "slot " .. i .. " should remain empty")
end
-- Grafter has no loaded_plant and stays in player hand
assert(grafter.loaded_plant == nil,
    "grafter should have no loaded_plant field after auto-spawn")
assert(ctx.gs.player.held_item == grafter,
    "grafter should stay in player's hand after clone")
print("PASS: grafter: clone auto-places into nearest empty slot")

-- ── Test 5: no empty slot → bubble visible, source untouched ─────────────────
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

-- Slots 1-3 already have tools from StoreScene._setup_store.
-- Fill slots 4-10 so every slot is occupied.
local source_plant = Plant.new(1)
source_plant.stage = 3
ctx.gs.store.slots[4].item = source_plant
for i = 5, #ctx.gs.store.slots do
    ctx.gs.store.slots[i].item = Plant.new(1)
end

ctx.gs.player.x = 700        -- over slot 4

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

assert(grafter.bubble.visible == true,
    "bubble should be visible when no empty slot exists")
assert(ctx.gs.store.slots[4].item == source_plant,
    "source slot should still hold the original plant")
assert(source_plant.stage == 3,
    "source plant should still be stage 3 (untouched), got " .. tostring(source_plant.stage))
print("PASS: grafter: no empty slot → bubble visible, source untouched")

-- ── Test 6: tie-breaking — lower index preferred ──────────────────────────────
-- Source in slot 5 (player.x=900). Slots 4 and 6 are both empty (distance 1 each).
-- Slots 1-3 pre-filled. Fill slots 7-10 to avoid any other empty slot being closer.
local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local grafter = Grafter.new()
ctx.gs.player.held_item = grafter

local plant = Plant.new(1)
plant.stage = 3
ctx.gs.store.slots[5].item = plant   -- source at slot 5
-- slots 1,2,3 filled by StoreScene; slot 4 is empty; slot 6 is empty
-- fill slots 7-10 so only 4 and 6 compete
for i = 7, #ctx.gs.store.slots do
    ctx.gs.store.slots[i].item = Plant.new(1)
end
ctx.gs.player.x = 900               -- over slot 5 (5th slot: (5-1)*200+100 = 900)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)

-- Tie: slot 4 and slot 6 are both distance 1. Lower index wins → slot 4.
assert(ctx.gs.store.slots[4].item ~= nil,
    "clone should land in slot 4 (lower-index tie-breaker)")
assert(ctx.gs.store.slots[4].item.plant_type == 1,
    "clone in slot 4 should have plant_type 1")
assert(ctx.gs.store.slots[6].item == nil,
    "slot 6 should remain empty (tie went to slot 4)")
print("PASS: grafter: tie-breaking prefers lower index")

print("ALL TESTS PASSED")
