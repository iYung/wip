local SceneManager = require("lua/core/scene_manager")
local StoreScene   = require("lua/game/scenes/store_scene")
local GameState    = require("lua/game/game_state")
local input        = require("lua/game/input")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas

local scene_manager

function love.load()
    canvas       = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    local gs     = GameState.new()
    scene_manager = SceneManager.new()
    local store_scene = StoreScene.new(gs, input, scene_manager)
    scene_manager:switch(store_scene)
end

function love.update(dt)
    input:update()
    scene_manager:update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.08, 0.12)
    scene_manager:draw()
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
