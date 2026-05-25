local SettingsMenu = require("lua/game/scenes/settings_menu")
local SettingsState = require("lua/game/settings_state")

-- Controllable stubs for this test file
local _setFullscreen_called_with = nil
love.window.setFullscreen = function(v) _setFullscreen_called_with = v end

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

local state = SettingsState.new()

-- Test 1: new() creates a closed menu at index 1
local m = SettingsMenu.new(state, {_map={}})
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
state.fullscreen = false
m:update(0)
assert(state.fullscreen == false, "f held at open time should not trigger confirm")
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
sim_key(m, "down")  -- 3->4
sim_key(m, "down")  -- 4->1 (wrap)
assert(m.selected == 1, "down from last item should wrap to 1, got " .. m.selected)
print("PASS: down wrap")

-- Test 9: up from 1 wraps to last item
sim_key(m, "up")
assert(m.selected == 4, "up from 1 should wrap to 4, got " .. m.selected)
print("PASS: up wrap")

-- Test 10: up navigates upward
sim_key(m, "up")
assert(m.selected == 3, "up from 4 should go to 3, got " .. m.selected)
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

-- Test 14: Exit Settings (index 3) closes the menu
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 3)
sim_key(m, "f")
assert(m.is_open == false, "Exit Settings should close the menu")
print("PASS: Exit Settings closes menu")

-- Test 15: Leave Game (index 4) calls love.event.quit
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 4, "should be on Leave Game")
_quit_called = false
sim_key(m, "f")
assert(_quit_called, "confirming Leave Game should call love.event.quit")
print("PASS: Leave Game calls quit")

-- Test 16: e key also confirms
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
_quit_called = false
sim_key(m, "e")
assert(_quit_called, "e key should also confirm")
print("PASS: e key confirms")

-- Test 17: Fullscreen/Window (index 1) toggles fullscreen, menu stays open
open_clean(m)
assert(m.selected == 1)
state.fullscreen = false
sim_key(m, "f")
assert(state.fullscreen == true, "first confirm should toggle fullscreen on")
assert(m.is_open == true, "menu should stay open after fullscreen toggle")
sim_key(m, "f")
assert(state.fullscreen == false, "second confirm should toggle fullscreen off")
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

-- Test 19: Item count wraps at 4
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 1, "4 downs from 1 should wrap back to 1, got " .. m.selected)
print("PASS: item count wraps at 4")

-- Test 20: Selecting item 2 opens keybind sub-screen
open_clean(m)
sim_key(m, "down")
assert(m.selected == 2)
sim_key(m, "f")
assert(m._subscreen == "keybinds", "selecting item 2 should open keybinds sub-screen")
assert(m._subscreen_selected == 1, "sub-screen should start at index 1")
print("PASS: item 2 opens keybind sub-screen")

-- Test 21: Escape from sub-screen returns to main
m._subscreen = "keybinds"
sim_key(m, "escape")
assert(m._subscreen == nil, "escape should clear _subscreen")
assert(m.is_open == true, "menu should still be open after escaping sub-screen")
print("PASS: escape from sub-screen returns to main")

-- Test 22: Confirm in sub-screen enters capture mode
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 1
sim_key(m, "f")
assert(m._capturing == "move_up", "confirming first sub-screen item should set _capturing to move_up, got " .. tostring(m._capturing))
print("PASS: confirm in sub-screen enters capture mode")

-- Test 23: keypressed sets binding and clears _capturing
m._capturing = "move_up"
m:keypressed("t")
assert(state.keybinds.move_up == "t", "keypressed should set the binding, got " .. tostring(state.keybinds.move_up))
assert(m._capturing == nil, "keypressed should clear _capturing")
print("PASS: keypressed sets binding and clears _capturing")

-- Test 24: keypressed with modifier is ignored
state.keybinds.move_up = "w"
m._capturing = "move_up"
m:keypressed("lshift")
assert(m._capturing == "move_up", "modifier key should not clear _capturing")
assert(state.keybinds.move_up == "w", "modifier key should not change binding")
print("PASS: keypressed with modifier is ignored")

-- Test 25: keypressed escape cancels capture without changing binding
state.keybinds.move_up = "w"
m._capturing = "move_up"
m:keypressed("escape")
assert(state.keybinds.move_up == "w", "escape should not change binding, got " .. tostring(state.keybinds.move_up))
assert(m._capturing == nil, "escape should clear _capturing")
print("PASS: keypressed escape cancels capture without changing binding")

