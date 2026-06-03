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

-- Test 1: first switch calls on_enter, current is set
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    sm:switch(a)
    assert(sm.current == a,  "first switch: current should be A")
    assert(a._entered == 1,  "first switch: on_enter called once")
    assert(a._exited  == 0,  "first switch: on_exit not called")
    print("PASS: scene_manager: first switch sets current and calls on_enter")
end

-- Test 2: subsequent switch calls on_exit on old and on_enter on new immediately
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    assert(sm.current == b,  "subsequent switch: current should be B")
    assert(a._exited  == 1,  "subsequent switch: on_exit called on A")
    assert(b._entered == 1,  "subsequent switch: on_enter called on B")
    print("PASS: scene_manager: subsequent switch swaps scene immediately")
end

-- Test 3: new scene's update runs on the very next tick
do
    local sm      = SceneManager.new()
    local a       = make_scene("A")
    local b       = make_scene("B")
    local b_ticks = 0
    b.update = function() b_ticks = b_ticks + 1 end
    sm:switch(a)
    sm:switch(b)
    sm:update(1/60)
    assert(b_ticks == 1, "new scene update called on first tick, got " .. b_ticks)
    print("PASS: scene_manager: new scene updates immediately after switch")
end

-- Test 4: switching to nil clears current
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    sm:switch(a)
    sm:switch(nil)
    assert(sm.current == nil, "switch(nil): current should be nil")
    assert(a._exited == 1,    "switch(nil): on_exit called on A")
    print("PASS: scene_manager: switch(nil) clears current")
end

print("ALL TESTS PASSED")
