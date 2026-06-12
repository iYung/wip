-- Reset any stub injected by earlier test files so we get the real module.
package.loaded["lua/core/sound"] = nil
local Sound = require("lua/core/sound")

-- Standard manifest used by all load() calls in this test file.
local MANIFEST = {
    sfx_dir   = "assets/sounds/",
    sfx       = {
        "pick_up", "put_down", "water_plant", "plant_ready",
        "clone_success", "shop_navigate", "shop_buy", "fail",
        "menu_navigate", "menu_confirm",
    },
    animalese = "assets/sounds/animalese.wav",
    music = {
        menu = { path = "assets/music/menu.mp3",         autoplay = true  },
        bg1  = { path = "assets/music/background.mp3"                     },
        bg2  = { path = "assets/music/background2.mp3"                    },
        bg3  = { path = "assets/music/background3.mp3"                    },
        bg4  = { path = "assets/music/background4.mp3"                    },
    },
}

-- Test: Sound.load() does not error in headless mode
do
    Sound.load(MANIFEST)
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
    Sound.play_music("bg1")
    Sound.play_music("nonexistent")
    print("PASS: Sound.play_music() runs without error")
end

-- Test: Sound.fade_music runs without error for fade in and fade out
do
    Sound.fade_music("menu", 0, 2)
    Sound.fade_music("bg1", 1, 2)
    Sound.fade_music("nonexistent", 0, 1)
    print("PASS: Sound.fade_music() runs without error")
end

-- Test: Sound.stop_music runs without error
do
    Sound.stop_music("menu")
    Sound.stop_music("bg1")
    Sound.stop_music("nonexistent")
    print("PASS: Sound.stop_music() runs without error")
end

-- Test: Sound.is_music_playing returns false in headless (stubs return false)
do
    assert(Sound.is_music_playing("menu") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("bg1") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("nonexistent") == false, "is_music_playing for unknown name should return false")
    print("PASS: Sound.is_music_playing() returns false in headless")
end

-- Test: update runs cleanly after a fade_music call (no error from fade arithmetic)
do
    Sound.load(MANIFEST)
    Sound.fade_music("bg1", 1, 2)
    Sound.update(0.5)
    Sound.update(2.0)
    print("PASS: Sound.update() runs cleanly after fade_music")
end

-- Test: Sound.play_animalese runs without error at neutral pitch
do
    Sound.play_animalese(1.0)
    print("PASS: sound: Sound.play_animalese() runs without error at pitch 1.0")
end

-- Test: Sound.play_animalese runs without error at low and high pitches
do
    Sound.play_animalese(0.70)
    Sound.play_animalese(1.35)
    print("PASS: sound: Sound.play_animalese() runs without error at extreme pitches")
end

-- Test: play_animalese cooldown suppresses notes fired within 50ms
do
    local play_count = 0
    local orig_play    = love.audio.play
    local orig_getInfo = love.filesystem.getInfo
    local orig_timer   = love.timer
    love.audio.play = function() play_count = play_count + 1 end
    love.filesystem.getInfo = function(p)
        if type(p) == "string" and p:find("animalese") then return true end
        return nil
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)

    local fake_time = 1.0
    love.timer = { getTime = function() return fake_time end }

    S.play_animalese(1.0)
    assert(play_count == 1, "expected first play to fire, got " .. play_count)

    S.play_animalese(1.0)
    assert(play_count == 1, "expected cooldown to suppress 0ms re-trigger, got " .. play_count)

    fake_time = 1.030
    S.play_animalese(1.0)
    assert(play_count == 1, "expected cooldown to suppress 30ms re-trigger, got " .. play_count)

    fake_time = 1.055
    S.play_animalese(1.0)
    assert(play_count == 2, "expected play at 55ms past cooldown, got " .. play_count)

    love.audio.play         = orig_play
    love.filesystem.getInfo = orig_getInfo
    love.timer              = orig_timer
    package.loaded["lua/core/sound"] = nil
    print("PASS: sound: play_animalese cooldown suppresses notes within 50ms")
end

