-- Reset any stub injected by earlier test files so we get the real module.
package.loaded["lua/game/sound"] = nil
local Sound = require("lua/game/sound")

-- Test: Sound.load() does not error in headless mode
do
    Sound.load()
    print("PASS: sound: Sound.load() runs without error in headless")
end

-- Test: Sound.play() does not error for a known event name
do
    Sound.play("pick_up")
    print("PASS: sound: Sound.play() runs without error for known name")
end

-- Test: Sound.play() does not error for an unknown event name
do
    Sound.play("nonexistent_event")
    print("PASS: sound: Sound.play() runs without error for unknown name")
end

-- Test: set_sfx_volume sets level without error
do
    Sound.set_sfx_volume(0.5)
    Sound.play("pick_up")
    print("PASS: set_sfx_volume sets level without error")
end

-- Test: set_sfx_volume accepts boundary values
do
    Sound.set_sfx_volume(0)
    Sound.set_sfx_volume(1)
    print("PASS: set_sfx_volume accepts boundary values")
end

-- Test: set_music_volume sets level without error
do
    Sound.set_music_volume(0.7)
    print("PASS: set_music_volume sets level without error")
end

-- Test: set_music_volume accepts boundary values
do
    Sound.set_music_volume(0)
    Sound.set_music_volume(1)
    print("PASS: set_music_volume accepts boundary values")
end

print("ALL TESTS PASSED")
