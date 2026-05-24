local ITEMS = { "Fullscreen / Window", "Exit Settings", "Leave Game" }

local W       = 1280
local H       = 720
local BTN_W   = 300
local BTN_H   = 54
local BTN_X   = (W - BTN_W) / 2
local BTN_GAP = 74
local BTN_Y0  = H / 2 - (#ITEMS - 1) * BTN_GAP / 2 - BTN_H / 2

local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu

SettingsMenu.is_open = false
SettingsMenu.selected = 1
SettingsMenu._prev_up      = false
SettingsMenu._prev_down    = false
SettingsMenu._prev_confirm = false
SettingsMenu._prev_escape  = false

function SettingsMenu.new()
    local self = setmetatable({}, SettingsMenu)
    self._img_btn     = love.graphics.newImage("assets/start_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/start_btn_selected.png")
    self._font_btn    = love.graphics.newFont(22)
    return self
end

function SettingsMenu:open()
    self.is_open  = true
    self.selected = 1
    -- Snapshot current key state so keys held at open time don't immediately fire
    self._prev_up      = love.keyboard.isDown("up")    or love.keyboard.isDown("w")
    self._prev_down    = love.keyboard.isDown("down")  or love.keyboard.isDown("s")
    self._prev_confirm = love.keyboard.isDown("e")     or love.keyboard.isDown("f")
                      or love.keyboard.isDown("return") or love.keyboard.isDown("space")
    self._prev_escape  = love.keyboard.isDown("escape")
end

function SettingsMenu:close()
    self.is_open = false
end

function SettingsMenu:update(dt)
    local up      = love.keyboard.isDown("up")   or love.keyboard.isDown("w")
    local down    = love.keyboard.isDown("down") or love.keyboard.isDown("s")
    local confirm = love.keyboard.isDown("e")      or love.keyboard.isDown("f")
                 or love.keyboard.isDown("return") or love.keyboard.isDown("space")
    local escape  = love.keyboard.isDown("escape")

    if up and not self._prev_up then
        self.selected = ((self.selected - 2) % #ITEMS) + 1
    end
    if down and not self._prev_down then
        self.selected = (self.selected % #ITEMS) + 1
    end
    if confirm and not self._prev_confirm then
        self:_confirm()
    end
    if escape and not self._prev_escape then
        self:close()
    end

    self._prev_up      = up
    self._prev_down    = down
    self._prev_confirm = confirm
    self._prev_escape  = escape
end

function SettingsMenu:_confirm()
    if self.selected == 1 then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif self.selected == 2 then
        self:close()
    elseif self.selected == 3 then
        love.event.quit()
    end
end

function SettingsMenu:draw()
    local prev_font = love.graphics.getFont()

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(self._font_btn)
    for i = 1, #ITEMS do
        local y   = BTN_Y0 + (i - 1) * BTN_GAP
        local img = i == self.selected and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, BTN_X, y)

        local label
        if i == 1 then
            label = love.window.getFullscreen() and "Window" or "Fullscreen"
        else
            label = ITEMS[i]
        end

        love.graphics.setColor(1, 1, 1, 1)
        local th = self._font_btn:getHeight()
        love.graphics.printf(label, BTN_X, y + (BTN_H - th) / 2, BTN_W, "center")
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return SettingsMenu
