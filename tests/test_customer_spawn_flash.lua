math.randomseed(42)
local runner   = require("lua/headless/runner")
local Customer = require("lua/game/customer")
local config   = require("lua/game/config")

-- Test: customer sprite positioned at exit_x on the same frame as show()
-- (no one-frame flash at the stale position from the previous customer)
--
-- Simulate a previous customer cycle: the sprite.x/y are left at the waiting
-- position (target_x) after the last update().  Then show() is called for a
-- new customer.  The sprite must snap to exit_x immediately, before update()
-- runs, so the first draw does not flash at the stale location.
do
    local U          = config.U
    local CW         = 6 * U   -- 120
    local CH         = 12 * U  -- 240
    local ZONE_WIDTH = config.ZONE_WIDTH  -- 400
    local target_x   = -ZONE_WIDTH / 2   -- -200
    local exit_x     = -(ZONE_WIDTH + 200)  -- -600
    local customer_y = 500

    local customer = Customer.new(target_x, exit_x, customer_y)

    -- Simulate stale sprite position left by a previous customer at target_x.
    customer.sprite.x = target_x - CW / 2
    customer.sprite.y = customer_y - CH / 2 - 20
    customer.sprite.visible = false

    -- Show a new customer — sprite must snap to exit_x before any update().
    customer:show({
        plant_type = 1, name = "Test", messages = {},
        primary_color = {1,1,1,1}, secondary_color = {1,1,1,1},
    })

    local expected_x = exit_x - CW / 2    -- -660
    local expected_y = customer_y - CH / 2 - 20  -- 360

    assert(customer.sprite.x == expected_x,
        "sprite.x should be " .. expected_x .. " immediately after show(), got "
        .. tostring(customer.sprite.x))
    assert(customer.sprite.y == expected_y,
        "sprite.y should be " .. expected_y .. " immediately after show(), got "
        .. tostring(customer.sprite.y))
    print("PASS: customer: sprite positioned at exit_x immediately after show() (no one-frame flash)")
end

print("ALL TESTS PASSED")
