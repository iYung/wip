-- Stub Sound module before requiring settings_state (which requires lua/game/sound).
-- Track calls so tests can verify that volume setters actually invoke Sound.
-- Evict cached modules so our stub is used regardless of test execution order.
local _sfx_volume_set  = nil
local _music_volume_set = nil
package.loaded["lua/game/sound"] = {
    set_sfx_volume   = function(v) _sfx_volume_set  = v end,
    set_music_volume = function(v) _music_volume_set = v end,
}
package.loaded["lua/game/settings_state"] = nil

local SettingsState = require("lua/game/settings_state")

-- Stub love.window.setFullscreen so toggle_fullscreen() doesn't crash.
love.window.setFullscreen = function() end

-- -------------------------------------------------------------------------
-- Test 1: to_save returns correct values after mutation
-- -------------------------------------------------------------------------
local s1 = SettingsState.new()
s1:set_sfx_volume(40)
s1:set_music_volume(70)
s1:set_keybind("move_up", "i")
s1.fullscreen = true

local saved1 = s1:to_save()
assert(saved1.sfx_volume   == 40,   "to_save: sfx_volume should be 40, got " .. tostring(saved1.sfx_volume))
assert(saved1.music_volume == 70,   "to_save: music_volume should be 70, got " .. tostring(saved1.music_volume))
assert(saved1.fullscreen   == true, "to_save: fullscreen should be true, got " .. tostring(saved1.fullscreen))
assert(saved1.keybinds.move_up == "i", "to_save: move_up should be 'i', got " .. tostring(saved1.keybinds.move_up))
print("PASS: to_save returns correct field values after mutation")

-- -------------------------------------------------------------------------
-- Test 2: to_save returns a keybinds copy, not the original reference
-- -------------------------------------------------------------------------
local s2 = SettingsState.new()
local saved2 = s2:to_save()
assert(saved2.keybinds ~= s2.keybinds, "to_save: keybinds should be a copy, not the same table reference")
-- Mutating the copy must not affect the original
saved2.keybinds.move_up = "z"
assert(s2.keybinds.move_up == "w", "to_save: mutating the copy should not affect the original keybinds")
print("PASS: to_save keybinds is a copy, not the original reference")

-- -------------------------------------------------------------------------
-- Test 3: from_save(nil) falls back to defaults gracefully
-- -------------------------------------------------------------------------
local s3 = SettingsState.from_save(nil)
assert(type(s3) == "table",          "from_save(nil): should return a table")
assert(s3.sfx_volume   == 100,       "from_save(nil): sfx_volume should default to 100")
assert(s3.music_volume == 100,       "from_save(nil): music_volume should default to 100")
assert(s3.fullscreen   == false,     "from_save(nil): fullscreen should default to false")
assert(type(s3.keybinds) == "table", "from_save(nil): keybinds should be a table")
assert(s3.keybinds.move_up == "w",   "from_save(nil): move_up should default to 'w'")
print("PASS: from_save(nil) falls back to defaults gracefully")

-- -------------------------------------------------------------------------
-- Test 4: from_save with a non-table value falls back gracefully
-- -------------------------------------------------------------------------
local s4 = SettingsState.from_save("corrupt_string")
assert(s4.sfx_volume   == 100,   "from_save(string): sfx_volume should default to 100")
assert(s4.music_volume == 100,   "from_save(string): music_volume should default to 100")
assert(s4.fullscreen   == false, "from_save(string): fullscreen should default to false")
print("PASS: from_save(non-table) falls back to defaults gracefully")

-- -------------------------------------------------------------------------
-- Test 5: from_save with partial data fills defaults for missing fields
-- -------------------------------------------------------------------------
local s5 = SettingsState.from_save({ sfx_volume = 30 })
assert(s5.sfx_volume   == 30,   "from_save(partial): sfx_volume should be 30, got " .. tostring(s5.sfx_volume))
assert(s5.music_volume == 100,  "from_save(partial): music_volume should default to 100, got " .. tostring(s5.music_volume))
assert(s5.fullscreen   == false, "from_save(partial): fullscreen should default to false")
assert(s5.keybinds.move_up == "w", "from_save(partial): move_up should default to 'w'")
print("PASS: from_save with partial data fills defaults for missing fields")

-- -------------------------------------------------------------------------
-- Test 6: from_save calls set_sfx_volume so Sound.set_sfx_volume is invoked
-- -------------------------------------------------------------------------
_sfx_volume_set = nil
local s6 = SettingsState.from_save({ sfx_volume = 60 })
assert(s6.sfx_volume == 60, "from_save: sfx_volume should be 60 on the returned object")
assert(_sfx_volume_set == 0.6, "from_save: Sound.set_sfx_volume should have been called with 0.6, got " .. tostring(_sfx_volume_set))
print("PASS: from_save calls Sound.set_sfx_volume via set_sfx_volume setter")

