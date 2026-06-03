local StartScene = require("lua/game/scenes/start_scene")

-- Minimal input stub: pressed() returns true only for the given action
local function make_input(pressed_action)
    return {
        pressed = function(_, action)
            return action == pressed_action
        end
    }
end

local _quit_called     = false
local _settings_opened = false
local _real_quit       = love.event.quit
love.event.quit = function() _quit_called = true end

local function make_scene(pressed_action)
    return StartScene.new(
        {},                                          -- game_state stub
        make_input(pressed_action),
        { switch = function() end },                 -- scene_manager stub
        function() _settings_opened = true end       -- open_settings callback
    )
end

-- Test 1: new() starts at selected = 1
local s = make_scene(nil)
assert(s.selected == 1, "new() should start at selected=1")
print("PASS: new() initial selection")

-- Test 2: no _prev_* edge-detection fields (input module handles that now)
assert(s._prev_up      == nil, "_prev_up should not exist on StartScene")
assert(s._prev_down    == nil, "_prev_down should not exist on StartScene")
assert(s._prev_confirm == nil, "_prev_confirm should not exist on StartScene")
print("PASS: no _prev_* edge-detection fields")

-- Test 3: move_down 1 → 2
s.selected = 1
s.input = make_input("move_down")
s:update(0)
assert(s.selected == 2, "move_down from 1 should go to 2, got " .. s.selected)
print("PASS: move_down 1->2")

-- Test 4: move_down 2 → 3
s:update(0)
assert(s.selected == 3, "move_down from 2 should go to 3, got " .. s.selected)
print("PASS: move_down 2->3")

-- Test 5: move_down wraps from 4 → 1
s.selected = 4
s:update(0)
assert(s.selected == 1, "move_down from 4 should wrap to 1, got " .. s.selected)
print("PASS: move_down wrap 4->1")

-- Test 6: move_up 2 → 1
s.selected = 2
s.input = make_input("move_up")
s:update(0)
assert(s.selected == 1, "move_up from 2 should go to 1, got " .. s.selected)
print("PASS: move_up 2->1")

-- Test 7: move_up wraps from 1 → 4
s:update(0)
assert(s.selected == 4, "move_up from 1 should wrap to 4, got " .. s.selected)
print("PASS: move_up wrap 1->4")

-- Test 8: menu_confirm on item 4 (Exit) calls love.event.quit
local s2 = make_scene("menu_confirm")
s2.selected = 4
_quit_called = false
s2:update(0)
assert(_quit_called, "confirming Exit (item 4) should call love.event.quit")
print("PASS: confirm Exit calls quit")

-- Test 9: menu_confirm on item 3 (Settings) calls open_settings callback
local s3 = make_scene("menu_confirm")
s3.selected = 3
_settings_opened = false
s3:update(0)
assert(_settings_opened, "confirming Settings (item 3) should invoke open_settings")
print("PASS: confirm Settings calls open_settings")

-- Test 10: no action → selection unchanged
local s4 = make_scene(nil)
s4.selected = 2
s4:update(0)
assert(s4.selected == 2, "no input should leave selection unchanged")
print("PASS: no input, selection unchanged")

-- Test 11: _time accumulates with dt
local s5 = make_scene(nil)
s5:update(1.0)
assert(s5._time == 1.0, "_time should be 1.0 after update(1.0), got " .. tostring(s5._time))
s5:update(0.5)
assert(s5._time == 1.5, "_time should be 1.5 after another update(0.5), got " .. tostring(s5._time))
print("PASS: _time accumulates with dt")

love.event.quit = _real_quit
print("ALL TESTS PASSED")
