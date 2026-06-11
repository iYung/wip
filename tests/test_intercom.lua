math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local BuyScene   = require("lua/game/scenes/buy_scene")
local Intercom   = require("lua/game/items/intercom")
local GameState  = require("lua/game/game_state")
local GarbageBin = require("lua/game/items/garbage_bin")

-- CATALOGUE indices:
-- 1-6: plant types, 7: Watering Can, 8: Grafter, 9: Intercom,
-- 10: Expand Slot, 11: Sneakers, 12: Heat Lamps, 13: Marketing

local INTERCOM_IDX = 9

local function make_buy(ctx)
    return BuyScene.new(ctx.gs, ctx.input, ctx.sm, ctx.sm.current)
end

-- Test: buy intercom deducts $50
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.currency == 50,
        "currency should be 50 after buying Intercom ($50), got " .. tostring(ctx.gs.currency))
    print("PASS: intercom: buy deducts $50")
end

-- Test: buy intercom gives Intercom in player hand
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 100
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.player.held_item ~= nil,
        "player should hold something after buying Intercom")
    assert(ctx.gs.player.held_item.name == "Intercom",
        "held item should be 'Intercom', got " .. tostring(ctx.gs.player.held_item and ctx.gs.player.held_item.name))
    print("PASS: intercom: buy gives Intercom in hand")
end

-- Test: cannot buy intercom with insufficient currency
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local buy = make_buy(ctx)
    ctx.gs.currency = 49
    buy.selected = INTERCOM_IDX
    buy:_confirm()
    assert(ctx.gs.currency == 49,
        "currency should be unchanged when broke, got " .. tostring(ctx.gs.currency))
    assert(ctx.gs.player.held_item == nil,
        "player should not receive Intercom when broke")
    print("PASS: intercom: cannot buy with insufficient currency")
end

-- Test: intercom is carriable (pick up and put down)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local ic = Intercom.new(nil)
    ctx.gs.store.slots[4].item = ic
    ctx.gs.player.x = 700   -- slot 4 center

    ctx.input:press("move_up")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.player.held_item == ic,
        "player should hold the Intercom after picking it up")
    assert(ctx.gs.store.slots[4].item == nil,
        "slot 4 should be empty after pick-up")
    print("PASS: intercom: is carriable (pick up)")
end

-- Test: intercom can be discarded in garbage bin
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local ic = Intercom.new(nil)
    ctx.gs.player.held_item = ic
    ctx.gs.player.x = 300   -- slot 2 = GarbageBin

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.player.held_item == nil,
        "intercom should be discarded into garbage bin")
    print("PASS: intercom: can be discarded in garbage bin")
end

-- Test: GameState serializes intercom as {type="intercom"}
do
    local gs = GameState.new()
    local ic = Intercom.new(nil)
    gs.store.slots[4].item = ic
    local data = GameState.to_save(gs)
    assert(data.slots[4].item ~= nil,
        "slot 4 item should be in save data")
    assert(data.slots[4].item.type == "intercom",
        "save data type should be 'intercom', got " .. tostring(data.slots[4].item.type))
    print("PASS: intercom: serializes as type='intercom'")
end

-- Test: GameState from_save restores intercom with correct name
do
    local gs = GameState.new()
    gs.store.slots[4].item = Intercom.new(nil)
    local data = GameState.to_save(gs)
    local gs2  = GameState.from_save(data)
    local item = gs2.store.slots[4].item
    assert(item ~= nil,
        "slot 4 item should exist after from_save")
    assert(item.name == "Intercom",
        "restored item name should be 'Intercom', got " .. tostring(item and item.name))
    print("PASS: intercom: from_save restores Intercom in slot")
end

-- Test: draw_bubble is a no-op when _customer_getter is nil (no crash)
do
    local ic = Intercom.new(nil)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble no-ops with nil getter")
end

-- Test: draw_bubble is a no-op when customer bubble not visible
do
    local customer = {
        bubble      = { visible = false },
        done_talking = true,
        state       = "waiting",
        plant_type  = 1,
    }
    local ic = Intercom.new(function() return customer end)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic.sprite.width = 120
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble no-ops when customer bubble not visible")
end

-- Test: draw_bubble does not crash when customer is in display state
do
    local customer = {
        bubble      = { visible = true },
        done_talking = true,
        state       = "waiting",
        plant_type  = 1,
    }
    local ic = Intercom.new(function() return customer end)
    ic.sprite.x = 0
    ic.sprite.y = 600
    ic.sprite.width = 120
    ic:draw_bubble()
    print("PASS: intercom: draw_bubble runs without error in display state")
end

-- Test: _wire_intercom rewires customer getter after save/load
do
    local gs = GameState.new()
    gs.store.slots[4].item = Intercom.new(nil)
    local data = GameState.to_save(gs)
    local gs2  = GameState.from_save(data)

    -- Loaded intercom has nil getter until StoreScene wires it
    local ic_before = gs2.store.slots[4].item
    assert(ic_before._customer_getter == nil,
        "loaded intercom should have nil getter before wiring")

    -- StoreScene with from_save=true wires the getter in _setup_store
    local ctx = runner.setup(function(_gs, input, sm)
        return StoreScene.new(gs2, input, sm, true)
    end)

    local ic_after = gs2.store.slots[4].item
    assert(ic_after._customer_getter ~= nil,
        "intercom getter should be set after StoreScene wiring")
    print("PASS: intercom: _wire_intercom sets getter after save/load")
end

print("ALL TESTS PASSED")
