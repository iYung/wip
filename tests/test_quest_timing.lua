math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local SCRIPTS    = require("lua/game/data/customer_scripts")

-- ── helpers (same pattern as test_balance.lua) ─────────────────────────────

local function walk_to(ctx, target_x, elapsed)
    while math.abs(ctx.gs.player.x - target_x) > 5 do
        local before = ctx.gs.player.x - target_x
        if ctx.gs.player.x < target_x then
            ctx.input:hold("move_right")
            ctx.input:release("move_left")
        else
            ctx.input:hold("move_left")
            ctx.input:release("move_right")
        end
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60
        -- at high speed tiers a single tick can step past the 5px snap
        -- window and ping-pong forever; crossing the target counts as arrived
        local after = ctx.gs.player.x - target_x
        if before * after < 0 then
            break
        end
    end
    ctx.input:release("move_right")
    ctx.input:release("move_left")
    return elapsed
end

local function sell_plant(ctx, plant_type, elapsed)
    while true do
        elapsed = runner.fast_forward_until(ctx, function()
            return ctx.sm.current._customer:arrived()
        end, elapsed, 2000)
        if ctx.sm.current._customer.plant_type ~= plant_type then
            ctx.input:press("pick_up_down")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60
        else
            while not ctx.sm.current._customer:on_last_message() do
                elapsed = runner.fast_forward_until(ctx, function()
                    return ctx.sm.current._customer:line_complete()
                end, elapsed)
                ctx.input:press("interact")
                runner.tick(ctx.input, ctx.sm, 1, 1/60)
                elapsed = elapsed + 1/60
            end
            ctx.input:press("interact")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60
            while ctx.sm.current._customer.state == "talking_after" do
                elapsed = runner.fast_forward_until(ctx, function()
                    return ctx.sm.current._customer:line_complete()
                end, elapsed)
                ctx.input:press("interact")
                runner.tick(ctx.input, ctx.sm, 1, 1/60)
                elapsed = elapsed + 1/60
            end
            return elapsed
        end
    end
end

-- ── setup ──────────────────────────────────────────────────────────────────

local STARTING_CURRENCY = 10

local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.currency = STARTING_CURRENCY

local elapsed    = 0
local milestones = {}   -- "id:chapter" -> elapsed seconds

local WATERING_CAN_X = 100
local PLANT_SLOT_X   = 700
local CASHIER_X      = -200

-- Optimistic check: mark a chapter eligible (and immediately "seen") as soon
-- as its trigger fires and all prior chapters are already seen.
local function check_milestones()
    for _, s in ipairs(SCRIPTS) do
        local key = s.id .. ":" .. s.chapter
        if not milestones[key] then
            local t = s.trigger
            if (ctx.gs.stage3_counts[t.plant_type] or 0) >= t.count then
                local ok = true
                for ch = 1, s.chapter - 1 do
                    if not milestones[s.id .. ":" .. ch] then
                        ok = false; break
                    end
                end
                if ok then
                    milestones[key] = elapsed
                    ctx.gs.seen_scripts[key] = true
                end
            end
        end
    end
end

-- ── plant schedule ─────────────────────────────────────────────────────────
-- Grow each plant type until stage3_counts[pt] reaches `target`.
-- Only the current plant type is unlocked so random customers always match.
-- Sequential order satisfies all chapter dependencies in one pass.
local PLANT_DATA = require("lua/game/data/plant_data")

local schedule = {
    { pt = 1, target = 3  },   -- Grass  >= 3   → sage:1 (immediate), sage:2
    { pt = 2, target = 36 },   -- Cactus >= 36  → frogsby:1 (>=2), sage:3 (>=4), frogsby:2 (>=9), glen:1 (>=9), mechafrog:3 (>=36)
    { pt = 3, target = 30 },   -- Rose   >= 30  → sage:4 (>=2), mira:1 (>=6), mayor_bloom:1 (>=9), mayor_bloom:2 (>=12), mayor_bloom:3 (>=30)
    { pt = 4, target = 12 },   -- Tulip  >= 12  → mira:2 (>=3), dottie:1 (>=3), dottie:2 (>=6), frogsby:3 (>=9), glen:2 (>=12)
    { pt = 5, target = 30 },   -- Daisy  >= 30  → mechafrog:1 (>=3), dottie:3 (>=5), glen:3 (>=12), collector:1 (>=30)
    { pt = 6, target = 5  },   -- Lotus  >= 5   → collector:2 (>=5)
    { pt = 1, target = 60 },   -- Grass  >= 60  → mechafrog:2 (>=60)
}

check_milestones()  -- sage:1 triggers at count=0, fires before first grow

local current_pt = 1   -- track the plant being grown for the earn-until-afford loop

