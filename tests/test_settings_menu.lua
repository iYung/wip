local _played = {}
package.loaded["lua/game/sound"] = {
    set_sfx_volume = function() end,
    set_music_volume = function() end,
    play = function(name) table.insert(_played, name) end,
}
local function last_sound() return _played[#_played] end
local function clear_sounds() _played = {} end

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
sim_key(m, "down")  -- 4->5
sim_key(m, "down")  -- 5->6
sim_key(m, "down")  -- 6->7
sim_key(m, "down")  -- 7->1 (wrap)
assert(m.selected == 1, "down from last item should wrap to 1, got " .. m.selected)
print("PASS: down wrap (7 items)")

-- Test 9: up from 1 wraps to last item
sim_key(m, "up")
assert(m.selected == 7, "up from 1 should wrap to 7, got " .. m.selected)
print("PASS: up wrap (wraps to 7)")

-- Test 10: up navigates upward
sim_key(m, "up")
assert(m.selected == 6, "up from 7 should go to 6, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 5, "up from 6 should go to 5, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 4, "up from 5 should go to 4, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 3, "up from 4 should go to 3, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 2, "up from 3 should go to 2, got " .. m.selected)
sim_key(m, "up")
assert(m.selected == 1, "up from 2 should go to 1, got " .. m.selected)
print("PASS: up navigation (7 rows)")

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

-- Test 14: Exit Settings (index 6) closes the menu
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 6)
sim_key(m, "f")
assert(m.is_open == false, "Exit Settings should close the menu")
print("PASS: Exit Settings closes menu")

-- Test 15: Leave Game (index 7) calls love.event.quit
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 7, "should be on Leave Game")
_quit_called = false
sim_key(m, "f")
assert(_quit_called, "confirming Leave Game should call love.event.quit")
print("PASS: Leave Game calls quit")

-- Test 16: e key also confirms
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
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

-- Test 19: Item count wraps at 7
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 1, "7 downs from 1 should wrap back to 1, got " .. m.selected)
print("PASS: item count wraps at 7")

-- Test 20: Selecting item 4 opens keybind sub-screen
open_clean(m)
sim_key(m, "down")
sim_key(m, "down")
sim_key(m, "down")
assert(m.selected == 4)
sim_key(m, "f")
assert(m._subscreen == "keybinds", "selecting item 4 should open keybinds sub-screen")
assert(m._subscreen_selected == 1, "sub-screen should start at index 1")
print("PASS: item 4 opens keybind sub-screen")

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

-- Restore move_up cleared by the collision test (Test 26) so _all_bound passes
state.keybinds.move_up = "w"

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
m.selected = 4
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
m.selected = 4
m._prev_confirm = false
sim_key(m, "f")
assert(m._subscreen == "keybinds", "should be in sub-screen")
assert(m._subscreen_selected == 1, "_subscreen_selected should reset to 1 on re-entry, got " .. m._subscreen_selected)
print("PASS: sub-screen selected resets to 1 on re-entry (item 4)")

-- Test 36: left on SFX Volume row (index 2) decreases sfx_volume by 10
open_clean(m)
state.sfx_volume = 50
sim_key(m, "down")   -- move to SFX Volume row (index 2)
assert(m.selected == 2, "should be on SFX Volume row")
sim_key(m, "left")
assert(state.sfx_volume == 40, "left on SFX Volume row should decrease sfx_volume by 10, got " .. tostring(state.sfx_volume))
print("PASS: left on SFX Volume row decreases sfx_volume")

-- Test 37: right on SFX Volume row increases sfx_volume by 10
open_clean(m)
state.sfx_volume = 50
sim_key(m, "down")   -- move to SFX Volume row (index 2)
sim_key(m, "right")
assert(state.sfx_volume == 60, "right on SFX Volume row should increase sfx_volume by 10, got " .. tostring(state.sfx_volume))
print("PASS: right on SFX Volume row increases sfx_volume")

-- Test 38: left/right on non-SFX-volume row does not change sfx_volume
open_clean(m)
state.sfx_volume = 50
assert(m.selected == 1, "should be on row 1 (Fullscreen)")
sim_key(m, "left")
sim_key(m, "right")
assert(state.sfx_volume == 50, "left/right on non-SFX-volume row should not change sfx_volume, got " .. tostring(state.sfx_volume))
print("PASS: left/right on non-SFX-volume row leaves sfx_volume unchanged")

-- Test 39: left on Music Volume row (index 3) decreases music_volume by 10
open_clean(m)
state.music_volume = 50
sim_key(m, "down")   -- move to index 2
sim_key(m, "down")   -- move to Music Volume row (index 3)
assert(m.selected == 3, "should be on Music Volume row")
sim_key(m, "left")
assert(state.music_volume == 40, "left on Music Volume row should decrease music_volume by 10, got " .. tostring(state.music_volume))
print("PASS: left on Music Volume row decreases music_volume")

-- Test 40: right on Music Volume row (index 3) increases music_volume by 10
open_clean(m)
state.music_volume = 50
sim_key(m, "down")   -- move to index 2
sim_key(m, "down")   -- move to Music Volume row (index 3)
assert(m.selected == 3, "should be on Music Volume row")
sim_key(m, "right")
assert(state.music_volume == 60, "right on Music Volume row should increase music_volume by 10, got " .. tostring(state.music_volume))
print("PASS: right on Music Volume row increases music_volume")

-- Test 41: left/right on non-music row does not change music_volume
open_clean(m)
state.music_volume = 50
assert(m.selected == 1, "should be on row 1 (Fullscreen)")
sim_key(m, "left")
sim_key(m, "right")
assert(state.music_volume == 50, "left/right on non-music row should not change music_volume, got " .. tostring(state.music_volume))
print("PASS: left/right on non-music row leaves music_volume unchanged")