-- Test: play_random_music picks one track and fades it in (all three tracks present)
do
    local orig_play    = love.audio.play
    local orig_newSrc  = love.audio.newSource
    local orig_getInfo = love.filesystem.getInfo

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
            if p == "assets/music/background3.mp3" then return true end
        end
        return nil
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)

    S.play_random_music({"bg1", "bg2", "bg3"}, 2)
    S.update(2)

    love.audio.play    = orig_play
    love.audio.newSource = orig_newSrc
    love.filesystem.getInfo = orig_getInfo
    package.loaded["lua/core/sound"] = nil
    print("PASS: play_random_music picks one track and fades it in")
end

-- Test: play_random_music handles missing tracks gracefully
do
    local orig_play    = love.audio.play
    local orig_newSrc  = love.audio.newSource
    local orig_getInfo = love.filesystem.getInfo

    -- Only background.mp3 (bg1) is present; bg2 and bg3 are missing
    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3" then return true end
        end
        return nil
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)

    S.play_random_music({"bg1", "bg2", "bg3"}, 2)
    S.update(2)

    love.audio.play    = orig_play
    love.audio.newSource = orig_newSrc
    love.filesystem.getInfo = orig_getInfo
    package.loaded["lua/core/sound"] = nil
    print("PASS: play_random_music handles missing tracks gracefully")

    -- Empty list must also be a no-op
    package.loaded["lua/core/sound"] = nil
    local S2 = require("lua/core/sound")
    S2.load(MANIFEST)
    S2.play_random_music({}, 2)
    S2.update(2)
    package.loaded["lua/core/sound"] = nil
    print("PASS: play_random_music handles empty list gracefully")
end

-- Regression: fading bg1-bg4 in a loop (store→start transition) works for all present tracks
-- and a wrong track name ("bg") silently does nothing.
do
    local orig_getInfo = love.filesystem.getInfo

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
            if p == "assets/music/background3.mp3" then return true end
            if p == "assets/music/background4.mp3" then return true end
        end
        return nil
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)

    -- Simulate bg music playing (play_random_music picks one; we start bg1 directly)
    S.play_music("bg1")

    -- The fixed _on_leave loop: all four names must be accepted without error
    for _, name in ipairs({"bg1", "bg2", "bg3", "bg4"}) do
        S.fade_music(name, 0, 1)
    end
    S.update(1.5)  -- advance past the fade duration; should not error

    -- The old broken call with the wrong name must still be a silent no-op
    S.fade_music("bg", 0, 1)
    S.update(0.016)

    love.filesystem.getInfo = orig_getInfo
    package.loaded["lua/core/sound"] = nil
    print("PASS: fading bg1-bg4 loop (store->start transition) runs without error")
end

-- Test: Sound.on_focus() does not error in headless mode (love.audio guard)
do
    Sound.load(MANIFEST)
    Sound.on_focus(true)
    Sound.on_focus(false)
    print("PASS: Sound.on_focus() runs without error in headless")
end

-- Test: on_focus(true) replays tracks with playing_intent=true; skips ones with playing_intent=false
do
    local orig_getInfo  = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0

    love.filesystem.getInfo = function(p)
        if type(p) == "string" and p == "assets/music/menu.mp3" then return true end
        return orig_getInfo(p)
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        return src
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)
    -- load() plays menu immediately; reset counter so we only count on_focus calls
    play_calls = 0

    -- menu: playing_intent=true, isPlaying()=false → should replay
    S.on_focus(true)
    assert(play_calls == 1, "expected 1 replay on focus (menu), got " .. play_calls)

    -- after stop, playing_intent=false → should not replay
    S.stop_music("menu")
    play_calls = 0
    S.on_focus(true)
    assert(play_calls == 0, "expected 0 replays after stop_music, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["lua/core/sound"] = nil
    print("PASS: on_focus(true) replays only tracks with playing_intent=true")
end

-- Test: on_focus(false) does not replay any tracks
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0

    love.filesystem.getInfo = function(p)
        if type(p) == "string" and p == "assets/music/menu.mp3" then return true end
        return orig_getInfo(p)
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        return src
    end

    package.loaded["lua/core/sound"] = nil
    local S = require("lua/core/sound")
    S.load(MANIFEST)
    play_calls = 0

    S.on_focus(false)
    assert(play_calls == 0, "on_focus(false) must not play any sources, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["lua/core/sound"] = nil
    print("PASS: on_focus(false) does not replay any tracks")
end

print("ALL TESTS PASSED")
