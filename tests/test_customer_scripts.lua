math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local GarbageBin = require("lua/game/items/garbage_bin")

-- Test: scripted customer spawned when trigger met
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[4] = 5   -- Dottie ch1: trigger plant_type=4, count=5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil, "should return a cfg")
    assert(cfg.id == "dottie", "expected id 'dottie', got " .. tostring(cfg.id))
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
    ctx.gs.stage3_counts[5] = 4   -- Dottie ch2: trigger plant_type=5, count=4
    ctx.gs.seen_scripts = {}
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    local is_dottie_ch2 = cfg and cfg.id == "dottie" and cfg.chapter == 2
    assert(not is_dottie_ch2,
        "Dottie ch2 should not be available before ch1 is seen")
    print("PASS: scripts: chapter 2 not available before chapter 1 seen")
end

-- Test: chapter 2 available after chapter 1 seen
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[4] = 11
    ctx.gs.seen_scripts = { ["dottie:1"] = true }
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil and cfg.id == "dottie" and cfg.chapter == 2,
        "Dottie ch2 should be available after ch1 seen, got " .. tostring(cfg and cfg.id))
    print("PASS: scripts: chapter 2 available after chapter 1 seen")
end

-- Test: seen_scripts written on sale, not on spawn
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5

    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    -- spawn alone should NOT write seen_scripts
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg and cfg.id == "dottie", "precondition: Dottie ch1 qualified")
    assert(ctx.gs.seen_scripts["dottie:1"] == nil,
        "seen_scripts should NOT be written on spawn")

    -- show with empty messages (plant_type=5 = Daisy, what Dottie wants)
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = {}, primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale (Daisy = type 5)
    local plant = Plant.new(5); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.seen_scripts["dottie:1"] == true,
        "seen_scripts['dottie:1'] should be true after sale")
    print("PASS: scripts: seen_scripts written on sale, not on spawn")
end

-- Test: seen_scripts not written on dismiss
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    local cfg = ctx.sm.current:_next_customer_cfg()
    ctx.sm.current._customer:show(cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    ctx.gs.player.x = -200
    ctx.input:press("move_up")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.gs.seen_scripts["dottie:1"] == nil,
        "seen_scripts should NOT be written on dismiss")
    print("PASS: scripts: seen_scripts not written on dismiss")
end

-- Test: dismiss sets cooldown
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    local cfg = ctx.sm.current:_next_customer_cfg()
    ctx.sm.current._customer:show(cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    ctx.gs.player.x = -200
    ctx.input:press("move_up")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._script_cooldowns["dottie:1"] == 3,
        "dismiss should set cooldown to 3, got " .. tostring(ctx.sm.current._script_cooldowns["dottie:1"]))
    print("PASS: scripts: dismiss sets cooldown")
end

-- Test: cooldown decrements per sale, customer returns after 3 sales
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.unlocked_plants = { [1] = true }
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    -- qualify and dismiss Dottie to set cooldown
    local dottie_cfg = ctx.sm.current:_next_customer_cfg()
    assert(dottie_cfg and dottie_cfg.id == "dottie", "precondition: Dottie qualified")
    ctx.sm.current._customer:show(dottie_cfg)
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    ctx.gs.player.x = -200
    ctx.input:press("move_up")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    assert(ctx.sm.current._script_cooldowns["dottie:1"] == 3, "precondition: cooldown=3")

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
    assert(ctx.sm.current._script_cooldowns["dottie:1"] == 2,
        "cooldown should be 2 after sale 1, got " .. tostring(ctx.sm.current._script_cooldowns["dottie:1"]))
    do_grass_sale()
    assert(ctx.sm.current._script_cooldowns["dottie:1"] == 1,
        "cooldown should be 1 after sale 2, got " .. tostring(ctx.sm.current._script_cooldowns["dottie:1"]))
    do_grass_sale()
    assert(ctx.sm.current._script_cooldowns["dottie:1"] == nil,
        "cooldown should be removed after sale 3, got " .. tostring(ctx.sm.current._script_cooldowns["dottie:1"]))

    -- Dottie should be eligible again
    local cfg2 = ctx.sm.current:_next_customer_cfg()
    assert(cfg2 and cfg2.id == "dottie",
        "Dottie should be eligible after cooldown expires, got " .. tostring(cfg2 and cfg2.id))
    print("PASS: scripts: cooldown decrements per sale, customer returns after 3 sales")
end

