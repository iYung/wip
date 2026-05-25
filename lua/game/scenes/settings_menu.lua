local ITEMS = { "Fullscreen / Window", "Keybinds", "Exit Settings", "Leave Game" }

local _ACTION_LIST   = {"move_up","move_down","move_left","move_right","pick_up_down","interact"}
local _ACTION_LABELS = {"move up","move down","move left","move right","pick up/down","interact"}

local _MODIFIERS = {
    lshift=true, rshift=true, lctrl=true, rctrl=true,
    lalt=true, ralt=true, lgui=true, rgui=true,
    capslock=true, numlock=true, scrolllock=true
}

local W       = 1280
local H       = 720
local BTN_W   = 300
local BTN_H   = 54
local BTN_X   = (W - BTN_W) / 2
local BTN_GAP = 74

local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu

SettingsMenu.is_open = false
SettingsMenu.selected = 1
SettingsMenu._prev_up      = false
SettingsMenu._prev_down    = false
SettingsMenu._prev_confirm = false
SettingsMenu._prev_escape  = false

function SettingsMenu.new(settings_state, input)
    local self = setmetatable({}, SettingsMenu)
    self._state = settings_state
    self._input = input
    self._subscreen = nil
    self._subscreen_selected = 1
    self._capturing = nil
    self._prev_sub_up      = false
    self._prev_sub_down    = false
    self._prev_sub_confirm = false
    self._prev_sub_escape  = false
    self._img_btn     = love.graphics.newImage("assets/start_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/start_btn_selected.png")
    self._img_bg      = love.graphics.newImage("assets/settings_background.png")
    self._font_btn    = love.graphics.newFont(22)
    self._btn_y0      = H / 2 - (#ITEMS - 1) * BTN_GAP / 2 - BTN_H / 2
    self._sub_btn_y0  = H / 2 - #_ACTION_LIST * BTN_GAP / 2 - BTN_H / 2  -- centres 7 sub-screen rows
    return self
end

function SettingsMenu:open(opaque)
    self.is_open  = true
    self._opaque  = opaque or false
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
    if self._subscreen == "keybinds" then
        if self._capturing ~= nil then
            return
        end

        local up      = love.keyboard.isDown("up")   or love.keyboard.isDown(self._state.keybinds.move_up   or "w")
        local down    = love.keyboard.isDown("down") or love.keyboard.isDown(self._state.keybinds.move_down or "s")
        local confirm = love.keyboard.isDown(self._state.keybinds.pick_up_down or "e")
                     or love.keyboard.isDown(self._state.keybinds.interact     or "f")
                     or love.keyboard.isDown("return") or love.keyboard.isDown("space")
        local escape  = love.keyboard.isDown("escape")

        local sub_count = #_ACTION_LIST + 1
        if up and not self._prev_sub_up then
            self._subscreen_selected = ((self._subscreen_selected - 2) % sub_count) + 1
        end
        if down and not self._prev_sub_down then
            self._subscreen_selected = (self._subscreen_selected % sub_count) + 1
        end
        if confirm and not self._prev_sub_confirm then
            if self._subscreen_selected == sub_count then
                self._subscreen = nil
            else
                self._capturing = _ACTION_LIST[self._subscreen_selected]
            end
        end
        if escape and not self._prev_sub_escape then
            self._subscreen = nil
        end

        self._prev_sub_up      = up
        self._prev_sub_down    = down
        self._prev_sub_confirm = confirm
        self._prev_sub_escape  = escape
        return
    end

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
        self._state:toggle_fullscreen()
    elseif self.selected == 2 then
        self._subscreen = "keybinds"
        self._subscreen_selected = 1
        -- Snapshot so keys held at transition time don't immediately fire in the sub-screen
        self._prev_sub_up      = love.keyboard.isDown("up")   or love.keyboard.isDown(self._state.keybinds.move_up   or "w")
        self._prev_sub_down    = love.keyboard.isDown("down") or love.keyboard.isDown(self._state.keybinds.move_down or "s")
        self._prev_sub_confirm = love.keyboard.isDown(self._state.keybinds.pick_up_down or "e")
                              or love.keyboard.isDown(self._state.keybinds.interact     or "f")
                              or love.keyboard.isDown("return") or love.keyboard.isDown("space")
        self._prev_sub_escape  = love.keyboard.isDown("escape")
    elseif self.selected == 3 then
        self:close()
    elseif self.selected == 4 then
        love.event.quit()
    end
end

function SettingsMenu:keypressed(key)
    if self._subscreen == "keybinds" and self._capturing == nil then
        if key == "escape" then
            self._subscreen = nil
            return true
        end
        return false
    end
    if self._capturing == nil then return false end
    if key == "escape" then
        self._capturing = nil
        return true
    end
    if _MODIFIERS[key] then return false end
    self._state:set_keybind(self._capturing, key)
    self._input._map = self._state:key_map()
    self._capturing = nil
    return true
end

function SettingsMenu:draw()
    local prev_font = love.graphics.getFont()

    if self._subscreen == "keybinds" then
        -- Background
        love.graphics.setColor(1, 1, 1, 1)
        if self._opaque then
            love.graphics.draw(self._img_bg, 0, 0)
        else
            love.graphics.setColor(0, 0, 0, 0.55)
            love.graphics.rectangle("fill", 0, 0, W, H)
        end

        local sub_count = #_ACTION_LIST + 1
        love.graphics.setFont(self._font_btn)
        for i = 1, #_ACTION_LIST do
            local y = self._sub_btn_y0 + (i - 1) * BTN_GAP
            local img = i == self._subscreen_selected and self._img_btn_sel or self._img_btn
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, BTN_X, y)

            local right_label
            if self._capturing == _ACTION_LIST[i] then
                right_label = "[press a key]"
            else
                right_label = "[" .. (self._state.keybinds[_ACTION_LIST[i]] or "unbound"):upper() .. "]"
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(_ACTION_LABELS[i], BTN_X + 10, y + (BTN_H - self._font_btn:getHeight()) / 2)
            love.graphics.printf(right_label, BTN_X, y + (BTN_H - self._font_btn:getHeight()) / 2, BTN_W - 10, "right")
        end

        local ry  = self._sub_btn_y0 + #_ACTION_LIST * BTN_GAP
        local img = sub_count == self._subscreen_selected and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, BTN_X, ry)
        love.graphics.printf("Return", BTN_X, ry + (BTN_H - self._font_btn:getHeight()) / 2, BTN_W, "center")

        love.graphics.setFont(prev_font)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Background: image when opened from start scene, semi-transparent overlay in-game
    love.graphics.setColor(1, 1, 1, 1)
    if self._opaque then
        love.graphics.draw(self._img_bg, 0, 0)
    else
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, W, H)
    end

    love.graphics.setFont(self._font_btn)
    for i = 1, #ITEMS do
        local y   = self._btn_y0 + (i - 1) * BTN_GAP
        local img = i == self.selected and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, BTN_X, y)

        local label
        if i == 1 then
            label = self._state.fullscreen and "Window" or "Fullscreen"
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
