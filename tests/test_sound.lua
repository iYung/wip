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

print("ALL TESTS PASSED")
