local SettingsMenu = require("lua/game/scenes/settings_menu")

-- Controllable stubs for this test file
local _fullscreen = false
love.window.getFullscreen = function() return _fullscreen end
love.window.setFullscreen = function(v) _fullscreen = v end

local _quit_called = false
local _real_quit = love.event.quit
love.event.quit = function() _quit_called = true end

-- Simulate pressing a key for one frame then releasing it
local function sim_key(menu, key)
    love.keyboard.isDown = function(k) return k == key end
    menu:update(0)
    love.keyboard.isDown = function() return false end
    menu:update(0)
end

-- Test 1: new() creates a closed menu at index 1
local m = SettingsMenu.new()
assert(m.is_open == false, "new menu should be closed")
assert(m.selected == 1, "new menu should start at index 1")
print("PASS: new() initial state")

-- Test 2: open() opens at index 1 with clean prev flags
m.selected = 2
m:open()
assert(m.is_open == true, "open() should set is_open")
assert(m.selected == 1, "open() should reset selected to 1")
assert(m._prev_up == false and m._prev_down == false, "open() should clear prev flags")
print("PASS: open()")

-- Test 3: close() clears is_open
m:close()
assert(m.is_open == false, "close() should clear is_open")
print("PASS: close()")

-- Test 4: down arrow moves selection from 1 to 2
m:open()
sim_key(m, "down")
assert(m.selected == 2, "down from 1 should select 2, got " .. m.selected)
print("PASS: down navigation")

-- Test 5: down wraps from last item back to 1
sim_key(m, "down")
assert(m.selected == 1, "down from last item should wrap to 1, got " .. m.selected)
print("PASS: down wrap")

-- Test 6: up from 1 wraps to last item
sim_key(m, "up")
assert(m.selected == 2, "up from 1 should wrap to 2, got " .. m.selected)
print("PASS: up wrap")

-- Test 7: up from 2 moves to 1
sim_key(m, "up")
assert(m.selected == 1, "up from 2 should go to 1, got " .. m.selected)
print("PASS: up navigation")

-- Test 8: escape closes the menu
m:open()
sim_key(m, "escape")
assert(m.is_open == false, "escape should close the menu")
print("PASS: escape closes menu")

-- Test 9: confirm on Leave Game (index 2) calls love.event.quit
m:open()
sim_key(m, "down")
assert(m.selected == 2, "should be on Leave Game")
_quit_called = false
sim_key(m, "f")
assert(_quit_called, "confirming Leave Game should call love.event.quit")
print("PASS: Leave Game calls quit")

-- Test 10: e key also confirms
m:open()
sim_key(m, "down")
_quit_called = false
sim_key(m, "e")
assert(_quit_called, "e key should also confirm")
print("PASS: e key confirms")

-- Test 11: confirm on Fullscreen/Window (index 1) toggles fullscreen
m:open()
assert(m.selected == 1)
_fullscreen = false
sim_key(m, "f")
assert(_fullscreen == true, "first confirm should toggle fullscreen on")
assert(m.is_open == true, "menu should stay open after fullscreen toggle")
sim_key(m, "f")
assert(_fullscreen == false, "second confirm should toggle fullscreen off")
print("PASS: fullscreen toggle")

-- Test 12: holding a key only fires once per press (edge-trigger)
m:open()
local nav_count = 0
local original_selected = m.selected
love.keyboard.isDown = function(k) return k == "down" end
m:update(0)  -- first frame: fires
m:update(0)  -- second frame: held, should not fire again
m:update(0)  -- third frame: held, should not fire again
love.keyboard.isDown = function() return false end
m:update(0)
assert(m.selected == 2, "held key should only fire once, got selected=" .. m.selected)
print("PASS: edge-triggered navigation")

love.event.quit = _real_quit
print("ALL TESTS PASSED")
