math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")

-- Test: scripted customer spawned when trigger met
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[1] = 1   -- Old Pete ch1: trigger plant_type=1, count=1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil, "should return a cfg")
    assert(cfg.id == "old_pete", "expected id 'old_pete', got " .. tostring(cfg.id))
    assert(cfg.chapter == 1, "expected chapter 1, got " .. tostring(cfg.chapter))
    print("PASS: scripts: scripted customer spawned when trigger met")
end

-- Test: scripted customer not spawned before trigger count
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[1] = 0
    ctx.gs.unlocked_plants = {}   -- disable random-customer fallback
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg == nil or cfg.id == nil,
        "should not return a scripted customer when trigger not met")
    print("PASS: scripts: scripted customer not spawned before trigger count")
end

-- Test: chapter 2 not available before chapter 1 seen
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[2] = 3   -- Old Pete ch2: trigger plant_type=2, count=3
    ctx.gs.seen_scripts = {}
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    local is_pete_ch2 = cfg and cfg.id == "old_pete" and cfg.chapter == 2
    assert(not is_pete_ch2,
        "Old Pete ch2 should not be available before ch1 is seen")
    print("PASS: scripts: chapter 2 not available before chapter 1 seen")
end

-- Test: chapter 2 available after chapter 1 seen
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.stage3_counts[2] = 3
    ctx.gs.seen_scripts = { ["old_pete:1"] = true }
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil and cfg.id == "old_pete" and cfg.chapter == 2,
        "Old Pete ch2 should be available after ch1 seen, got " .. tostring(cfg and cfg.id))
    print("PASS: scripts: chapter 2 available after chapter 1 seen")
end

-- Test: seen_scripts written on sale, not on spawn
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1

    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true
    -- spawn alone should NOT write seen_scripts
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg and cfg.id == "old_pete", "precondition: Old Pete ch1 qualified")
    assert(ctx.gs.seen_scripts["old_pete:1"] == nil,
        "seen_scripts should NOT be written on spawn")

    -- show with empty messages (plant_type=2 = Cactus, what Old Pete wants)
    ctx.sm.current._customer:show({
        plant_type = 2, name = "Old Pete",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale (Cactus = type 2)
    local plant = Plant.new(2); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.seen_scripts["old_pete:1"] == true,
        "seen_scripts['old_pete:1'] should be true after sale")
    print("PASS: scripts: seen_scripts written on sale, not on spawn")
end

-- Test: seen_scripts not written on dismiss
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1

    local cfg = ctx.sm.current:_next_customer_cfg()
    ctx.sm.current._customer:show(cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    ctx.gs.player.x = -200
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.seen_scripts["old_pete:1"] == nil,
        "seen_scripts should NOT be written on dismiss")
    print("PASS: scripts: seen_scripts not written on dismiss")
end

-- Test: dismiss sets cooldown
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    local cfg = ctx.sm.current:_next_customer_cfg()
    ctx.sm.current._customer:show(cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    ctx.gs.player.x = -200
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 3,
        "dismiss should set cooldown to 3, got " .. tostring(ctx.sm.current._script_cooldowns["old_pete:1"]))
    print("PASS: scripts: dismiss sets cooldown")
end

-- Test: cooldown decrements per sale, customer returns after 3 sales
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.unlocked_plants = { [1] = true }
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    -- qualify and dismiss Old Pete to set cooldown
    local pete_cfg = ctx.sm.current:_next_customer_cfg()
    assert(pete_cfg and pete_cfg.id == "old_pete", "precondition: Old Pete qualified")
    ctx.sm.current._customer:show(pete_cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    ctx.gs.player.x = -200
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 3, "precondition: cooldown=3")

    -- helper: sell one stage-3 grass to a random customer
    local function do_grass_sale()
        ctx.sm.current._active_script_key = nil
        ctx.sm.current._customer:show({
            plant_type = 1, name = "Grass Customer",
            messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
        })
        elapsed = runner.fast_forward_until(ctx, function()
            return ctx.sm.current._customer:arrived()
        end, elapsed)
        local p = Plant.new(1); p.stage = 3
        ctx.gs.player.held_item = p
        ctx.gs.player.x = -200
        ctx.input:press("interact")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
    end

    do_grass_sale()
    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 2,
        "cooldown should be 2 after sale 1, got " .. tostring(ctx.sm.current._script_cooldowns["old_pete:1"]))
    do_grass_sale()
    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == 1,
        "cooldown should be 1 after sale 2, got " .. tostring(ctx.sm.current._script_cooldowns["old_pete:1"]))
    do_grass_sale()
    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == nil,
        "cooldown should be removed after sale 3, got " .. tostring(ctx.sm.current._script_cooldowns["old_pete:1"]))

    -- Old Pete should be eligible again
    local cfg2 = ctx.sm.current:_next_customer_cfg()
    assert(cfg2 and cfg2.id == "old_pete",
        "Old Pete should be eligible after cooldown expires, got " .. tostring(cfg2 and cfg2.id))
    print("PASS: scripts: cooldown decrements per sale, customer returns after 3 sales")
