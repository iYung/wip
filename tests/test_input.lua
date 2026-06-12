local Input = require("lua/core/input")

-- key_for returns the first key for a known action
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("pick_up_down") == "g",
        "key_for('pick_up_down') should return 'g', got " .. tostring(input:key_for("pick_up_down")))
    print("PASS: input: key_for returns first key for pick_up_down")
end

-- key_for returns the first key for interact
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("interact") == "h",
        "key_for('interact') should return 'h', got " .. tostring(input:key_for("interact")))
    print("PASS: input: key_for returns first key for interact")
end

-- key_for returns nil for an unknown action
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("unknown") == nil,
        "key_for('unknown') should return nil, got " .. tostring(input:key_for("unknown")))
    print("PASS: input: key_for returns nil for unknown action")
end

-- Ghost-interact prevention: a priming update() call after settings closes prevents
-- the held confirm key from registering as a fresh press on the next frame.
-- This matches the fix in main.lua where input:update() is called when is_open
-- flips to false inside settings_menu:update(dt).
do
    local input = Input.new({ interact = {"space"} })
    -- Last frame before settings opened: space not held
    love.keyboard.isDown = function() return false end
    input:update()
    -- Settings is now "open"; input:update() is skipped for several frames.
    -- Player presses space to confirm "Exit Settings" — key is now held.
    love.keyboard.isDown = function(k) return k == "space" end
    -- Settings closes; main.lua calls input:update() once to prime _down (the fix).
    input:update()
    -- Next frame: normal update with space still held
    input:update()
    assert(not input:pressed("interact"),
        "interact should not ghost-fire after priming update with key held at settings close")
    print("PASS: input: priming update after settings-close prevents ghost interact")
end

print("ALL TESTS PASSED")
