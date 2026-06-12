local SceneManager = require("lua/core/scene_manager")

local function make_scene(name)
    return {
        name     = name,
        _entered = 0,
        _exited  = 0,
        on_enter = function(s) s._entered = s._entered + 1 end,
        on_exit  = function(s) s._exited  = s._exited  + 1 end,
        update   = function() end,
        draw     = function() end,
    }
end

-- Test 1: first switch is immediate, no fade
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    sm:switch(a)
    assert(sm.current == a,          "first switch: current should be A")
    assert(a._entered == 1,          "first switch: on_enter called")
    assert(a._exited  == 0,          "first switch: on_exit not called")
    assert(sm._fade_state == "idle", "first switch: no fade started")
    print("PASS: scene_manager: first switch is immediate with no fade")
end

-- Test 2: subsequent switch swaps current immediately and starts fade-out
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    assert(sm.current == b,          "subsequent switch: current is B immediately")
    assert(b._entered == 1,          "subsequent switch: on_enter called on B")
    assert(a._exited  == 0,          "subsequent switch: on_exit on A deferred (not yet called)")
    assert(sm._prev   == a,          "subsequent switch: old scene held in _prev for drawing")
    assert(sm._fade_state == "out",  "subsequent switch: fade-out started")
    assert(sm._fade_alpha == 0,      "subsequent switch: alpha starts at 0")
    print("PASS: scene_manager: subsequent switch swaps current immediately, defers on_exit")
end

-- Test 3: on_exit called on old scene only when fully black
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    sm:update(1.0)   -- large dt: completes fade-out
    assert(a._exited == 1,           "on_exit called on A when fully black")
    assert(sm._prev  == nil,         "_prev cleared after fade-out")
    assert(sm._fade_state == "in",   "fade-in started after fade-out completes")
    assert(sm._fade_alpha == 1,      "alpha at 1 at start of fade-in")
    print("PASS: scene_manager: on_exit deferred until fully black")
end

-- Test 4: fade-in completes and returns to idle
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    sm:update(1.0)   -- complete fade-out
    sm:update(1.0)   -- complete fade-in
    assert(sm._fade_state == "idle", "fade-in complete: state is idle")
    assert(sm._fade_alpha == 0,      "fade-in complete: alpha is 0")
    assert(sm.current == b,          "current still B after full transition")
    print("PASS: scene_manager: fade-in completes and returns to idle")
end

-- Test 5: new scene's update runs on the very first tick after switch
do
    local sm      = SceneManager.new()
    local a       = make_scene("A")
    local b       = make_scene("B")
    local b_ticks = 0
    b.update = function() b_ticks = b_ticks + 1 end
    sm:switch(a)
    sm:switch(b)
    sm:update(1/60)
    assert(b_ticks == 1, "B update called on first tick, got " .. b_ticks)
    print("PASS: scene_manager: new scene updates immediately after switch")
end

-- Test 6: default dimensions are 1280x720
do
    local sm = SceneManager.new()
    assert(sm._w == 1280, "default _w should be 1280, got " .. tostring(sm._w))
    assert(sm._h == 720,  "default _h should be 720, got "  .. tostring(sm._h))
    print("PASS: scene_manager: default dimensions are 1280x720")
end

-- Test 7: custom dimensions are stored
do
    local sm = SceneManager.new(800, 600)
    assert(sm._w == 800, "custom _w should be 800, got " .. tostring(sm._w))
    assert(sm._h == 600, "custom _h should be 600, got " .. tostring(sm._h))
    print("PASS: scene_manager: custom dimensions stored correctly")
end

print("ALL TESTS PASSED")
