local config = require("lua/game/config")

local SceneManager = {}
SceneManager.__index = SceneManager

local FADE_DURATION = 0.3

function SceneManager.new()
    local self        = setmetatable({}, SceneManager)
    self.current      = nil
    self._fade_state  = "idle"
    self._fade_alpha  = 0
    return self
end

function SceneManager:switch(scene)
    if not self.current then
        -- First load: swap immediately, no fade
        self.current = scene
        if self.current then self.current:on_enter() end
    else
        -- Subsequent switches: swap immediately, then run fade overlay
        self.current:on_exit()
        self.current = scene
        if self.current then self.current:on_enter() end
        self._fade_state = "out"
        self._fade_alpha = 0
    end
end

function SceneManager:update(dt)
    if self.current then self.current:update(dt) end

    if self._fade_state == "out" then
        self._fade_alpha = self._fade_alpha + dt / FADE_DURATION
        if self._fade_alpha >= 1 then
            self._fade_alpha = 1
            self._fade_state = "in"
        end
    elseif self._fade_state == "in" then
        self._fade_alpha = self._fade_alpha - dt / FADE_DURATION
        if self._fade_alpha <= 0 then
            self._fade_alpha = 0
            self._fade_state = "idle"
        end
    end
end

function SceneManager:draw()
    if self.current then self.current:draw() end

    if self._fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0, self._fade_alpha)
        love.graphics.rectangle("fill", 0, 0, config.LOGICAL_W, config.LOGICAL_H)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return SceneManager