-- Test 42: up/down navigation plays menu_navigate
open_clean(m)
clear_sounds()
sim_key(m, "down")
assert(last_sound() == "menu_navigate", "down navigation should play menu_navigate, got " .. tostring(last_sound()))
clear_sounds()
sim_key(m, "up")
assert(last_sound() == "menu_navigate", "up navigation should play menu_navigate, got " .. tostring(last_sound()))
print("PASS: up/down navigation plays menu_navigate")

-- Test 43: confirm plays menu_confirm
open_clean(m)
clear_sounds()
sim_key(m, "f")   -- confirm on Fullscreen/Window (index 1)
assert(last_sound() == "menu_confirm", "confirm should play menu_confirm, got " .. tostring(last_sound()))
print("PASS: confirm plays menu_confirm")

-- Test 44: escape does not play any sound
open_clean(m)
clear_sounds()
sim_key(m, "escape")
assert(#_played == 0, "escape should not play any sound, got " .. tostring(last_sound()))
print("PASS: escape plays no sound")

-- Test 45: volume left/right plays menu_navigate
open_clean(m)
sim_key(m, "down")   -- move to SFX Volume (index 2)
clear_sounds()
sim_key(m, "left")
assert(last_sound() == "menu_navigate", "SFX volume left should play menu_navigate, got " .. tostring(last_sound()))
clear_sounds()
sim_key(m, "right")
assert(last_sound() == "menu_navigate", "SFX volume right should play menu_navigate, got " .. tostring(last_sound()))
sim_key(m, "down")   -- move to Music Volume (index 3)
clear_sounds()
sim_key(m, "left")
assert(last_sound() == "menu_navigate", "Music volume left should play menu_navigate, got " .. tostring(last_sound()))
clear_sounds()
sim_key(m, "right")
assert(last_sound() == "menu_navigate", "Music volume right should play menu_navigate, got " .. tostring(last_sound()))
print("PASS: volume left/right plays menu_navigate")

-- Test 46: keybinds subscreen up/down plays menu_navigate
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 1
clear_sounds()
sim_key(m, "down")
assert(last_sound() == "menu_navigate", "keybinds down should play menu_navigate, got " .. tostring(last_sound()))
clear_sounds()
sim_key(m, "up")
assert(last_sound() == "menu_navigate", "keybinds up should play menu_navigate, got " .. tostring(last_sound()))
print("PASS: keybinds subscreen up/down plays menu_navigate")

-- Test 47: keybinds subscreen confirm plays menu_confirm
open_clean(m)
m._subscreen = "keybinds"
m._subscreen_selected = 1
clear_sounds()
sim_key(m, "f")
assert(last_sound() == "menu_confirm", "keybinds confirm should play menu_confirm, got " .. tostring(last_sound()))
print("PASS: keybinds subscreen confirm plays menu_confirm")

-- Test 48: All bound — confirm Return closes sub-screen
do
    local s48 = SettingsState.new()
    local m48 = SettingsMenu.new(s48, {_map={}})
    m48:open(true)
    m48._subscreen = "keybinds"
    m48._subscreen_selected = 7   -- Return row = #_ACTION_LIST + 1
    m48._prev_sub_confirm = false
    sim_key(m48, "f")
    assert(m48._subscreen == nil, "all bound: confirm Return should close sub-screen, got " .. tostring(m48._subscreen))
    print("PASS: all bound — confirm Return closes sub-screen")
end

-- Test 49: Missing keybind — confirm Return does NOT close sub-screen
do
    local s49 = SettingsState.new()
    local m49 = SettingsMenu.new(s49, {_map={}})
    m49:open(true)
    s49.keybinds.move_up = nil
    m49._subscreen = "keybinds"
    m49._subscreen_selected = 7
    m49._prev_sub_confirm = false
    sim_key(m49, "f")
    assert(m49._subscreen == "keybinds", "missing keybind: confirm Return should NOT close sub-screen, got " .. tostring(m49._subscreen))
    print("PASS: missing keybind — confirm Return does NOT close sub-screen")
end

-- Test 50: Missing keybind — escape (keypressed) does NOT close sub-screen
do
    local s50 = SettingsState.new()
    local m50 = SettingsMenu.new(s50, {_map={}})
    m50:open(true)
    s50.keybinds.move_up = nil
    m50._subscreen = "keybinds"
    m50._capturing = nil
    m50:keypressed("escape")
    assert(m50._subscreen == "keybinds", "missing keybind: keypressed escape should NOT close sub-screen, got " .. tostring(m50._subscreen))
    print("PASS: missing keybind — escape (keypressed) does NOT close sub-screen")
end

-- Test 51: Rebind restores — confirm Return now closes sub-screen
do
    local s51 = SettingsState.new()
    local m51 = SettingsMenu.new(s51, {_map={}})
    m51:open(true)
    s51.keybinds.move_up = nil
    m51._subscreen = "keybinds"
    m51._subscreen_selected = 7
    m51._prev_sub_confirm = false
    sim_key(m51, "f")
    assert(m51._subscreen == "keybinds", "precondition: missing keybind should keep sub-screen open")
    s51.keybinds.move_up = "t"
    m51._subscreen_selected = 7
    m51._prev_sub_confirm = false
    sim_key(m51, "f")
    assert(m51._subscreen == nil, "rebind restores: confirm Return should now close sub-screen, got " .. tostring(m51._subscreen))
    print("PASS: rebind restores — confirm Return now closes sub-screen")
end

love.event.quit = _real_quit
print("ALL TESTS PASSED")