for _, step in ipairs(schedule) do
    local pt     = step.pt
    local target = step.target

    -- If switching to a new plant type, earn enough to afford it first
    if pt ~= current_pt then
        local unlock_cost = PLANT_DATA[pt].cost
        while ctx.gs.currency < unlock_cost do
            ctx.gs.unlocked_plants = { [current_pt] = true }
            if ctx.gs.store.slots[4].item == nil
            or ctx.gs.store.slots[4].item.plant_type ~= current_pt then
                ctx.gs.store.slots[4].item = Plant.new(current_pt)
            end

            elapsed = walk_to(ctx, WATERING_CAN_X, elapsed)
            ctx.input:press("pick_up_down")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60

            elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
            elapsed = runner.fast_forward_until(ctx, function()
                return ctx.gs.store.slots[4].item ~= nil
                   and ctx.gs.store.slots[4].item.ready
            end, elapsed, 5000)
            ctx.input:press("interact")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60

            elapsed = runner.fast_forward_until(ctx, function()
                return ctx.gs.store.slots[4].item ~= nil
                   and ctx.gs.store.slots[4].item.ready
            end, elapsed, 5000)
            ctx.input:press("interact")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60

            check_milestones()

            elapsed = walk_to(ctx, WATERING_CAN_X, elapsed)
            ctx.input:press("pick_up_down")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60

            elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
            ctx.input:press("pick_up_down")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60

            elapsed = walk_to(ctx, CASHIER_X, elapsed)
            elapsed = sell_plant(ctx, current_pt, elapsed)

            elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
            ctx.gs.store.slots[4].item = Plant.new(current_pt)

            check_milestones()
        end
        ctx.gs.currency = ctx.gs.currency - unlock_cost
        current_pt = pt
    end

    ctx.gs.unlocked_plants = { [pt] = true }
    if ctx.gs.store.slots[4].item == nil
    or ctx.gs.store.slots[4].item.plant_type ~= pt then
        ctx.gs.store.slots[4].item = Plant.new(pt)
    end

    while (ctx.gs.stage3_counts[pt] or 0) < target do
        -- 1. pick up watering can from slot 1
        elapsed = walk_to(ctx, WATERING_CAN_X, elapsed)
        ctx.input:press("pick_up_down")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60

        -- 2. water: stage 1 → 2
        elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
        elapsed = runner.fast_forward_until(ctx, function()
            return ctx.gs.store.slots[4].item ~= nil
               and ctx.gs.store.slots[4].item.ready
        end, elapsed, 5000)
        ctx.input:press("interact")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60

        -- 3. water: stage 2 → 3  (increments stage3_counts)
        elapsed = runner.fast_forward_until(ctx, function()
            return ctx.gs.store.slots[4].item ~= nil
               and ctx.gs.store.slots[4].item.ready
        end, elapsed, 5000)
        ctx.input:press("interact")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60

        check_milestones()

        -- 4. return watering can to slot 1
        elapsed = walk_to(ctx, WATERING_CAN_X, elapsed)
        ctx.input:press("pick_up_down")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60

        -- 5. pick up stage-3 plant
        elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
        ctx.input:press("pick_up_down")
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60

        -- 6. sell
        elapsed = walk_to(ctx, CASHIER_X, elapsed)
        elapsed = sell_plant(ctx, pt, elapsed)

        -- 7. replant
        elapsed = walk_to(ctx, PLANT_SLOT_X, elapsed)
        ctx.gs.store.slots[4].item = Plant.new(pt)

        check_milestones()
    end
end

-- ── report ─────────────────────────────────────────────────────────────────

local PLANT_NAMES = { "Grass", "Cactus", "Rose", "Tulip", "Daisy", "Golden Lotus" }

local sorted = {}
for _, s in ipairs(SCRIPTS) do
    sorted[#sorted + 1] = {
        key     = s.id .. ":" .. s.chapter,
        name    = s.name,
        chapter = s.chapter,
        trigger = s.trigger,
        t       = milestones[s.id .. ":" .. s.chapter],
    }
end
table.sort(sorted, function(a, b)
    return (a.t or 1e9) < (b.t or 1e9)
end)

print("[quests] quest eligibility timeline  (single slot, optimistic serve):")
print(string.format("  %-20s  %-3s  %8s  %-12s  trigger", "name", "ch", "time", "clock"))
print(string.rep("-", 72))
local last_t = 0
for _, q in ipairs(sorted) do
    local t = q.t or 0
    if t > last_t then last_t = t end
    print(string.format("  %-20s  ch%d  %6.1f s  %dm %02.0f s  %s >= %d",
        q.name, q.chapter, t,
        math.floor(t / 60), t % 60,
        PLANT_NAMES[q.trigger.plant_type], q.trigger.count))
end
print(string.rep("-", 72))
print(string.format("  All quests by:  %6.1f s  (%.1f min)", last_t, last_t / 60))

for _, s in ipairs(SCRIPTS) do
    local key = s.id .. ":" .. s.chapter
    assert(milestones[key], "quest not reached: " .. key)
end

-- ── no-dismiss test for sage:1 ────────────────────────────────────────────
do
    local nd_ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local nd_elapsed = 0

    -- sage:1 trigger count=0 fires immediately; wait for customer to arrive.
    nd_elapsed = runner.fast_forward_until(nd_ctx, function()
        return nd_ctx.sm.current._customer:arrived()
    end, nd_elapsed, 600)

    -- Move player into cashier zone (x < 0) so the E branch is reached.
    nd_elapsed = walk_to(nd_ctx, CASHIER_X, nd_elapsed)

    assert(nd_ctx.sm.current._active_script_key == "sage:1",
        "expected sage:1 active, got: " .. tostring(nd_ctx.sm.current._active_script_key))

    -- Press E — must not dismiss a no_dismiss quest.
    nd_ctx.input:press("pick_up_down")
    runner.tick(nd_ctx.input, nd_ctx.sm, 1, 1/60)
    nd_elapsed = nd_elapsed + 1/60

    assert(nd_ctx.sm.current._customer:arrived(),
        "sage:1 customer was dismissed by E — no_dismiss should have blocked it")
    assert(nd_ctx.sm.current._active_script_key == "sage:1",
        "active_script_key was cleared by E — no_dismiss should have blocked it")
    assert(not nd_ctx.sm.current._script_cooldowns["sage:1"],
        "dismiss cooldown was set for no_dismiss quest — should not have been")

    print("[no-dismiss] sage:1 E-key block: PASS")
end

print("PASS")
