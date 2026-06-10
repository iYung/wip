local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

-- Test 1: initial state
local ctx = runner.setup()
assert(ctx.gs.currency == 0, "currency should start at 0, got " .. tostring(ctx.gs.currency))
assert(ctx.gs.speed_level == 0, "speed_level should start at 0")
assert(ctx.gs.growth_level == 0, "growth_level should start at 0")
print("PASS: initial state")

-- Test 2: player moves right in StoreScene
local ctx2 = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
local start_x = ctx2.gs.player.x
ctx2.input:hold("move_right")
runner.tick(ctx2.input, ctx2.sm, 30)
assert(ctx2.gs.player.x > start_x,
    "player should have moved right: start=" .. start_x .. " now=" .. ctx2.gs.player.x)
print("PASS: player moves right")

-- Test 3: player moves left in StoreScene
local ctx3 = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
-- move right first so there is room to move left
ctx3.input:hold("move_right")
runner.tick(ctx3.input, ctx3.sm, 20)
ctx3.input:release("move_right")
local mid_x = ctx3.gs.player.x
ctx3.input:hold("move_left")
runner.tick(ctx3.input, ctx3.sm, 20)
ctx3.input:release("move_left")
assert(ctx3.gs.player.x < mid_x,
    "player should have moved left: mid=" .. mid_x .. " now=" .. ctx3.gs.player.x)
print("PASS: player moves left")

-- Test 4: currency unchanged by movement
local ctx4 = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx4.input:hold("move_right")
runner.tick(ctx4.input, ctx4.sm, 60)
assert(ctx4.gs.currency == 0, "currency should not change from movement")
print("PASS: currency unchanged by movement")

print("ALL TESTS PASSED")