end

-- Test: after_messages play after sale before walk-out
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    ctx.sm.current._customer:show({
        plant_type     = 2, name = "Old Pete",
        messages       = {},
        after_messages = { "Thanks.", "See ya." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale
    local plant = Plant.new(2); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after",
        "customer should be in talking_after state after sale, got " .. tostring(ctx.sm.current._customer.state))

    -- advance through first after_message
    ctx.sm.current._customer:skip_reveal()
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after",
        "customer should still be talking_after after first line, got " .. tostring(ctx.sm.current._customer.state))

    -- advance through second (last) after_message
    ctx.sm.current._customer:skip_reveal()
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "walking_out",
        "customer should be walking_out after last after_message, got " .. tostring(ctx.sm.current._customer.state))
    assert(ctx.sm.current._customer.heart_bubble.visible == true,
        "heart_bubble should be visible when walking out after after_messages")
    print("PASS: scripts: after_messages play after sale before walk-out")
end

-- Test: pick_up_down during talking_after does NOT dismiss the customer
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    ctx.sm.current._customer:show({
        plant_type     = 2, name = "Old Pete",
        messages       = {},
        after_messages = { "Thanks.", "See ya." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale
    local plant = Plant.new(2); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after", "precondition: talking_after")

    -- press pick_up_down in the cashier zone while in talking_after
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after",
        "pick_up_down during talking_after should NOT dismiss customer, got " .. tostring(ctx.sm.current._customer.state))
    assert(ctx.sm.current._script_cooldowns["old_pete:1"] == nil,
        "no cooldown should be set when pick_up_down is a no-op during talking_after")
    print("PASS: scripts: pick_up_down during talking_after does not dismiss customer")
end

-- Test: talking_after state reached via show/arrive/serve
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    -- show a scripted customer with after_messages
    ctx.sm.current._customer:show({
        plant_type     = 2, name = "Old Pete",
        messages       = {},
        after_messages = { "Thanks." },
        primary_color  = {1,1,1,1}, secondary_color = {1,1,1,1},
    })

    -- simulate arrival
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    assert(ctx.sm.current._customer.state == "waiting", "precondition: customer arrived (waiting)")

    -- serve the customer (triggers talking_after since after_messages is non-empty)
    ctx.sm.current._customer:serve()

    assert(ctx.sm.current._customer.state == "talking_after",
        "customer should be in talking_after after serve(), got " .. tostring(ctx.sm.current._customer.state))
    print("PASS: scripts: talking_after state reached via show/arrive/serve")
end

-- Test: script with no after_messages walks out immediately on sale (no regression)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[1] = 1
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true

    ctx.sm.current._customer:show({
        plant_type = 2, name = "Old Pete",
        messages   = {},
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    local plant = Plant.new(2); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "walking_out",
        "no after_messages: customer should walk out immediately on sale, got " .. tostring(ctx.sm.current._customer.state))
    print("PASS: scripts: no after_messages walks out immediately on sale")
end

print("ALL TESTS PASSED")
