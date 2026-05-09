local Scene = require("lua/core/scene")
local Plant = require("lua/game/plant")

local BuyScene = setmetatable({}, { __index = Scene })
BuyScene.__index = BuyScene

function BuyScene.new(game_state, input, scene_manager, store_scene, target_slot)
    local self           = Scene.new()
    setmetatable(self, BuyScene)
    self.game_state      = game_state
    self.input           = input
    self.scene_manager   = scene_manager
    self.store_scene     = store_scene
    self.target_slot     = target_slot
    return self
end

function BuyScene:on_enter() end

function BuyScene:on_exit() end

function BuyScene:update(dt)
    if self.input:pressed("interact") then
        self:_buy_plant()
        self.scene_manager:switch(self.store_scene)
    elseif self.input:pressed("pick_up_down") then
        self.scene_manager:switch(self.store_scene)
    end
end

function BuyScene:_buy_plant()
    local plant = Plant.new(1)
    self.game_state.player.held_item = plant
end

function BuyScene:draw()
    love.graphics.setColor(0, 0, 0, 0.82)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(0.95, 0.95, 0.95, 1)
    love.graphics.print("-- Buy Scene --",        460, 240, 0, 2, 2)
    love.graphics.print("Plant Type 1",            520, 320, 0, 1.5, 1.5)

    love.graphics.setColor(0.7, 0.9, 0.7, 1)
    love.graphics.print("[F]  Buy plant",          500, 410, 0, 1.3, 1.3)
    love.graphics.setColor(0.9, 0.7, 0.7, 1)
    love.graphics.print("[E]  Cancel",             500, 450, 0, 1.3, 1.3)

    love.graphics.setColor(1, 1, 1, 1)
end

return BuyScene
