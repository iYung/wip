math.randomseed(42)

local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

local function walk_to(ctx, target_x, elapsed)
    while math.abs(ctx.gs.player.x - target_x) > 5 do
        if ctx.gs.player.x < target_x then
            ctx.input:hold("move_right")
            ctx.input:release("move_left")
        else
            ctx.input:hold("move_left")
            ctx.input:release("move_right")
        end
        runner.tick(ctx.input, ctx.sm, 1, 1/60)
        elapsed = elapsed + 1/60
    end
    ctx.input:release("move_right")
    ctx.input:release("move_left")
    return elapsed
end

local function fast_forward_until(ctx, condition_fn, elapsed)
    local cap = 600
    local iters = 0
    while not condition_fn() do
        if iters >= cap then
            error("fast_forward_until: condition not met after " .. cap .. " simulated seconds")
        end
        runner.tick(ctx.input, ctx.sm, 1, 1.0)
        elapsed = elapsed + 1.0
        iters   = iters + 1
    end
    return elapsed
end

local function sell_plant(ctx, plant_type, elapsed)
    while true do
        elapsed = fast_forward_until(ctx, function()
            return ctx.sm.current._customer:arrived()
        end, elapsed)

        if ctx.sm.current._customer.plant_type ~= plant_type then
            ctx.input:press("pick_up_down")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60
        else
            -- advance through all non-final messages
            while not ctx.sm.current._customer:on_last_message() do
                elapsed = fast_forward_until(ctx, function()
                    return ctx.sm.current._customer:line_complete()
                end, elapsed)
                ctx.input:press("interact")
                runner.tick(ctx.input, ctx.sm, 1, 1/60)
                elapsed = elapsed + 1/60
            end
            -- final press completes the sale
            ctx.input:press("interact")
            runner.tick(ctx.input, ctx.sm, 1, 1/60)
            elapsed = elapsed + 1/60
            -- advance through post-sale after_messages
            while ctx.sm.current._customer.state == "talking_after" do
                elapsed = fast_forward_until(ctx, function()
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

local ctx = runner.setup(function(gs, input, sm)
    return StoreScene.new(gs, input, sm)
end)
ctx.gs.currency = 10
local elapsed = 0

for _ = 1, 3 do
    elapsed = walk_to(ctx, 500, elapsed)
    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, 700, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, 100, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, 700, elapsed)
    elapsed = fast_forward_until(ctx, function()
        return ctx.gs.store.slots[4].item and ctx.gs.store.slots[4].item.ready
    end, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = fast_forward_until(ctx, function()
        return ctx.gs.store.slots[4].item and ctx.gs.store.slots[4].item.ready
    end, elapsed)

    ctx.input:press("interact")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, 100, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, 700, elapsed)
    ctx.input:press("pick_up_down")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60

    elapsed = walk_to(ctx, -200, elapsed)
    elapsed = sell_plant(ctx, 1, elapsed)
end

assert(ctx.gs.currency >= 20,
    "currency should be >= 20 after 3 grass sales, got " .. tostring(ctx.gs.currency))

-- Golden Lotus cycle
elapsed = walk_to(ctx, 500, elapsed)
ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

for _ = 1, 5 do
    ctx.input:press("move_right")
    runner.tick(ctx.input, ctx.sm, 1, 1/60)
    elapsed = elapsed + 1/60
end

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, 700, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, 100, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, 700, elapsed)
elapsed = fast_forward_until(ctx, function()
    return ctx.gs.store.slots[4].item and ctx.gs.store.slots[4].item.ready
end, elapsed)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = fast_forward_until(ctx, function()
    return ctx.gs.store.slots[4].item and ctx.gs.store.slots[4].item.ready
end, elapsed)

ctx.input:press("interact")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, 100, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, 700, elapsed)
ctx.input:press("pick_up_down")
runner.tick(ctx.input, ctx.sm, 1, 1/60)
elapsed = elapsed + 1/60

elapsed = walk_to(ctx, -200, elapsed)
elapsed = sell_plant(ctx, 6, elapsed)

assert(ctx.gs.currency > 10, "currency should have increased from sales")
print(string.format("Golden Lotus sold in %.1f simulated seconds", elapsed))
print("PASS: golden lotus timing")