-- Test: after_messages play after sale before walk-out
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    ctx.sm.current._customer:show({
        plant_type     = 5, name = "Dottie",
        messages       = {},
        after_messages = { "Thanks.", "See ya." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale
    local plant = Plant.new(5); plant.stage = 3
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

-- Test: move_up during talking_after does NOT dismiss the customer
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    ctx.sm.current._customer:show({
        plant_type     = 5, name = "Dottie",
        messages       = {},
        after_messages = { "Thanks.", "See ya." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    -- make the sale
    local plant = Plant.new(5); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after", "precondition: talking_after")

    -- press move_up in the cashier zone while in talking_after
    ctx.input:press("move_up")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "talking_after",
        "move_up during talking_after should NOT dismiss customer, got " .. tostring(ctx.sm.current._customer.state))
    assert(ctx.sm.current._script_cooldowns["dottie:1"] == nil,
        "no cooldown should be set when move_up is a no-op during talking_after")
    print("PASS: scripts: move_up during talking_after does not dismiss customer")
end

-- Test: talking_after state reached via show/arrive/serve
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    -- show a scripted customer with after_messages
    ctx.sm.current._customer:show({
        plant_type     = 5, name = "Dottie",
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
    ctx.gs.stage3_counts[4] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true

    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages   = {},
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)

    local plant = Plant.new(5); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)

    assert(ctx.sm.current._customer.state == "walking_out",
        "no after_messages: customer should walk out immediately on sale, got " .. tostring(ctx.sm.current._customer.state))
    print("PASS: scripts: no after_messages walks out immediately on sale")
end

-- Test: all script entries have a voice_pitch field
do
    local scripts = require("lua/game/data/customer_scripts")
    for _, entry in ipairs(scripts) do
        local p = entry.voice_pitch
        assert(type(p) == "number", "expected voice_pitch number for " .. entry.id .. " ch" .. entry.chapter .. ", got " .. type(p))
        assert(p > 0, "voice_pitch must be positive for " .. entry.id .. " ch" .. entry.chapter)
    end
    print("PASS: scripts: all script entries have a valid voice_pitch field")
end

-- Test: show() stores voice_pitch from cfg onto customer
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = { "Hi." },
        voice_pitch = 1.28,
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    assert(ctx.sm.current._customer._voice_pitch == 1.28,
        "expected _voice_pitch 1.28, got " .. tostring(ctx.sm.current._customer._voice_pitch))
    print("PASS: scripts: show() stores voice_pitch from cfg")
end

-- Test: show() defaults voice_pitch to 1.0 when not provided
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = { "Hi." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    assert(ctx.sm.current._customer._voice_pitch == 1.0,
        "expected _voice_pitch default 1.0, got " .. tostring(ctx.sm.current._customer._voice_pitch))
    print("PASS: scripts: show() defaults _voice_pitch to 1.0 when not in cfg")
end

-- Test: _full_text has no name prefix after show()
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = { "Hello there." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    local ft = ctx.sm.current._customer._full_text
    assert(ft == "Hello there.", "expected 'Hello there.', got '" .. tostring(ft) .. "'")
    assert(not ft:find("Dottie"), "_full_text should not contain customer name")
    print("PASS: scripts: _full_text has no name prefix after show()")
end

-- Test: _full_text has no name prefix after serve()
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = {},
        after_messages = { "I know exactly which page this one gets." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    local plant = Plant.new(5); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    local ft = ctx.sm.current._customer._full_text
    assert(ft == "I know exactly which page this one gets.", "expected raw after_message, got '" .. tostring(ft) .. "'")
    assert(not ft:find("Dottie"), "_full_text should not contain customer name after serve()")
    print("PASS: scripts: _full_text has no name prefix after serve()")
end

-- Test: _full_text has no name prefix after advance_after()
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local elapsed = 0
    ctx.sm.current._customer:show({
        plant_type = 5, name = "Dottie",
        messages = {},
        after_messages = { "First line.", "Second line." },
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })
    elapsed = runner.fast_forward_until(ctx, function()
        return ctx.sm.current._customer:arrived()
    end, elapsed)
    local plant = Plant.new(5); plant.stage = 3
    ctx.gs.player.held_item = plant
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    -- advance to second after_message
    ctx.sm.current._customer:skip_reveal()
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    local ft = ctx.sm.current._customer._full_text
    assert(ft == "Second line.", "expected 'Second line.', got '" .. tostring(ft) .. "'")
    assert(not ft:find("Dottie"), "_full_text should not contain customer name after advance_after()")
    print("PASS: scripts: _full_text has no name prefix after advance_after()")
end

-- Test: Romeo ch1 spawns at 6 cactuses
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[2] = 6   -- Romeo ch1: trigger plant_type=2, count=6
    -- mark all sage chapters seen (sage:3 triggers at 4 cactuses)
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil and cfg.id == "romeo" and cfg.chapter == 1,
        "Romeo ch1 should spawn at 6 cactuses, got " .. tostring(cfg and cfg.id))
    print("PASS: scripts: Romeo ch1 spawns at 6 cactuses")
end

-- Test: Romeo ch1 does not spawn before 6 cactuses
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[2] = 5
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    local is_romeo = cfg and cfg.id == "romeo" and cfg.chapter == 1
    assert(not is_romeo, "Romeo ch1 should not spawn before 6 cactuses")
    print("PASS: scripts: Romeo ch1 does not spawn before 6 cactuses")
end

-- Test: Frogsby ch2 triggers at 4 roses (not 9 cactuses)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[3] = 4   -- Frogsby ch2: trigger plant_type=3, count=4
    ctx.gs.seen_scripts["agent_frogsby:1"] = true
    -- mark all sage chapters seen (sage:4 triggers at 2 roses)
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.seen_scripts["sage:4"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    assert(cfg ~= nil and cfg.id == "agent_frogsby" and cfg.chapter == 2,
        "Frogsby ch2 should trigger at 4 roses, got " .. tostring(cfg and cfg.id))
    print("PASS: scripts: Frogsby ch2 triggers at 4 roses")
end

-- Test: Frogsby ch2 does not trigger at 9 cactuses (old trigger removed)
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    ctx.gs.stage3_counts[2] = 9   -- old trigger: 9 cactuses
    ctx.gs.seen_scripts["agent_frogsby:1"] = true
    ctx.gs.seen_scripts["sage:1"] = true
    ctx.gs.seen_scripts["sage:2"] = true
    ctx.gs.seen_scripts["sage:3"] = true
    ctx.gs.unlocked_plants = {}
    local cfg = ctx.sm.current:_next_customer_cfg()
    local is_frogsby_ch2 = cfg and cfg.id == "agent_frogsby" and cfg.chapter == 2
    assert(not is_frogsby_ch2, "Frogsby ch2 should no longer trigger at 9 cactuses")
    print("PASS: scripts: Frogsby ch2 does not trigger at 9 cactuses")
end

-- Test: new game uses short 0.1-second initial spawn timer (sage:1 active within 2s)
do
    -- sage:1 trigger is count=0, satisfied immediately; do NOT mark it seen.
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)   -- from_save omitted → new game
    end)

    -- Fast-forward 2 simulated seconds (2 ticks of 1s each).
    -- With the 0.1-second initial cooldown the timer fires on the first tick,
    -- so the customer should be active well before a normal 4-second cooldown.
    runner.tick(ctx.input, ctx.sm, 2, 1.0)

    assert(ctx.sm.current._customer:active(),
        "new game: sage:1 should be active within 2s (0.1-second initial cooldown), got state="
        .. tostring(ctx.sm.current._customer.state))
    print("PASS: scripts: new game uses short 0.1-second initial spawn timer")
end

-- Test: loaded save uses normal 4-second initial spawn timer (sage:1 NOT active at 2s)
do
    -- sage:1 trigger is count=0, satisfied immediately; do NOT mark it seen.
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm, true)   -- from_save=true → normal cooldown
    end)

    -- After only 2 simulated seconds the 4-second timer should NOT have fired yet.
    runner.tick(ctx.input, ctx.sm, 2, 1.0)

    assert(not ctx.sm.current._customer:active(),
        "loaded save: sage:1 should NOT be active at 2s (4-second initial cooldown), got state="
        .. tostring(ctx.sm.current._customer.state))

    -- After 5 simulated seconds total (3 more ticks) the timer has fired and
    -- the customer should now be active.
    runner.tick(ctx.input, ctx.sm, 3, 1.0)

    assert(ctx.sm.current._customer:active(),
        "loaded save: sage:1 should be active by 5s (4-second initial cooldown), got state="
        .. tostring(ctx.sm.current._customer.state))
    print("PASS: scripts: loaded save uses normal 4-second initial spawn timer")
end

-- Test: garbage bin in slot 1 does NOT discard item when player is in cashier zone
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    -- place garbage bin in slot 1 (leftmost slot)
    ctx.gs.store.slots[1].item = GarbageBin.new()
    -- give the player a sellable item
    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    -- position player in the cashier zone (x < 0)
    ctx.gs.player.x = -200
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    assert(ctx.gs.player.held_item ~= nil,
        "held item should NOT be discarded when player is in cashier zone (x < 0), even with bin in slot 1")
    print("PASS: garbage bin: cashier zone does not discard when bin is in slot 1")
end

-- Test: garbage bin in slot 1 DOES discard item when player is in shop area over slot 1
do
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    -- place garbage bin in slot 1 (leftmost slot)
    ctx.gs.store.slots[1].item = GarbageBin.new()
    -- give the player a sellable item
    local plant = Plant.new(1); plant.stage = 3
    ctx.gs.player.held_item = plant
    -- position player in the shop area over slot 1 (x >= 0, within the first 200px slot)
    ctx.gs.player.x = 100
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    assert(ctx.gs.player.held_item == nil,
        "held item should be discarded when player is in shop area (x >= 0) over bin in slot 1")
    print("PASS: garbage bin: shop area discards item when bin is in slot 1")
end

print("ALL TESTS PASSED")
