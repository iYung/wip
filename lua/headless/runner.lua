local GameState    = require("lua/game/game_state")
local HeadlessInput = require("lua/headless/input")
local SceneManager = require("lua/core/scene_manager")
local StartScene   = require("lua/game/scenes/start_scene")

local runner = {}

-- Creates a fresh GameState, HeadlessInput, and SceneManager; wires them
-- together; switches to either StartScene (default) or the scene returned by
-- the optional scene_factory(gs, input, sm).
-- Returns { gs=gs, input=input, sm=sm }.
function runner.setup(scene_factory)
    local gs    = GameState.new()
    local input = HeadlessInput.new()
    local sm    = SceneManager.new()

    local scene
    if scene_factory then
        scene = scene_factory(gs, input, sm)
    else
        scene = StartScene.new(gs, input, sm)
    end

    sm:switch(scene)

    return { gs = gs, input = input, sm = sm }
end

-- Advances the simulation n times (default 1) by dt seconds each (default
-- 1/60).  Calls input:update() then scene_manager:update(dt) each iteration.
function runner.tick(input, scene_manager, n, dt)
    n  = n  or 1
    dt = dt or (1 / 60)
    for _ = 1, n do
        input:update()
        scene_manager:update(dt)
    end
end

-- Loads and executes test_file inside a pcall, prints a PASS/FAIL summary
-- line, then quits Love2D with exit code 0 (all passed) or 1 (failure).
function runner.run(test_file)
    _G.runner = runner

    local ok, err = pcall(dofile, test_file)

    if ok then
        print("PASS")
        love.event.quit(0)
    else
        print("FAIL: " .. tostring(err))
        love.event.quit(1)
    end
end

return runner