-- Test 26: Collision clears old binding
state.keybinds.move_up = "w"
state.keybinds.move_down = "s"
m._capturing = "move_down"
m:keypressed("w")
assert(state.keybinds.move_down == "w", "move_down should now be bound to w, got " .. tostring(state.keybinds.move_down))
assert(state.keybinds.move_up == nil, "collision should clear old move_up binding, got " .. tostring(state.keybinds.move_up))
print("PASS: collision clears old binding")

-- Test 27: Sub-screen down navigation moves _subscreen_selected from 1 to 2
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 1
m._prev_sub_down = false
sim_key(m, "down")
assert(m._subscreen_selected == 2, "down in sub-screen should move to row 2, got " .. m._subscreen_selected)
print("PASS: sub-screen down navigation")

-- Test 28: Sub-screen down wraps from row 7 (Return) to row 1
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 7
m._prev_sub_down = false
sim_key(m, "down")
assert(m._subscreen_selected == 1, "down from row 7 should wrap to row 1, got " .. m._subscreen_selected)
print("PASS: sub-screen down wrap")

-- Test 29: Sub-screen up from row 1 wraps to row 7 (Return button)
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 1
m._prev_sub_up = false
sim_key(m, "up")
assert(m._subscreen_selected == 7, "up from row 1 should wrap to row 7, got " .. m._subscreen_selected)
print("PASS: sub-screen up wrap to Return")

-- Test 30: Confirming Return button (row 7) exits sub-screen, menu stays open
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 7
m._prev_sub_confirm = false
sim_key(m, "f")
assert(m._subscreen == nil, "confirming Return button should exit sub-screen")
assert(m.is_open == true, "menu should stay open after Return")
print("PASS: Return button exits sub-screen")

-- Test 31: Confirm key held when entering sub-screen does not immediately trigger capture
open_clean(m)
m._subscreen = nil
m.selected = 2
love.keyboard.isDown = function(k) return k == "f" end
m:update(0)   -- enters sub-screen; _prev_sub_confirm snapshotted as true ("f" still down)
m:update(0)   -- sub-screen: confirm held but _prev_sub_confirm=true → should not capture
love.keyboard.isDown = function() return false end
m:update(0)
assert(m._subscreen == "keybinds", "should still be in keybinds sub-screen")
assert(m._capturing == nil, "confirm held at sub-screen entry should not trigger capture")
print("PASS: key-bleed prevention on sub-screen entry")

-- Test 32: keypressed returns true when consuming escape during capture
m._subscreen = "keybinds"
m._capturing = "move_up"
local r32 = m:keypressed("escape")
assert(r32 == true, "keypressed should return true for escape during capture")
assert(m._capturing == nil, "escape should clear _capturing")
print("PASS: keypressed returns true for escape during capture")

-- Test 33: keypressed returns true when consuming escape in sub-screen (not capturing)
m._subscreen = "keybinds"
m._capturing = nil
local r33 = m:keypressed("escape")
assert(r33 == true, "keypressed should return true for escape in sub-screen without capture")
assert(m._subscreen == nil, "escape should exit sub-screen")
print("PASS: keypressed returns true for escape in sub-screen")

-- Test 34: keypressed returns false for modifier during capture
m._subscreen = "keybinds"
m._capturing = "move_up"
local r34 = m:keypressed("lshift")
assert(r34 == false, "keypressed should return false for modifier")
assert(m._capturing == "move_up", "modifier should not clear _capturing")
print("PASS: keypressed returns false for modifier")

-- Test 35: Sub-screen selected resets to 1 when re-entering Keybinds
open_clean(m)
m._subscreen = nil
m._subscreen_selected = 4   -- dirty: simulate having navigated the sub-screen before
m.selected = 2
m._prev_confirm = false
sim_key(m, "f")
assert(m._subscreen == "keybinds", "should be in sub-screen")
assert(m._subscreen_selected == 1, "_subscreen_selected should reset to 1 on re-entry, got " .. m._subscreen_selected)
print("PASS: sub-screen selected resets to 1 on re-entry")

love.event.quit = _real_quit
print("ALL TESTS PASSED")
