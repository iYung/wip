math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

-- Test: factory returns the same BuyScene instance on every call
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local factory = ctx.gs.store.slots[3].item.buy_scene_factory
    local buy1 = factory()
    local buy2 = factory()
    assert(buy1 == buy2,
        "factory should return the same BuyScene instance each call")
    print("PASS: buy_scene: factory returns the same instance each call")
end

-- Test: carousel position persists across visits
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local factory = ctx.gs.store.slots[3].item.buy_scene_factory
    local buy = factory()
    assert(buy.selected == 1, "initial selected should be 1")
    buy.selected = 5
    local buy2 = factory()
    assert(buy2.selected == 5,
        "selected should still be 5 after re-opening, got " .. tostring(buy2.selected))
    print("PASS: buy_scene: carousel position persists across visits")
end

-- Test: _wire_pc_store (save path) reuses the same cached instance
do
    local ctx = runner.setup(function(gs, input, sm)
        -- Simulate a save/load by marking from_save; _setup_store will create
        -- _buy_scene and then call _wire_pc_store, which must reuse it.
        local gs2 = require("lua/game/game_state").from_save(
            require("lua/game/game_state").to_save(gs))
        return StoreScene.new(gs2, input, sm, true)
    end)
    local store_scene = ctx.sm.current
    -- _buy_scene should exist (created in _setup_store)
    assert(store_scene._buy_scene ~= nil,
        "_buy_scene should be cached on StoreScene after save/load")
    -- All wired PCStore slots and held item should point to the same instance
    for _, slot in ipairs(ctx.sm.current.game_state.store.slots) do
        if slot.item and slot.item.name == "PC Store" then
            local got = slot.item.buy_scene_factory()
            assert(got == store_scene._buy_scene,
                "wired PCStore factory should return the cached _buy_scene")
        end
    end
    print("PASS: buy_scene: _wire_pc_store reuses cached instance after save/load")
end

print("ALL TESTS PASSED")
