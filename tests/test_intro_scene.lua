local IntroScene = require("lua/game/scenes/intro_scene")
local config     = require("lua/game/config")

local FADE_DURATION = config.FADE_DURATION
local HOLD_DURATION = 2.0

local function make_input(pressed_action)
    return {
        pressed = function(_, action) return action == pressed_action end,
        _map    = {},
    }
end

local function make_scene(pressed_action)
    local switched_to = nil
    local sm = { switch = function(_, s) switched_to = s end }
    local s  = IntroScene.new({}, make_input(pressed_action), sm)
    s:on_enter()
    return s, sm, function() return switched_to end
end

-- Test 1: on_enter initialises to slide 1, fade_in, alpha 1
do
    local s = make_scene(nil)
    assert(s._slide == 1,       "slide should start at 1")
    assert(s._state == "fade_in", "state should start as fade_in")
    assert(s._alpha == 1,       "alpha should start at 1")
    print("PASS: on_enter: slide=1, state=fade_in, alpha=1")
end

-- Test 2: fade_in completes after FADE_DURATION → state becomes hold, alpha=0
do
    local s = make_scene(nil)
    s:update(FADE_DURATION)
    assert(s._state == "hold", "after fade_in duration state should be hold, got " .. s._state)
    assert(s._alpha == 0,     "alpha should be 0 in hold")
    print("PASS: fade_in completes → hold, alpha=0")
end

-- Test 3: input is ignored during fade_in
do
    local s = make_scene("interact")
    s:update(FADE_DURATION * 0.5)
    assert(s._state == "fade_in", "skip during fade_in should be ignored")
    print("PASS: skip ignored during fade_in")
end

-- Test 4: input is ignored during fade_out
do
    local s = make_scene("interact")
    s:update(FADE_DURATION)              -- → hold
    s:update(0)                          -- triggers skip → fade_out
    assert(s._state == "fade_out")
    s._input = make_input("interact")
    s:update(FADE_DURATION * 0.3)        -- mid fade_out, press skip
    assert(s._state == "fade_out", "skip during fade_out should be ignored")
    print("PASS: skip ignored during fade_out")
end

-- Test 5: interact during hold → jumps to fade_out
do
    local s = make_scene("interact")
    s:update(FADE_DURATION)   -- → hold
    s:update(0)               -- interact pressed → fade_out
    assert(s._state == "fade_out", "interact during hold should jump to fade_out, got " .. s._state)
    assert(s._timer == 0,          "timer should reset on skip")
    print("PASS: interact during hold → fade_out")
end

-- Test 6: pick_up_down during hold also skips
do
    local s = make_scene("pick_up_down")
    s:update(FADE_DURATION)
    s:update(0)
    assert(s._state == "fade_out", "pick_up_down during hold should also skip")
    print("PASS: pick_up_down during hold → fade_out")
end

-- Test 7: hold timer expires naturally → fade_out
do
    local s = make_scene(nil)
    s:update(FADE_DURATION)              -- → hold
    s:update(HOLD_DURATION)              -- → fade_out
    assert(s._state == "fade_out", "hold timer expiry should transition to fade_out, got " .. s._state)
    print("PASS: hold timer expires → fade_out")
end

-- Test 8: fade_out advances to next slide (slide 1 → 2)
do
    local s = make_scene(nil)
    s:update(FADE_DURATION)              -- → hold
    s:update(HOLD_DURATION)              -- → fade_out
    s:update(FADE_DURATION)              -- fade_out done → slide 2, fade_in
    assert(s._slide == 2,         "slide should advance to 2, got " .. s._slide)
    assert(s._state == "fade_in", "state should reset to fade_in, got " .. s._state)
    print("PASS: fade_out completes → slide 2, fade_in")
end

-- Test 9: alpha increases during fade_out (0 → 1)
do
    local s = make_scene(nil)
    s:update(FADE_DURATION)                 -- → hold
    s:update(HOLD_DURATION)                 -- → fade_out
    s:update(FADE_DURATION * 0.5)           -- halfway through fade_out
    local approx = math.abs(s._alpha - 0.5) < 0.05
    assert(approx, "alpha mid-fade_out should be ~0.5, got " .. s._alpha)
    print("PASS: alpha ramps 0→1 during fade_out")
end

-- Test 10: after slide 4 fade_out, scene_manager:switch is called
do
    local s, sm, get_switched = make_scene(nil)

    local function one_slide()
        s:update(FADE_DURATION)
        s:update(HOLD_DURATION)
        s:update(FADE_DURATION)
    end

    one_slide()  -- slide 1→2
    one_slide()  -- slide 2→3
    one_slide()  -- slide 3→4
    assert(s._slide == 4, "should be on slide 4")
    assert(get_switched() == nil, "should not have switched yet")

    one_slide()  -- slide 4 → switch
    assert(get_switched() ~= nil, "scene_manager:switch should be called after slide 4")
    print("PASS: after slide 4 fade_out → scene_manager:switch called")
end

-- Test 11: StartScene New Game switches to an IntroScene (not StoreScene)
do
    local StartScene = require("lua/game/scenes/start_scene")
    local switched_scene = nil
    local sm = { switch = function(_, scene) switched_scene = scene end }
    local input = make_input("interact")
    input._map = {}
    local sc = StartScene.new({}, input, sm, function() end)
    sc.selected = 1
    sc:update(0)
    assert(switched_scene ~= nil, "New Game should switch scene")
    assert(getmetatable(switched_scene) == IntroScene, "New Game should switch to IntroScene")
    print("PASS: StartScene New Game switches to IntroScene")
end

print("ALL TESTS PASSED")
