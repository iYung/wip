local _visual_test = nil
local _visual_mode = false
do
    local headless, visual, test_file = false, false, nil
    for _, v in ipairs(arg or {}) do
        if     v == "--headless" then headless = true
        elseif v == "--visual"   then visual   = true
        elseif (headless or visual) and not test_file and v:sub(1, 1) ~= "-" then
            test_file = v
        end
    end
    if headless then
        require("lua/headless/stubs")
        require("lua/headless/runner").run(test_file)
        return
    end
    if visual then
        _visual_test = test_file
        _visual_mode = true
    end
end

love.graphics.setDefaultFilter("nearest", "nearest")

local SceneManager = require("lua/core/scene_manager")
local StartScene   = require("lua/game/scenes/start_scene")
local GameState    = require("lua/game/game_state")
local input        = require("lua/game/input")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas
local scene_manager

local _visual_coro
local _visual_done     = false
local _visual_exit_code = 0

function love.load()
    canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")

    if _visual_mode then
        local runner = require("lua/headless/runner")
        runner._visual = true
        if _visual_test then
            local chunk, err = loadfile(_visual_test)
            if not chunk then error(err) end
            _visual_coro = coroutine.create(chunk)
        else
            _visual_coro = coroutine.create(function()
                local items = love.filesystem.getDirectoryItems("tests")
                local files = {}
                for _, name in ipairs(items) do
                    if name:sub(-4) == ".lua" then files[#files + 1] = name end
                end
                table.sort(files)
                local passed, total = 0, #files
                for _, filename in ipairs(files) do
                    local path = "tests/" .. filename
                    local ok, err = pcall(dofile, path)
                    if ok then
                        print("PASS  " .. path)
                        passed = passed + 1
                    else
                        print("FAIL  " .. path .. " — " .. tostring(err))
                        _visual_exit_code = 1
                    end
                end
                print(passed .. "/" .. total .. " passed")
            end)
        end
    else
        local gs = GameState.new()
        scene_manager = SceneManager.new()
        scene_manager:switch(StartScene.new(gs, input, scene_manager))
    end
end

function love.update(dt)
    if _visual_coro and not _visual_done then
        local ok, err = coroutine.resume(_visual_coro)
        if not ok then
            print("FAIL: " .. tostring(err))
            _visual_done = true
            love.event.quit(1)
        elseif coroutine.status(_visual_coro) == "dead" then
            _visual_done = true
            love.event.quit(_visual_exit_code)
        end
        return
    end
    if not _visual_mode then
        input:update()
        scene_manager:update(dt)
    end
end

function love.draw()
    local sm = _visual_mode and require("lua/headless/runner")._active_sm or scene_manager
    if not sm then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.08, 0.12)
    sm:draw()
    love.graphics.setCanvas()

    local sw, sh  = love.graphics.getDimensions()
    local scale   = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox      = (sw - LOGICAL_W * scale) / 2
    local oy      = (sh - LOGICAL_H * scale) / 2
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end
