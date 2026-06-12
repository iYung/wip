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

-- Gamepad: _mode defaults to "keyboard"
do
    local input = Input.new({ interact = {"space"} })
    assert(input._mode == "keyboard",
        "_mode should default to 'keyboard', got " .. tostring(input._mode))
    print("PASS: input: _mode defaults to keyboard")
end

-- Gamepad: key_for returns gamepad label when mode is "gamepad"
do
    local input = Input.new({ move_up={"w"}, move_down={"s"}, move_left={"a"}, move_right={"d"}, interact={"space"} })
    input._mode = "gamepad"
    assert(input:key_for("move_up")    == "↑",   "gamepad move_up label should be ↑")
    assert(input:key_for("move_down")  == "↓",   "gamepad move_down label should be ↓")
    assert(input:key_for("move_left")  == "←",   "gamepad move_left label should be ←")
    assert(input:key_for("move_right") == "→",   "gamepad move_right label should be →")
    assert(input:key_for("interact")   == "[A]", "gamepad interact label should be [A]")
    print("PASS: input: key_for returns gamepad labels in gamepad mode")
end

-- Gamepad: key_for still returns keyboard key in keyboard mode
do
    local input = Input.new({ interact = {"space"} })
    assert(input._mode == "keyboard")
    assert(input:key_for("interact") == "space",
        "key_for('interact') in keyboard mode should return 'space'")
    print("PASS: input: key_for returns keyboard key in keyboard mode")
end

-- Gamepad: joystick button press drives _pressed and _down
do
    local input = Input.new({ interact = {"space"} })
    love.keyboard.isDown = function() return false end
    local btn_a = false
    input._joystick = {
        isConnected    = function() return true end,
        getGamepadAxis = function(_, _) return 0 end,
        isGamepadDown  = function(_, b) return b == "a" and btn_a end,
    }
    input:update()
    assert(not input:is_down("interact"), "interact should be up before gamepad A pressed")
    btn_a = true
    input:update()
    assert(input:is_down("interact"),    "interact should be down when gamepad A held")
    assert(input:pressed("interact"),    "interact should be pressed on first frame of gamepad A")
    input:update()
    assert(input:is_down("interact"),    "interact stays down while gamepad A held")
    assert(not input:pressed("interact"),"interact not pressed on repeated frames")
    print("PASS: input: gamepad A button drives interact _down and _pressed")
end

-- Gamepad: left-stick axis drives movement actions
do
    local input = Input.new({ move_up={"w"}, move_down={"s"} })
    love.keyboard.isDown = function() return false end
    local axis_y = 0
    input._joystick = {
        isConnected    = function() return true end,
        getGamepadAxis = function(_, name)
            if name == "lefty" then return axis_y end
            return 0
        end,
        isGamepadDown  = function() return false end,
    }
    input:update()
    assert(not input:is_down("move_up"),   "move_up should be up at axis 0")
    assert(not input:is_down("move_down"), "move_down should be up at axis 0")
    axis_y = -0.9
    input:update()
    assert(input:is_down("move_up"),       "move_up should be down when lefty < -0.3")
    assert(not input:is_down("move_down"), "move_down should be up when lefty < -0.3")
    axis_y = 0.9
    input:update()
    assert(not input:is_down("move_up"),   "move_up should be up when lefty > 0.3")
    assert(input:is_down("move_down"),     "move_down should be down when lefty > 0.3")
    print("PASS: input: left-stick Y axis drives move_up and move_down")
end

-- Gamepad: mode auto-switches to "gamepad" when axis input detected
do
    local input = Input.new({ move_up={"w"} })
    love.keyboard.isDown = function() return false end
    local axis_y = 0
    input._joystick = {
        isConnected    = function() return true end,
        getGamepadAxis = function(_, name)
            if name == "lefty" then return axis_y end
            return 0
        end,
        isGamepadDown  = function() return false end,
    }
    assert(input._mode == "keyboard", "mode should start as keyboard")
    input:update()
    assert(input._mode == "keyboard", "mode should stay keyboard when no gamepad input")
    axis_y = -0.9
    input:update()
    assert(input._mode == "gamepad", "mode should switch to gamepad when axis input detected")
    print("PASS: input: mode auto-switches to gamepad on stick input")
end

-- Gamepad: disconnected joystick does not affect state
do
    local input = Input.new({ interact = {"space"} })
    love.keyboard.isDown = function() return false end
    input._joystick = {
        isConnected    = function() return false end,
        getGamepadAxis = function() return 0 end,
        isGamepadDown  = function() return true end,  -- would fire if polled
    }
    input:update()
    assert(not input:is_down("interact"), "disconnected joystick should not drive actions")
    assert(input._mode == "keyboard",     "mode should not switch for disconnected joystick")
    print("PASS: input: disconnected joystick is ignored")
end

print("ALL TESTS PASSED")
