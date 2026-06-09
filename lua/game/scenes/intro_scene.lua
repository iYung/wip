local Scene      = require("lua/core/scene")
local Sound      = require("lua/game/sound")
local config     = require("lua/game/config")

local FADE_DURATION = config.FADE_DURATION
local HOLD_DURATION = 2.0

local W = 1280
local H = 720

local IntroScene = setmetatable({}, { __index = Scene })
IntroScene.__index = IntroScene

function IntroScene.new(game_state, input, scene_manager)
    local self          = Scene.new()
    setmetatable(self, IntroScene)
    self._game_state    = game_state
    self._input         = input
    self._scene_manager = scene_manager
    return self
end

function IntroScene:on_enter()
    self._images = {
        love.graphics.newImage("assets/images/intro_1.png"),
        love.graphics.newImage("assets/images/intro_2.png"),
        love.graphics.newImage("assets/images/intro_3.png"),
        love.graphics.newImage("assets/images/intro_4.png"),
    }
    Sound.fade_music("menu", 0, 2)
    self._slide = 1
    self._state = "fade_in"
    self._alpha = 1
    self._timer = 0
end

function IntroScene:update(dt)
    self._timer = self._timer + dt

    if self._state == "fade_in" then
        self._alpha = 1 - (self._timer / FADE_DURATION)
        if self._timer >= FADE_DURATION then
            self._alpha = 0
            self._timer = 0
            self._state = "hold"
        end

    elseif self._state == "hold" then
        self._alpha = 0
        if self._input:pressed("interact") or self._input:pressed("pick_up_down") then
            self._timer = 0
            self._state = "fade_out"
        elseif self._timer >= HOLD_DURATION then
            self._timer = 0
            self._state = "fade_out"
        end

    elseif self._state == "fade_out" then
        self._alpha = self._timer / FADE_DURATION
        if self._timer >= FADE_DURATION then
            self._alpha = 1
            if self._slide >= 4 then
                local StoreScene = require("lua/game/scenes/store_scene")
                self._scene_manager:switch(StoreScene.new(self._game_state, self._input, self._scene_manager, false))
            else
                self._slide = self._slide + 1
                self._timer = 0
                self._state = "fade_in"
            end
        end
    end
end

function IntroScene:draw()
    local img = self._images[self._slide]
    if img then
        local iw = img:getWidth()
        local ih = img:getHeight()
        local sx = W / iw
        local sy = H / ih
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, 0, 0, 0, sx, sy)
    end

    love.graphics.setColor(0, 0, 0, self._alpha)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setColor(1, 1, 1, 1)
end

return IntroScene
