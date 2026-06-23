local Scene  = require("lua/core/scene")
local WinBg  = require("lua/game/shaders/win_bg")
local A      = require("lua/game/assets")
local config = require("lua/game/config")

local ROTATE_SPEED = 0.3

local WinScene = setmetatable({}, { __index = Scene })
WinScene.__index = WinScene

function WinScene.new(game_state, input, scene_manager, store_scene)
    local self          = Scene.new(config.LOGICAL_W, config.LOGICAL_H)
    setmetatable(self, WinScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self.store_scene    = store_scene
    self._time          = 0
    return self
end

function WinScene:on_enter()
    self._time = 0
    if love.filesystem.getInfo("assets/images/start_pattern.png") then
        local pat = love.graphics.newImage("assets/images/start_pattern.png")
        pat:setWrap("repeat", "repeat")
        self._img_pattern = pat
    end
end

function WinScene:on_exit() end

function WinScene:update(dt)
    self._time = self._time + dt
    if self.input:pressed("cancel") then
        self.scene_manager:switch(self.store_scene)
    end
end

function WinScene:draw()
    local img    = A.win_scene
    local iw, ih = img:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    if self._img_pattern then
        WinBg.apply(self._img_pattern, img, self._time * ROTATE_SPEED)
    end
    love.graphics.draw(img, 0, 0, 0, config.LOGICAL_W / iw, config.LOGICAL_H / ih)
    if self._img_pattern then WinBg.clear() end
end

return WinScene
