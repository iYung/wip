local Scene = require("lua/core/scene")
local Sound = require("lua/game/sound")

local ITEMS = { "New Game", "Continue", "Settings", "Exit" }

local W         = 1280
local BTN_W     = 300
local BTN_H     = 54
local BTN_X     = (W - BTN_W) / 2
local BTN_Y0    = 290
local BTN_GAP   = 74

local StartScene = setmetatable({}, { __index = Scene })
StartScene.__index = StartScene

function StartScene.new(game_state, input, scene_manager, open_settings)
    local self          = Scene.new()
    setmetatable(self, StartScene)
    self.game_state     = game_state
    self.input          = input
    self.scene_manager  = scene_manager
    self.open_settings  = open_settings
    self.selected       = 1
    self._prev_up       = false
    self._prev_down     = false
    self._prev_confirm  = false
    return self
end

function StartScene:on_enter()
    self._font_btn    = love.graphics.newFont(22)
    self._img_bg      = love.graphics.newImage("assets/start_bg.png")
    self._img_logo    = love.graphics.newImage("assets/start_logo.png")
    self._img_btn     = love.graphics.newImage("assets/menu_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/menu_btn_selected.png")
end

function StartScene:update(dt)
    local up      = love.keyboard.isDown("up")    or love.keyboard.isDown("w")
    local down    = love.keyboard.isDown("down")  or love.keyboard.isDown("s")
    local confirm = love.keyboard.isDown("return") or love.keyboard.isDown("space") or love.keyboard.isDown("f")

    if up and not self._prev_up then
        self.selected = ((self.selected - 2) % #ITEMS) + 1
        Sound.play("menu_navigate")
    end
    if down and not self._prev_down then
        self.selected = (self.selected % #ITEMS) + 1
        Sound.play("menu_navigate")
    end
    if confirm and not self._prev_confirm then
        self:_confirm()
    end

    self._prev_up      = up
    self._prev_down    = down
    self._prev_confirm = confirm
end

function StartScene:_confirm()
    Sound.play("menu_confirm")
    if self.selected == 3 then
        if self.open_settings then self.open_settings() end
        return
    end
    if self.selected == 4 then
        love.event.quit()
        return
    end
    local StoreScene = require("lua/game/scenes/store_scene")
    self.scene_manager:switch(StoreScene.new(self.game_state, self.input, self.scene_manager))
end

function StartScene:draw()
    local prev_font = love.graphics.getFont()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._img_bg, 0, 0)

    local iw = self._img_logo:getWidth()
    love.graphics.draw(self._img_logo, (W - iw) / 2, 140)

    love.graphics.setFont(self._font_btn)
    for i, label in ipairs(ITEMS) do
        local y = BTN_Y0 + (i - 1) * BTN_GAP
        local img = i == self.selected and self._img_btn_sel or self._img_btn
        love.graphics.draw(img, BTN_X, y)
        love.graphics.setColor(1, 1, 1, 1)
        local th = self._font_btn:getHeight()
        love.graphics.printf(label, BTN_X, y + (BTN_H - th) / 2, BTN_W, "center")
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return StartScene
