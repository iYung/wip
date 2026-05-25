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

print("ALL TESTS PASSED")
