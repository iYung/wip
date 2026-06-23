local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local WinScene    = require("lua/game/scenes/win_scene")
local GoldenIdol  = require("lua/game/items/golden_idol")

-- Test: GoldenIdol interact with wired factory switches to WinScene
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene = ctx.sm.current
    local win_scene   = store_scene._win_scene
    assert(win_scene ~= nil, "StoreScene should create _win_scene in _setup_store")

    local idol = GoldenIdol.new()
    idol.win_scene_factory = store_scene._win_scene_factory

    idol:interact(ctx.gs.player, ctx.gs.store, ctx.sm)
    assert(ctx.sm.current == win_scene,
        "sm.current should be WinScene after idol interact, got " .. tostring(ctx.sm.current))
    print("PASS: win_scene: idol interact switches to WinScene")
end

-- Test: GoldenIdol interact without factory is a safe no-op
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene = ctx.sm.current
    local idol = GoldenIdol.new()
    -- no factory set
    idol:interact(ctx.gs.player, ctx.gs.store, ctx.sm)
    assert(ctx.sm.current == store_scene,
        "sm.current should remain StoreScene when no factory is set")
    print("PASS: win_scene: idol interact without factory is a no-op")
end

-- Test: pressing cancel in WinScene returns to StoreScene
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene = ctx.sm.current
    local win_scene   = store_scene._win_scene
    ctx.sm:switch(win_scene)
    assert(ctx.sm.current == win_scene, "should be in WinScene before cancel")

    ctx.input:press("cancel")
    runner.tick(ctx.input, ctx.sm)
    assert(ctx.sm.current == store_scene,
        "sm.current should be StoreScene after cancel in WinScene, got " .. tostring(ctx.sm.current))
    print("PASS: win_scene: cancel returns to StoreScene")
end

-- Test: _wire_golden_idol wires an idol sitting in a slot
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene = ctx.sm.current
    local idol = GoldenIdol.new()
    ctx.gs.store.slots[1].item = idol

    store_scene:on_enter()   -- triggers _wire_golden_idol
    assert(idol.win_scene_factory ~= nil,
        "idol in slot should have win_scene_factory after on_enter")
    assert(idol.win_scene_factory() == store_scene._win_scene,
        "factory should return the WinScene instance")
    print("PASS: win_scene: _wire_golden_idol wires idol in slot")
end

-- Test: _wire_golden_idol wires an idol held by the player
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local store_scene       = ctx.sm.current
    local idol              = GoldenIdol.new()
    ctx.gs.player.held_item = idol

    store_scene:on_enter()   -- triggers _wire_golden_idol
    assert(idol.win_scene_factory ~= nil,
        "held idol should have win_scene_factory after on_enter")
    assert(idol.win_scene_factory() == store_scene._win_scene,
        "factory should return the WinScene instance")
    print("PASS: win_scene: _wire_golden_idol wires held idol")
end

-- Test: draw doesn't crash when first_idol_at is nil (fallback path)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local win_scene = ctx.sm.current._win_scene
    assert(ctx.gs.first_idol_at == nil, "first_idol_at should be nil by default")
    ctx.sm:switch(win_scene)   -- calls on_enter
    win_scene:draw()
    print("PASS: win_scene: draw doesn't crash when first_idol_at is nil")
end

-- Test: draw doesn't crash with known elapsed time (minutes + seconds path)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local win_scene = ctx.sm.current._win_scene
    ctx.gs.started_at    = 1000
    ctx.gs.first_idol_at = 1125   -- 2m 5s elapsed
    ctx.sm:switch(win_scene)
    win_scene:draw()
    print("PASS: win_scene: draw doesn't crash with elapsed time set")
end

print("ALL TESTS PASSED")
