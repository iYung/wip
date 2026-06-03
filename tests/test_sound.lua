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

-- Test: Sound.update(dt) runs without error
do
    Sound.update(0.016)
    Sound.update(0)
    print("PASS: Sound.update() runs without error")
end

-- Test: Sound.play_music runs without error for known and unknown names
do
    Sound.play_music("menu")
    Sound.play_music("bg")
    Sound.play_music("nonexistent")
    print("PASS: Sound.play_music() runs without error")
end

-- Test: Sound.fade_music runs without error for fade in and fade out
do
    Sound.fade_music("menu", 0, 2)
    Sound.fade_music("bg", 1, 2)
    Sound.fade_music("nonexistent", 0, 1)
    print("PASS: Sound.fade_music() runs without error")
end

-- Test: Sound.stop_music runs without error
do
    Sound.stop_music("menu")
    Sound.stop_music("bg")
    Sound.stop_music("nonexistent")
    print("PASS: Sound.stop_music() runs without error")
end

-- Test: Sound.is_music_playing returns false in headless (stubs return false)
do
    assert(Sound.is_music_playing("menu") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("bg") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("nonexistent") == false, "is_music_playing for unknown name should return false")
    print("PASS: Sound.is_music_playing() returns false in headless")
end

-- Test: update runs cleanly after a fade_music call (no error from fade arithmetic)
do
    Sound.load()
    Sound.fade_music("bg", 1, 2)
    Sound.update(0.5)
    Sound.update(2.0)
    print("PASS: Sound.update() runs cleanly after fade_music")
end

print("ALL TESTS PASSED")
