local StartScene = require("lua/game/scenes/start_scene")

-- Minimal input stub: pressed() returns true only for the given action
local function make_input(pressed_action)
    return {
        pressed = function(_, action)
            return action == pressed_action
        end
    }
end

local _quit_called     = false
local _settings_opened = false
local _real_quit       = love.event.quit
love.event.quit = function() _quit_called = true end

local function make_scene(pressed_action)
    return StartScene.new(
        {},                                          -- game_state stub
        make_input(pressed_action),
        { switch = function() end },                 -- scene_manager stub
        function() _settings_opened = true end       -- open_settings callback
    )
end

-- Test 1: new() starts at selected = 1
local s = make_scene(nil)
assert(s.selected == 1, "new() should start at selected=1")
print("PASS: new() initial selection")

-- Test 2: no _prev_* edge-detection fields (input module handles that now)
assert(s._prev_up      == nil, "_prev_up should not exist on StartScene")
assert(s._prev_down    == nil, "_prev_down should not exist on StartScene")
assert(s._prev_confirm == nil, "_prev_confirm should not exist on StartScene")
print("PASS: no _prev_* edge-detection fields")

-- Tests 3-7: navigation with no save (_has_save=false); Continue (2) is skipped

-- Test 3: move_down 1 → 3 (skips 2)
s.selected = 1
s._has_save = false
s.input = make_input("move_down")
s:update(0)
assert(s.selected == 3, "move_down from 1 (no save) should skip 2 and go to 3, got " .. s.selected)
print("PASS: move_down 1->3 (skips disabled Continue)")

-- Test 4: move_down 3 → 4
s:update(0)
assert(s.selected == 4, "move_down from 3 should go to 4, got " .. s.selected)
print("PASS: move_down 3->4")

-- Test 5: move_down wraps from 4 → 1
s:update(0)
assert(s.selected == 1, "move_down from 4 should wrap to 1, got " .. s.selected)
print("PASS: move_down wrap 4->1")

-- Test 6: move_up 1 → 4 (skips 2 going up)
s.selected = 1
s.input = make_input("move_up")
s:update(0)
assert(s.selected == 4, "move_up from 1 (no save) should wrap to 4, got " .. s.selected)
print("PASS: move_up wrap 1->4 (skips disabled Continue)")

-- Test 7: move_up 3 → 1 (skips 2)
s.selected = 3
s:update(0)
assert(s.selected == 1, "move_up from 3 (no save) should skip 2 and go to 1, got " .. s.selected)
print("PASS: move_up 3->1 (skips disabled Continue)")

-- Test 7b: with save present, Continue is selectable normally
do
    local sw = make_scene("move_down")
    sw._has_save = true
    sw.selected = 1
    sw:update(0)
    assert(sw.selected == 2, "move_down from 1 (save present) should land on 2, got " .. sw.selected)
    print("PASS: move_down 1->2 when save present")
end

-- Test 8: interact on item 4 (Exit) calls love.event.quit
local s2 = make_scene("interact")
s2.selected = 4
_quit_called = false
s2:update(0)
assert(_quit_called, "interact on Exit (item 4) should call love.event.quit")
print("PASS: interact confirms Exit calls quit")

-- Test 9: interact on item 3 (Settings) calls open_settings callback
local s3 = make_scene("interact")
s3.selected = 3
_settings_opened = false
s3:update(0)
assert(_settings_opened, "interact on Settings (item 3) should invoke open_settings")
print("PASS: interact confirms Settings calls open_settings")

-- Test 10: interact on item 1 (New Game) switches scene
do
    local switched = false
    local sng = StartScene.new(
        {},
        make_input("interact"),
        { switch = function() switched = true end },
        function() end
    )
    sng.selected = 1
    sng:update(0)
    assert(switched, "interact on New Game (item 1) should switch scene")
    print("PASS: interact confirms New Game switches scene")
end

-- Test 11: interact on item 2 (Continue) is a no-op when no save exists
do
    local switched = false
    local sc = StartScene.new(
        {},
        make_input("interact"),
        { switch = function() switched = true end },
        function() end
    )
    sc.selected = 2
    sc._has_save = false
    sc:update(0)
    assert(not switched, "interact on Continue with no save should not switch scene")
    print("PASS: interact Continue no-op when no save")
end

-- Test 11b: interact on item 2 (Continue) switches scene when save exists
do
    local switched = false
    local Save = require("lua/game/save")
    local _orig_read = Save.read
    -- stub Save.read to return a minimal valid save table
    Save.read = function()
        return {
            version=1, currency=500, speed_level=0, growth_level=0,
            cooldown_level=0, growth_mult=1.0,
            unlocked_plants={[1]=true}, stage3_counts={}, seen_scripts={},
            player={ x=100, facing="right", held_item=nil },
            slots={ {item=nil},{item=nil},{item=nil},{item=nil},{item=nil} },
        }
    end
    local sc = StartScene.new(
        {},
        make_input("interact"),
        { switch = function() switched = true end },
        function() end
    )
    sc.selected = 2
    sc._has_save = true
    sc:update(0)
    assert(switched, "interact on Continue with save should switch scene")
    Save.read = _orig_read
    print("PASS: interact Continue switches scene when save exists")
end

-- Test 12: no action → selection unchanged
local s4 = make_scene(nil)
s4.selected = 2
s4:update(0)
assert(s4.selected == 2, "no input should leave selection unchanged")
print("PASS: no input, selection unchanged")

-- Test 13: _time accumulates with dt
local s5 = make_scene(nil)
s5:update(1.0)
assert(s5._time == 1.0, "_time should be 1.0 after update(1.0), got " .. tostring(s5._time))
s5:update(0.5)
assert(s5._time == 1.5, "_time should be 1.5 after another update(0.5), got " .. tostring(s5._time))
print("PASS: _time accumulates with dt")

-- Test 14: StartScene must NOT expose game_state so love.quit() does not
-- overwrite the save file with an empty GameState when quitting from the menu.
local s6 = make_scene(nil)
assert(s6.game_state == nil, "StartScene must not set game_state (would corrupt save on quit from menu)")
print("PASS: StartScene does not expose game_state")

love.event.quit = _real_quit
print("ALL TESTS PASSED")
