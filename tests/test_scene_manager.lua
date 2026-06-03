local SceneManager = require("lua/core/scene_manager")

local function make_scene(name)
    local entered = 0
    local exited  = 0
    return {
        name     = name,
        entered  = function(s) return s._entered end,
        exited   = function(s) return s._exited  end,
        _entered = 0,
        _exited  = 0,
        on_enter = function(s) s._entered = s._entered + 1 end,
        on_exit  = function(s) s._exited  = s._exited  + 1 end,
        update   = function() end,
        draw     = function() end,
    }
end

-- Test 1: first switch is immediate (no fade)
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    sm:switch(a)
    assert(sm.current == a,         "first switch: current should be A")
    assert(a._entered == 1,         "first switch: on_enter called once")
    assert(a._exited  == 0,         "first switch: on_exit not called")
    assert(sm._fade_state == "idle","first switch: no fade")
    assert(sm._fade_alpha == 0,     "first switch: alpha stays 0")
    print("PASS: scene_manager: first switch is immediate with no fade")
end

-- Test 2: subsequent switch swaps scene immediately and starts fade-out
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    assert(sm.current == b,          "subsequent switch: current should be B immediately")
    assert(a._exited  == 1,          "subsequent switch: on_exit called on A")
    assert(b._entered == 1,          "subsequent switch: on_enter called on B")
    assert(sm._fade_state == "out",  "subsequent switch: fade-out started")
    assert(sm._fade_alpha == 0,      "subsequent switch: alpha starts at 0")
    print("PASS: scene_manager: subsequent switch swaps scene immediately")
end

-- Test 3: fade-out advances alpha and transitions to fade-in
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)

    -- tick with large dt to complete fade-out in one step
    sm:update(1.0)
    assert(sm._fade_state == "in",   "after large dt: should be in fade-in")
    assert(sm._fade_alpha == 1,      "after large dt: alpha clamped to 1")
    print("PASS: scene_manager: fade-out completes and transitions to fade-in")
end

-- Test 4: fade-in decrements alpha and returns to idle
do
    local sm = SceneManager.new()
    local a  = make_scene("A")
    local b  = make_scene("B")
    sm:switch(a)
    sm:switch(b)
    sm:update(1.0)   -- complete fade-out → state="in", alpha=1
    sm:update(1.0)   -- complete fade-in  → state="idle", alpha=0
    assert(sm._fade_state == "idle", "after fade-in: state should be idle")
    assert(sm._fade_alpha == 0,      "after fade-in: alpha back to 0")
    assert(sm.current == b,          "after fade: current still B")
    print("PASS: scene_manager: fade-in completes and returns to idle")
end

-- Test 5: new scene's update runs immediately after switch
do
    local sm      = SceneManager.new()
    local a       = make_scene("A")
    local b       = make_scene("B")
    local b_ticks = 0
    b.update = function() b_ticks = b_ticks + 1 end
    sm:switch(a)
    sm:switch(b)
    sm:update(1/60)
    assert(b_ticks == 1, "new scene update called on first tick after switch, got " .. b_ticks)
    print("PASS: scene_manager: new scene updates immediately after switch")
end

print("ALL TESTS PASSED")
