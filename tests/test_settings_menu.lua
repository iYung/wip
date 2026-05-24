local SettingsMenu = require("lua/game/scenes/settings_menu")

-- Controllable stubs for this test file
local _fullscreen = false
love.window.getFullscreen = function() return _fullscreen end
love.window.setFullscreen = function(v) _fullscreen = v end

local _quit_called = false
local _real_quit = love.event.quit
love.event.quit = function() _quit_called = true end

-- Simulate pressing a key for one frame then releasing it.
-- open() snapshots current key state, so we reset isDown before opening.
local function sim_key(menu, key)
    love.keyboard.isDown = function(k) return k == key end
    menu:update(0)
    love.keyboard.isDown = function() return false end
    menu:update(0)
end

local function open_clean(menu)
    love.keyboard.isDown = function() return false end
    menu:open()
end

-- Test 1: new() creates a closed menu at index 1
local m = SettingsMenu.new()
assert(m.is_open == false, "new menu should be closed")
assert(m.selected == 1, "new menu should start at index 1")
print("PASS: new() initial state")

-- Test 2: open() opens at index 1
m.selected = 2
open_clean(m)
assert(m.is_open == true, "open() should set is_open")
assert(m.selected == 1, "open() should reset selected to 1")
print("PASS: open()")

-- Test 3: close() clears is_open
m:close()
assert(m.is_open == false, "close() should clear is_open")
print("PASS: close()")

-- Test 4: open() with a key held does not fire that key on first update
love.keyboard.isDown = function(k) return k == "escape" end
m:open()  -- _prev_escape snapshotted as true
love.keyboard.isDown = function() return false end
m:update(0)
assert(m.is_open == true, "escape held at open time should not close the menu")
print("PASS: open() snapshots key state (escape)")

-- Test 5: open() with confirm held does not immediately confirm
love.keyboard.isDown = function(k) return k == "f" end
m:open()  -- _prev_confirm snapshotted as true
love.keyboard.isDown = function() return false end
_fullscreen = false
m:update(0)
assert(_fullscreen == false, "f held at open time should not trigger confirm")
print("PASS: open() snapshots key state (confirm)")

-- Test 6: down arrow moves selection from 1 to 2
open_clean(m)
sim_key(m, "down")
assert(m.selected == 2, "down from 1 should select 2, got " .. m.selected)
print("PASS: down navigation")

-- Test 7: down moves from 2 to 3
sim_key(m, "down")
assert(m.selected == 3, "down from 2 should select 3, got " .. m.selected)
print("PASS: down navigation (2->3)")

-- Test 8: down wraps from last item back to 1
sim_key(m, "down")
assert(m.selected == 1, "down from last item should wrap to 1, got " .. m.selected)
print("PASS: down wrap")

-- Test 9: up from 1 wraps to last item
sim_key(m, "up")
assert(m.selected == 3, "up from 1 should wrap to 3, got " .. m.selected)
print("PASS: up wrap")

-- Test 10: up navigates upward
sim_key(m, "up")
assert(m.selected == 2, "up from 3 should go to 2, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 1, "up from 2 should go to 1, got " .. m.selected)
print("PASS: up navigation")

-- Test 11: s key navigates down
open_clean(m)
sim_key(m, "s")
assert(m.selected == 2, "s should navigate down, got " .. m.selected)
print("PASS: s key navigation")

-- Test 12: w key navigates up
sim_key(m, "w")
assert(m.selected == 1, "w should navigate up, got " .. m.selected)
print("PASS: w key navigation")

-- Test 13: escape closes the menu
open_clean(m)
sim_key(m, "escape")
assert(m.is_open == false, "escape should close the menu")
print("PASS: escape closes menu")

-- Test 14: Exit Settings (index 2) closes the menu
open_clean(m)
sim_key(m, "down")
assert(m.selected == 2)
sim_key(m, "f")
assert(m.is_open == false, "Exit Settings should close the menu")
print("PASS: Exit Settings closes menu")

-- Test 15: Leave Game (index 3) calls love.event.quit
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 3, "should be on Leave Game")
_quit_called = false
sim_key(m, "f")
assert(_quit_called, "confirming Leave Game should call love.event.quit")
print("PASS: Leave Game calls quit")

-- Test 16: e key also confirms
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
_quit_called = false
sim_key(m, "e")
assert(_quit_called, "e key should also confirm")
print("PASS: e key confirms")

-- Test 17: Fullscreen/Window (index 1) toggles fullscreen, menu stays open
open_clean(m)
assert(m.selected == 1)
_fullscreen = false
sim_key(m, "f")
assert(_fullscreen == true, "first confirm should toggle fullscreen on")
assert(m.is_open == true, "menu should stay open after fullscreen toggle")
sim_key(m, "f")
assert(_fullscreen == false, "second confirm should toggle fullscreen off")
print("PASS: fullscreen toggle")

-- Test 18: holding a key only fires once (edge-trigger)
open_clean(m)
love.keyboard.isDown = function(k) return k == "down" end
m:update(0)  -- fires once
m:update(0)  -- held, should not fire again
m:update(0)  -- held, should not fire again
love.keyboard.isDown = function() return false end
m:update(0)
assert(m.selected == 2, "held key should only fire once, got selected=" .. m.selected)
print("PASS: edge-triggered navigation")

love.event.quit = _real_quit
print("ALL TESTS PASSED")
