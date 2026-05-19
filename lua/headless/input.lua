-- HeadlessInput: a scriptable drop-in replacement for lua/core/input.lua.
-- State is driven by explicit test calls (press/hold/release) rather than
-- love.keyboard.isDown, so it works in a windowless/headless LOVE process.

local HeadlessInput = {}
HeadlessInput.__index = HeadlessInput

-- Creates a new instance with empty state and no queued actions.
function HeadlessInput.new()
    return setmetatable({
        _down    = {},   -- actions currently held down
        _pressed = {},   -- actions that triggered a rising edge this frame
        _queued  = {},   -- actions queued by press() for the next update()
    }, HeadlessInput)
end

-- Queue a single-frame press: on the next update() the action will be
-- _down=true and _pressed=true; the frame after (without another press()
-- call) it returns to not-down.
function HeadlessInput:press(action)
    self._queued[action] = true
end

-- Mark action as held down indefinitely (no pressed edge after the first
-- frame it transitions in).  Stays down until release() is called.
function HeadlessInput:hold(action)
    self._down[action] = true
end

-- Clear action from down state entirely.
function HeadlessInput:release(action)
    self._down[action]   = nil
    self._queued[action] = nil
end

-- Advance one frame.  Called once per tick by the runner before scene:update().
-- Edge-triggered semantics mirror lua/core/input.lua:
--   _pressed  = actions that just transitioned from not-down → down
--   _down     = actions currently held (includes queued presses, only for this frame)
function HeadlessInput:update()
    local new_pressed = {}
    local new_down    = {}

    -- Keep actions that are held via hold().
    for action, flag in pairs(self._down) do
        if flag then
            new_down[action] = true
        end
    end

    -- Apply queued single-frame presses.
    for action in pairs(self._queued) do
        if not new_down[action] then
            -- Rising edge: was not already down, so mark pressed.
            new_pressed[action] = true
        end
        new_down[action] = true
    end

    -- Queued presses are consumed after one frame.
    self._queued  = {}
    self._down    = new_down
    self._pressed = new_pressed
end

-- Returns true if action is currently held down (mirrors Input:is_down).
function HeadlessInput:is_down(action)
    return self._down[action] == true
end

-- Returns true only on the frame the action first went down (mirrors Input:pressed).
function HeadlessInput:pressed(action)
    return self._pressed[action] == true
end

return HeadlessInput
