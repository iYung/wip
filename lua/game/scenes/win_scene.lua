local Scene  = require("lua/core/scene")
local A      = require("lua/game/assets")
local config = require("lua/game/config")

local WinScene = setmetatable({}, { __index = Scene })
WinScene.__index = WinScene

function WinScene.new(game_state, input, scene_manager, store_scene)
    local self          = Scene.new(config.LOGICAL_W, config.LOGICAL_H)
    setmetatable(self, WinScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self.store_scene    = store_scene
    return self
end

function WinScene:on_enter() end

function WinScene:on_exit() end

function WinScene:update(dt)
    if self.input:pressed("cancel") then
        self.scene_manager:switch(self.store_scene)
    end
end

function WinScene:draw()
    local img    = A.win_scene
    local iw, ih = img:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, 0, 0, 0, config.LOGICAL_W / iw, config.LOGICAL_H / ih)
end

return WinScene
