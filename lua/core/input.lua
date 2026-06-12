local _PAD_LABELS = {
    move_up    = "↑",
    move_down  = "↓",
    move_left  = "←",
    move_right = "→",
    interact   = "[A]",
}

local Input = {}
Input.__index = Input

function Input.new(key_map)
    local self    = setmetatable({}, Input)
    self._map     = key_map
    self._down    = {}
    self._pressed = {}
    self._mode     = "keyboard"   -- "keyboard" | "gamepad"
    self._joystick = nil          -- active Love2D joystick object or nil
    return self
end

function Input:update()
    local prev_down = self._down
    local new_down = {}
    local new_pressed = {}

    -- keyboard
    for action, keys in pairs(self._map) do
        local down = false
        for _, key in ipairs(keys) do
            if love.keyboard.isDown(key) then
                down = true
                break
            end
        end
        new_down[action] = down
    end

    -- gamepad
    if self._joystick and self._joystick:isConnected() then
        local joy = self._joystick
        local ax = joy:getGamepadAxis("leftx")
        local ay = joy:getGamepadAxis("lefty")
        local pad = {
            move_up    = ay < -0.3 or joy:isGamepadDown("dpup"),
            move_down  = ay >  0.3 or joy:isGamepadDown("dpdown"),
            move_left  = ax < -0.3 or joy:isGamepadDown("dpleft"),
            move_right = ax >  0.3 or joy:isGamepadDown("dpright"),
            interact   = joy:isGamepadDown("a"),
        }
        local any_gamepad = false
        for action, down in pairs(pad) do
            if down then
                any_gamepad = true
                new_down[action] = true
            end
        end
        if any_gamepad and self._mode == "keyboard" then
            self._mode = "gamepad"
        end
    end

    for action in pairs(self._map) do
        if new_down[action] and not prev_down[action] then
            new_pressed[action] = true
        end
    end

    self._down    = new_down
    self._pressed = new_pressed
end

function Input:is_down(action)
    return self._down[action] == true
end

function Input:pressed(action)
    return self._pressed[action] == true
end

function Input:key_for(action)
    if self._mode == "gamepad" then
        return _PAD_LABELS[action]
    end
    local keys = self._map[action]
    return keys and keys[1]
end

return Input