-- -------------------------------------------------------------------------
-- Test 7: from_save calls set_music_volume so Sound.set_music_volume is invoked
-- -------------------------------------------------------------------------
_music_volume_set = nil
local s7 = SettingsState.from_save({ music_volume = 80 })
assert(s7.music_volume == 80, "from_save: music_volume should be 80 on the returned object")
assert(_music_volume_set == 0.8, "from_save: Sound.set_music_volume should have been called with 0.8, got " .. tostring(_music_volume_set))
print("PASS: from_save calls Sound.set_music_volume via set_music_volume setter")

-- -------------------------------------------------------------------------
-- Test 8: from_save only loads keybinds for known actions (unknown keys ignored)
-- -------------------------------------------------------------------------
local s8 = SettingsState.from_save({
    keybinds = {
        move_up   = "t",
        move_down = "g",
        unknown_action = "z",  -- should be silently ignored
    }
})
assert(s8.keybinds.move_up   == "t", "from_save: move_up should be 't', got " .. tostring(s8.keybinds.move_up))
assert(s8.keybinds.move_down == "g", "from_save: move_down should be 'g', got " .. tostring(s8.keybinds.move_down))
assert(s8.keybinds.unknown_action == nil, "from_save: unknown_action should not be added to keybinds")
print("PASS: from_save ignores unknown keybind actions")

-- -------------------------------------------------------------------------
-- Test 9: Full round-trip — to_save → from_save → all fields match
-- -------------------------------------------------------------------------
local src = SettingsState.new()
src:set_sfx_volume(55)
src:set_music_volume(35)
src:set_keybind("move_up",    "i")
src:set_keybind("move_down",  "k")
src:set_keybind("move_left",  "j")
src:set_keybind("move_right", "l")
src.fullscreen = false

local round_tripped = SettingsState.from_save(src:to_save())

assert(round_tripped.sfx_volume   == src.sfx_volume,   "round-trip: sfx_volume mismatch")
assert(round_tripped.music_volume == src.music_volume,  "round-trip: music_volume mismatch")
assert(round_tripped.fullscreen   == src.fullscreen,    "round-trip: fullscreen mismatch")
assert(round_tripped.keybinds.move_up    == "i", "round-trip: move_up should be 'i'")
assert(round_tripped.keybinds.move_down  == "k", "round-trip: move_down should be 'k'")
assert(round_tripped.keybinds.move_left  == "j", "round-trip: move_left should be 'j'")
assert(round_tripped.keybinds.move_right == "l", "round-trip: move_right should be 'l'")
-- keybinds in the round-tripped object must be independent of the source
round_tripped.keybinds.move_up = "x"
assert(src.keybinds.move_up == "i", "round-trip: mutating round-tripped keybinds must not affect source")
print("PASS: full round-trip to_save -> from_save preserves all fields")

-- -------------------------------------------------------------------------
-- Test 10: Round-trip with fullscreen = true
-- -------------------------------------------------------------------------
local src10 = SettingsState.new()
src10.fullscreen = true
local rt10 = SettingsState.from_save(src10:to_save())
assert(rt10.fullscreen == true, "round-trip: fullscreen=true should survive round-trip, got " .. tostring(rt10.fullscreen))
print("PASS: round-trip preserves fullscreen=true")

-- -------------------------------------------------------------------------
-- Test 11: key_map() from a loaded SettingsState reflects saved keybinds
-- -------------------------------------------------------------------------
local ss11 = SettingsState.from_save({
    keybinds = { pick_up_down = "q", interact = "r",
                 move_up = "w", move_down = "s", move_left = "a", move_right = "d" }
})
local map11 = ss11:key_map()
assert(type(map11.pick_up_down) == "table" and map11.pick_up_down[1] == "q",
    "key_map: pick_up_down should be {'q'}, got " .. tostring(map11.pick_up_down and map11.pick_up_down[1]))
assert(type(map11.interact) == "table" and map11.interact[1] == "r",
    "key_map: interact should be {'r'}, got " .. tostring(map11.interact and map11.interact[1]))
print("PASS: key_map() from loaded SettingsState reflects saved keybinds")

-- -------------------------------------------------------------------------
-- Test 12: assigning input._map from a loaded SettingsState makes Input
--          respond to the rebound keys (simulates the main.lua startup fix)
-- -------------------------------------------------------------------------
do
    local CoreInput = require("lua/core/input")
    local inp = CoreInput.new({
        pick_up_down = {"e"},
        interact     = {"f"},
    })
    local ss12 = SettingsState.from_save({
        keybinds = { pick_up_down = "q", interact = "r",
                     move_up = "w", move_down = "s", move_left = "a", move_right = "d" }
    })
    -- Sync input map as main.lua now does on startup
    inp._map = ss12:key_map()

    -- Simulate "r" held down
    local _orig_isDown = love.keyboard.isDown
    love.keyboard.isDown = function(k) return k == "r" end
    inp:update()
    love.keyboard.isDown = _orig_isDown

    assert(inp:pressed("interact"), "input: 'interact' should fire on rebound key 'r'")
    assert(not inp:pressed("pick_up_down"), "input: 'pick_up_down' should not fire when 'q' is not held")
    print("PASS: input._map sync from loaded SettingsState routes rebound keys correctly")
end

print("ALL TESTS PASSED")
