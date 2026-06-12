math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")

local function find_priority(scene, sprite)
    for _, entry in ipairs(scene.drawer.layers) do
        if entry.sprite == sprite then return entry.priority end
    end
    return nil
end

-- Test: bubble drawer priorities — customer < plant < held
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current

    local cust_pri   = find_priority(scene, scene._customer_bubble)
    local plant_pri  = find_priority(scene, scene._plant_bubbles)
    local player_pri = find_priority(scene, ctx.gs.player)
    local held_pri   = find_priority(scene, scene._held_bubble)

    assert(cust_pri   ~= nil, "customer_bubble must be in drawer")
    assert(plant_pri  ~= nil, "plant_bubbles must be in drawer")
    assert(player_pri ~= nil, "player must be in drawer")
    assert(held_pri   ~= nil, "held_bubble must be in drawer")

    assert(cust_pri < plant_pri,
        "customer_bubble (" .. cust_pri .. ") must be below plant_bubbles (" .. plant_pri .. ")")
    assert(plant_pri < player_pri,
        "plant_bubbles (" .. plant_pri .. ") must be below player (" .. player_pri .. ")")
    assert(player_pri < held_pri,
        "player (" .. player_pri .. ") must be below held_bubble (" .. held_pri .. ")")

    print("PASS: draw_order: held_bubble > player > plant_bubbles > customer_bubble")
end

-- Test: Player:draw() no longer calls draw_bubble on held item
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current

    local plant = Plant.new(1)
    local bubble_calls = 0
    plant.draw_bubble = function() bubble_calls = bubble_calls + 1 end
    ctx.gs.player.held_item = plant

    ctx.gs.player:draw()
    assert(bubble_calls == 0,
        "Player:draw() must not call draw_bubble (got " .. bubble_calls .. " call(s))")

    scene._held_bubble:draw()
    assert(bubble_calls == 1,
        "_held_bubble:draw() must call held item's draw_bubble once")

    print("PASS: draw_order: held item bubble routed through _held_bubble, not Player:draw")
end

print("ALL TESTS PASSED")
