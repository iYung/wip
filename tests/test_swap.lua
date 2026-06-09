math.randomseed(42)
local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local WateringCan = require("lua/game/items/watering_can")

-- Test: swap held item with carriable slot item
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)

    -- Preconditions: player at x=100 (slot 1), slot 1 has WateringCan
    assert(ctx.gs.store.slots[1].item ~= nil, "precondition: slot 1 has watering can")
    local wc = ctx.gs.store.slots[1].item

    -- Pick up the WateringCan from slot 1
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.player.held_item == wc,
        "player should hold the watering can after pick-up")
    assert(ctx.gs.store.slots[1].item == nil,
        "slot 1 should be empty after pick-up")

    -- Move player to x=300 (slot 2 center, GarbageBin)
    ctx.gs.player.x = 300

    -- Press pick_up_down again to swap
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    local slot2 = ctx.gs.store.slots[2]
    assert(slot2.item ~= nil,
        "slot 2 should contain an item after swap")
    assert(slot2.item == wc,
        "slot 2 should contain the original watering can after swap")
    assert(ctx.gs.player.held_item ~= nil,
        "player should hold an item after swap")
    assert(ctx.gs.player.held_item ~= wc,
        "player should now hold the garbage bin, not the watering can")
    print("PASS: swap: swap held item with carriable slot item")
end

-- Test: _hud_labels shows SWAP label with default key
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current

    -- Give ctx.input a _map and key_for method so _hud_labels can read key names
    ctx.input._map = { pick_up_down = {"e"}, interact = {"f"} }
    ctx.input.key_for = function(self, action)
        local keys = self._map[action]
        return keys and keys[1]
    end

    -- Set up state: player holds WateringCan, standing over slot 2 (GarbageBin)
    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil
    ctx.gs.player.x = 300  -- slot 2: GarbageBin

    local hud = scene:_hud_labels()
    assert(hud.e == "E: SWAP WITH WATERING CAN",
        "e label should be 'E: SWAP WITH WATERING CAN', got " .. tostring(hud.e))
    print("PASS: swap: _hud_labels shows SWAP label with default key")
end

-- Test: _hud_labels shows SWAP label with remapped key
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current

    -- Give ctx.input a _map and key_for method
    ctx.input._map = { pick_up_down = {"e"}, interact = {"f"} }
    ctx.input.key_for = function(self, action)
        local keys = self._map[action]
        return keys and keys[1]
    end

    -- Set up state: player holds WateringCan, standing over slot 2 (GarbageBin)
    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil
    ctx.gs.player.x = 300  -- slot 2: GarbageBin

    -- Remap pick_up_down to "g"
    ctx.input._map["pick_up_down"] = {"g"}

    local hud = scene:_hud_labels()
    assert(hud.e == "G: SWAP WITH WATERING CAN",
        "e label should be 'G: SWAP WITH WATERING CAN' after remap, got " .. tostring(hud.e))
    print("PASS: swap: _hud_labels shows SWAP label with remapped key")
end

print("ALL TESTS PASSED")
