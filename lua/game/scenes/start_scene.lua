local Scene     = require("lua/core/scene")
local Sound     = require("lua/core/sound")
local MenuBg    = require("lua/game/shaders/menu_bg")
local Save      = require("lua/core/save")
local GameState = require("lua/game/game_state")
local Fonts     = require("lua/game/fonts")
local config    = require("lua/game/config")

local SCROLL_SPEED_X = 60
local SCROLL_SPEED_Y = 30

local ITEMS = { "New Game", "Continue", "Settings", "Exit" }

local W         = 1280
local H         = 720
local BTN_W     = 300
local BTN_H     = 54
local BTN_X     = (W - BTN_W) / 2
local BTN_Y0    = 360
local BTN_GAP   = 74

local StartScene = setmetatable({}, { __index = Scene })
StartScene.__index = StartScene


function StartScene.new(game_state, input, scene_manager, open_settings)
    local self          = Scene.new(config.LOGICAL_W, config.LOGICAL_H)
    setmetatable(self, StartScene)
    self.input          = input
    self.scene_manager  = scene_manager
    self.open_settings  = open_settings
    self.selected       = 1
    self._time          = 0
    return self
end

function StartScene:on_enter()
    self._font_btn      = Fonts.new(22)
    self._font_tagline  = Fonts.new(16)
    self._img_bg      = love.graphics.newImage("assets/images/start_bg.png")
    self._img_logo     = love.graphics.newImage("assets/images/start_logo.png")
    self._img_sub_logo = love.graphics.newImage("assets/images/sub_logo.png")
    self._img_btn     = love.graphics.newImage("assets/images/menu_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/images/menu_btn_selected.png")
    if love.filesystem.getInfo("assets/images/start_pattern.png") then
        local img = love.graphics.newImage("assets/images/start_pattern.png")
        img:setWrap("repeat", "repeat")
        self._img_pattern = img
    end
    self._font_credit = love.graphics.newFont(12)
    self._time = 0
    if not Sound.is_music_playing("menu") then
        Sound.play_music("menu")
    end
    self._has_save = Save.exists()
    if self._has_save then
        self.selected = 2
    end
end

local function _next_selectable(current, delta, has_save)
    local n = #ITEMS
    local s = current
    for _ = 1, n do
        s = ((s - 1 + delta) % n) + 1
        if s ~= 2 or has_save then return s end
    end
    return current
end

function StartScene:update(dt)
    self._time = self._time + dt
    if self.input:pressed("move_up") then
        self.selected = _next_selectable(self.selected, -1, self._has_save)
        Sound.play("menu_navigate")
    end
    if self.input:pressed("move_down") then
        self.selected = _next_selectable(self.selected, 1, self._has_save)
        Sound.play("menu_navigate")
    end
    if self.input:pressed("interact") then
        self:_confirm()
    end
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
    if self.selected == 2 then
        if not self._has_save then return end
        local data = Save.read()
        if not data then return end
        local gs = GameState.from_save(data)
        Sound.fade_music("menu", 0, 2)
        self.scene_manager:switch(StoreScene.new(gs, self.input, self.scene_manager, true))
        return
    end
    -- New Game (selected == 1)
    Sound.fade_music("menu", 0, 2)
    self.scene_manager:switch(StoreScene.new(GameState.new(), self.input, self.scene_manager, false))
end

function StartScene:draw()
    local prev_font = love.graphics.getFont()

    love.graphics.setColor(1, 1, 1, 1)
    if self._img_pattern then
        MenuBg.apply(self._img_pattern, self._img_bg,
            self._time * SCROLL_SPEED_X,
            self._time * SCROLL_SPEED_Y)
    end
    love.graphics.draw(self._img_bg, 0, 0)
    if self._img_pattern then MenuBg.clear() end

    local iw = self._img_logo:getWidth()
    local logo_y = 140
    love.graphics.draw(self._img_logo, (W - iw) / 2, logo_y)

    local sw = self._img_sub_logo:getWidth()
    local sub_y = logo_y + self._img_logo:getHeight() + 8
    local sub_x = (W - sw) / 2
    love.graphics.draw(self._img_sub_logo, sub_x, sub_y)

    love.graphics.setFont(self._font_tagline)
    local sh = self._img_sub_logo:getHeight()
    local th = self._font_tagline:getHeight()
    local tag_y = sub_y + (sh - th) / 2
    local tag   = "grows plants with increasing speed and quantity for profit"
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tag, sub_x,     tag_y, sw, "center")
    love.graphics.printf(tag, sub_x + 1, tag_y, sw, "center")

    love.graphics.setFont(self._font_btn)
    for i, label in ipairs(ITEMS) do
        local y = BTN_Y0 + (i - 1) * BTN_GAP
        if i == 2 and not self._has_save then
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.draw(self._img_btn, BTN_X, y)
            love.graphics.setColor(1, 1, 1, 0.4)
            local th = self._font_btn:getHeight()
            love.graphics.printf(label, BTN_X, y + (BTN_H - th) / 2, BTN_W, "center")
            love.graphics.setColor(1, 1, 1, 1)
        else
            local img = i == self.selected and self._img_btn_sel or self._img_btn
            love.graphics.draw(img, BTN_X, y)
            love.graphics.setColor(1, 1, 1, 1)
            local th = self._font_btn:getHeight()
            love.graphics.printf(label, BTN_X, y + (BTN_H - th) / 2, BTN_W, "center")
        end
    end

    love.graphics.setFont(self._font_credit)
    love.graphics.setColor(1, 1, 1, 0.5)
    local credit = "sounds by qubodup · music by trash kid"
    local ch = self._font_credit:getHeight()
    love.graphics.printf(credit, 0, H - ch - 8, W, "center")

    local ku = self.input:key_for("move_up")    or "?"
    local kl = self.input:key_for("move_left")  or "?"
    local kd = self.input:key_for("move_down")  or "?"
    local kr = self.input:key_for("move_right") or "?"
    local kb_text = ku .. "/" .. kl .. "/" .. kd .. "/" .. kr
    love.graphics.setFont(self._font_btn)
    love.graphics.setColor(0, 0, 0, 1)
    local kb_w = self._font_btn:getWidth(kb_text)
    love.graphics.print(kb_text, 950 - kb_w / 2, 630)

    local ki = self.input:key_for("interact") or "?"
    local ki_w = self._font_btn:getWidth(ki)
    love.graphics.print(ki, 1150 - ki_w / 2, 630)

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return StartScene
