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

local _runner = _visual_mode and require("lua/headless/runner") or nil

love.graphics.setDefaultFilter("nearest", "nearest")

local SceneManager = require("lua/core/scene_manager")
local StartScene   = require("lua/game/scenes/start_scene")
local GameState    = require("lua/game/game_state")
local input        = require("lua/game/input")
local Save          = require("lua/game/save")
local SettingsMenu  = require("lua/game/scenes/settings_menu")
local SettingsState = require("lua/game/settings_state")
local Sound         = require("lua/game/sound")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas
local scene_manager
local settings_menu
local ss

local _visual_coro
local _visual_done      = false
local _visual_exit_code = 0
local _visual_files     = nil  -- list of paths in run-all mode; nil in single-file mode
local _visual_file_idx  = 1
local _visual_passed    = 0

local function _visual_advance()
    _visual_file_idx = _visual_file_idx + 1
    if _visual_file_idx <= #_visual_files then
        local chunk = assert(loadfile(_visual_files[_visual_file_idx]))
        _visual_coro = coroutine.create(chunk)
    else
        print(_visual_passed .. "/" .. #_visual_files .. " passed")
        _visual_done = true
        love.event.quit(_visual_exit_code)
    end
end

function love.load()
    love.window.setIcon(love.image.newImageData("assets/images/icon.png"))

    canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("linear", "nearest")
    love.graphics.setNewFont("assets/fonts/font.ttf", 16, "light")

    if _visual_mode then
        local runner = require("lua/headless/runner")
        runner._visual = true
        if _visual_test then
            local chunk, err = loadfile(_visual_test)
            if not chunk then error(err) end
            _visual_coro = coroutine.create(chunk)
        else
            local items = love.filesystem.getDirectoryItems("tests")
            _visual_files = {}
            for _, name in ipairs(items) do
                if name:sub(-4) == ".lua" then
                    _visual_files[#_visual_files + 1] = "tests/" .. name
                end
            end
            table.sort(_visual_files)
            if #_visual_files > 0 then
                _visual_coro = coroutine.create(assert(loadfile(_visual_files[1])))
            end
        end
    else
        scene_manager = SceneManager.new()
        ss = Save.settings_exist() and SettingsState.from_save(Save.read_settings()) or SettingsState.new()
        input._map = ss:key_map()
        local function _on_save()
            local current = scene_manager and scene_manager.current
            if current and current.game_state then
                Save.write(GameState.to_save(current.game_state))
            end
        end
        local function _on_leave()
            _on_save()
            Save.write_settings(ss:to_save())
            settings_menu:close()
            for _, _bg_name in ipairs({"bg1", "bg2", "bg3", "bg4"}) do
                Sound.fade_music(_bg_name, 0, 1)
            end
            scene_manager:switch(StartScene.new(nil, input, scene_manager, function() settings_menu:open(true) end))
            -- Prime _down with currently-held keys so the confirm key that
            -- triggered this doesn't register as a fresh press in StartScene.
            input:update()
        end
        settings_menu = SettingsMenu.new(ss, input, _on_save, _on_leave)
        scene_manager:switch(StartScene.new(nil, input, scene_manager, function() settings_menu:open(true) end))
        Sound.load()
    end
end

function love.update(dt)
    if _visual_coro and not _visual_done then
        local ok, err = coroutine.resume(_visual_coro)
        if not ok then
            if _visual_files then
                print("FAIL  " .. _visual_files[_visual_file_idx] .. " — " .. tostring(err))
                _visual_exit_code = 1
                _visual_advance()
            else
                print("FAIL: " .. tostring(err))
                _visual_done = true
                love.event.quit(1)
            end
        elseif coroutine.status(_visual_coro) == "dead" then
            if _visual_files then
                print("PASS  " .. _visual_files[_visual_file_idx])
                _visual_passed = _visual_passed + 1
                _visual_advance()
            else
                _visual_done = true
                love.event.quit(_visual_exit_code)
            end
        end
        return
    end
    if not _visual_mode then
        Sound.update(dt)
        if settings_menu and settings_menu.is_open then
            settings_menu:update(dt)
        else
            input:update()
            scene_manager:update(dt)
        end
    end
end

function love.draw()
    local sm = _visual_mode and _runner._active_sm or scene_manager
    if not sm then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.08, 0.12)
    sm:draw()
    if settings_menu and settings_menu.is_open then
        settings_menu:draw()
    end
    love.graphics.setCanvas()

    local sw, sh  = love.graphics.getDimensions()
    local scale   = math.min(sw / LOGICAL_W, sh / LOGICAL_H)
    local ox      = (sw - LOGICAL_W * scale) / 2
    local oy      = (sh - LOGICAL_H * scale) / 2
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function love.keypressed(key)
    if settings_menu and settings_menu.is_open then
        if settings_menu:keypressed(key) then return end
    end
    if key == "escape" then
        if settings_menu and scene_manager and scene_manager.current and scene_manager.current.esc_opens_settings then
            if settings_menu.is_open then
                settings_menu:close()
            else
                settings_menu:open()
            end
        elseif not (settings_menu and settings_menu.is_open) then
            love.event.quit()
        end
    end
end

function love.quit()
    local current = scene_manager and scene_manager.current
    if current and current.game_state then
        Save.write(GameState.to_save(current.game_state))
    end
    if ss then
        Save.write_settings(ss:to_save())
    end
end

function love.focus(focused)
    Sound.on_focus(focused)
end
