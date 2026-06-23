local Scene  = require("lua/core/scene")
local WinBg  = require("lua/game/shaders/win_bg")
local UI     = require("lua/game/ui")
local Fonts  = require("lua/game/fonts")
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
    self._font = Fonts.new(22)
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
    local prev_font = love.graphics.getFont()
    local img    = A.win_scene
    local iw, ih = img:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    if self._img_pattern then
        WinBg.apply(self._img_pattern, img, self._time * ROTATE_SPEED)
    end
    love.graphics.draw(img, 0, 0, 0, config.LOGICAL_W / iw, config.LOGICAL_H / ih)
    if self._img_pattern then WinBg.clear() end

    local PAD    = 20
    local MARGIN = { top = 12, right = 12, bottom = 12, left = 12 }
    local font   = self._font or love.graphics.getFont()
    local line_h = font:getHeight()
    local gap_h  = math.floor(line_h * 0.6)

    local gs      = self.game_state
    local elapsed = math.floor((gs.first_idol_at or os.time()) - (gs.started_at or os.time()))
    local mins    = math.floor(elapsed / 60)
    local secs    = elapsed % 60
    local time_str
    if mins > 0 then
        time_str = string.format("%dm %ds", mins, secs)
    else
        time_str = string.format("%ds", secs)
    end
    local cancel_icon = self.input:icon_key_for("cancel")
    local cancel_key  = self.input:key_for("cancel") or "Esc"
    local ICON_SIZE   = 16
    local hint_pre    = "Press "
    local hint_post   = " to go back."

    local text_lines = {
        "Thank you for playing!",
        "You bought the idol in " .. time_str .. ".",
        "",
    }

    local content_w = 0
    for _, line in ipairs(text_lines) do
        if line ~= "" then
            local lw = font:getWidth(line)
            if lw > content_w then content_w = lw end
        end
    end
    local hint_w
    if cancel_icon and A[cancel_icon] then
        hint_w = font:getWidth(hint_pre) + ICON_SIZE + font:getWidth(hint_post)
    else
        hint_w = font:getWidth(hint_pre .. cancel_key .. hint_post)
    end
    if hint_w > content_w then content_w = hint_w end

    local content_h = line_h * 2 + gap_h + line_h
    local box_w = content_w + PAD * 2
    local box_h = content_h + PAD * 2
    local box_x = math.floor((config.LOGICAL_W - box_w) / 2)
    local box_y = math.floor(config.LOGICAL_H * 0.75 - box_h / 2)

    love.graphics.setColor(1, 1, 1, 1)
    UI.draw9(A.speech_bubble, box_x, box_y, box_w, box_h, MARGIN)

    love.graphics.setFont(font)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    local cy = box_y + PAD
    for _, line in ipairs(text_lines) do
        if line ~= "" then
            love.graphics.printf(line, box_x + PAD, cy, content_w, "center")
            cy = cy + line_h
        else
            cy = cy + gap_h
        end
    end

    if cancel_icon and A[cancel_icon] then
        local total_w = font:getWidth(hint_pre) + ICON_SIZE + font:getWidth(hint_post)
        local lx = box_x + PAD + math.floor((content_w - total_w) / 2)
        local iy = cy + math.floor((line_h - ICON_SIZE) / 2)
        love.graphics.print(hint_pre, lx, cy)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(A[cancel_icon], lx + font:getWidth(hint_pre), iy)
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.print(hint_post, lx + font:getWidth(hint_pre) + ICON_SIZE, cy)
    else
        love.graphics.printf(hint_pre .. cancel_key .. hint_post, box_x + PAD, cy, content_w, "center")
    end
    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return WinScene
