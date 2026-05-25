local SettingsState = require("lua/game/settings_state")

-- Stub love.window.setFullscreen to track calls
local _setFullscreen_last = nil
love.window.setFullscreen = function(v) _setFullscreen_last = v end

-- Test 1: new() defaults fullscreen to false
local s = SettingsState.new()
assert(s.fullscreen == false, "new() should default fullscreen to false")
print("PASS: new() defaults fullscreen to false")

-- Test 2: toggle_fullscreen() sets fullscreen to true and calls love.window.setFullscreen(true)
_setFullscreen_last = nil
s:toggle_fullscreen()
assert(s.fullscreen == true, "first toggle should set fullscreen to true")
assert(_setFullscreen_last == true, "first toggle should call love.window.setFullscreen(true)")
print("PASS: toggle_fullscreen() turns fullscreen on")

-- Test 3: second toggle_fullscreen() sets fullscreen back to false and calls love.window.setFullscreen(false)
_setFullscreen_last = nil
s:toggle_fullscreen()
assert(s.fullscreen == false, "second toggle should set fullscreen back to false")
assert(_setFullscreen_last == false, "second toggle should call love.window.setFullscreen(false)")
print("PASS: toggle_fullscreen() turns fullscreen off")

-- Test 4: keybind defaults — all six bindings present on a fresh SettingsState
local s2 = SettingsState.new()
assert(s2.keybinds.move_up    == "w", "default move_up should be 'w'")
assert(s2.keybinds.move_down  == "s", "default move_down should be 's'")
assert(s2.keybinds.move_left  == "a", "default move_left should be 'a'")
assert(s2.keybinds.move_right == "d", "default move_right should be 'd'")
assert(s2.keybinds.pick_up_down == "e", "default pick_up_down should be 'e'")
assert(s2.keybinds.interact   == "f", "default interact should be 'f'")
print("PASS: keybind defaults are correct")

-- Test 5: set_keybind basic — rebind move_up to "t"
local s3 = SettingsState.new()
s3:set_keybind("move_up", "t")
assert(s3.keybinds.move_up == "t", "set_keybind should update move_up to 't'")
print("PASS: set_keybind basic rebind works")

-- Test 6: collision clearing — binding move_down to "w" clears move_up
local s4 = SettingsState.new()
s4:set_keybind("move_up", "w")   -- ensure move_up == "w"
s4:set_keybind("move_down", "w") -- "w" collides with move_up
assert(s4.keybinds.move_up   == nil, "collision should clear move_up")
assert(s4.keybinds.move_down == "w", "move_down should now be 'w'")
print("PASS: set_keybind clears colliding binding")

-- Test 7: key_map output — action maps to a single-element array
local s5 = SettingsState.new()
local km = s5:key_map()
assert(type(km.move_down) == "table", "key_map move_down should be a table")
assert(km.move_down[1] == "s", "key_map move_down[1] should be 's'")
print("PASS: key_map returns single-element arrays")

-- Test 8: key_map skips nil — nil binding is absent from key_map result
local s6 = SettingsState.new()
s6.keybinds.move_up = nil
local km2 = s6:key_map()
assert(km2.move_up == nil, "key_map should omit actions with nil bindings")
print("PASS: key_map skips nil bindings")

print("ALL TESTS PASSED")
