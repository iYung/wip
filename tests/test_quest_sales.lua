math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")
local Plant      = require("lua/game/items/plant")
local SCRIPTS    = require("lua/game/data/customer_scripts")

-- ── counters (declared early so all closures can close over them) ──────────

local sales        = { n = 0 }
local sales_by_pt  = {}
local current_pt   = 1

-- ── helpers ────────────────────────────────────────────────────────────────

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
        local after = ctx.gs.player.x - target_x
        if before * after < 0 then break end
    end
    ctx.input:release("move_right")
    ctx.input:release("move_left")
    return elapsed
end

-- Returns elapsed, and increments total_sales by reference via a wrapper table.
local function sell_plant(ctx, plant_type, elapsed, sales_ref)
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
            sales_ref.n = sales_ref.n + 1
            sales_by_pt[plant_type] = (sales_by_pt[plant_type] or 0) + 1
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
local milestones = {}   -- "id:chapter" -> { n, pt, by_pt snapshot }

local WATERING_CAN_X = 100
local PLANT_SLOT_X   = 700
local CASHIER_X      = -200

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
                    local snap = {}
                    for p, c in pairs(sales_by_pt) do snap[p] = c end
                    milestones[key] = { n = sales.n, pt = current_pt, by_pt = snap }
                    ctx.gs.seen_scripts[key] = true
                end
            end
        end
    end
end

-- ── plant schedule ─────────────────────────────────────────────────────────

local PLANT_DATA = require("lua/game/data/plant_data")

local schedule = {
    { pt = 1, target = 3  },
    { pt = 2, target = 36 },
    { pt = 3, target = 30 },
    { pt = 4, target = 18 },
    { pt = 5, target = 32 },
    { pt = 6, target = 5  },
    { pt = 1, target = 60 },
}

check_milestones()  -- sage:1 triggers at count=0, fires before first sale

for _, step in ipairs(schedule) do
    local pt     = step.pt
    local target = step.target

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
            elapsed = sell_plant(ctx, current_pt, elapsed, sales)

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
        elapsed = sell_plant(ctx, pt, elapsed, sales)

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
        m       = milestones[s.id .. ":" .. s.chapter],
    }
end
table.sort(sorted, function(a, b)
    return ((a.m and a.m.n) or 1e9) < ((b.m and b.m.n) or 1e9)
end)

print("[quest-sales] chapter unlock curve  (total sales at trigger, single slot):")
print(string.format("  %-20s  %-3s  %6s  %-12s  trigger", "name", "ch", "sales", "selling"))
print(string.rep("-", 72))
local last_n = 0
for _, q in ipairs(sorted) do
    local n      = q.m and q.m.n  or 0
    local pt     = q.m and q.m.pt or 0
    local by_pt  = q.m and q.m.by_pt or {}
    if n > last_n then last_n = n end
    print(string.format("  %-20s  ch%d  %6d  %-12s  %s >= %d",
        q.name, q.chapter, n,
        PLANT_NAMES[pt] or "?",
        PLANT_NAMES[q.trigger.plant_type], q.trigger.count))
    local parts = {}
    for i = 1, #PLANT_NAMES do
        if (by_pt[i] or 0) > 0 then
            parts[#parts + 1] = PLANT_NAMES[i] .. ":" .. by_pt[i]
        end
    end
    print(string.format("  %s", table.concat(parts, "  ")))
end
print(string.rep("-", 72))
print(string.format("  All chapters by: %d sales", last_n))

for _, s in ipairs(SCRIPTS) do
    local key = s.id .. ":" .. s.chapter
    assert(milestones[key], "chapter not reached: " .. key)
end

print("PASS")
