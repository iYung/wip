local Sound = require("lua/game/sound")
local Fonts = require("lua/game/fonts")

local ITEMS = { "Fullscreen / Window", "SFX Volume", "Music Volume", "Keybinds", "Save Game", "Exit Settings", "Leave Game" }

local function _visible_items(opaque)
    local result = {}
    for i = 1, #ITEMS do
        if not (opaque and i == 5) then result[#result + 1] = i end
    end
    return result
end

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

local LABEL_W    = 180
local VAL_W      = 110
local BAR_GAP    = 10
local ARROW_PAD  = 10
local LABEL_SX = LABEL_W / BTN_W   -- horizontal scale for label bar image
local VAL_SX   = VAL_W  / BTN_W    -- horizontal scale for value bar image

local SettingsMenu = {}
SettingsMenu.__index = SettingsMenu

function SettingsMenu.new(settings_state, input, on_save, on_leave)
    local self = setmetatable({}, SettingsMenu)
    self.is_open = false
    self.selected = 1
    self._prev_up      = false
    self._prev_down    = false
    self._prev_left    = false
    self._prev_right   = false
    self._prev_confirm = false
    self._prev_escape  = false
    self._state = settings_state
    self._input = input
    self._on_save  = on_save
    self._on_leave = on_leave
    self._subscreen = nil
    self._subscreen_selected = 1
    self._capturing = nil
    self._prev_sub_up      = false
    self._prev_sub_down    = false
    self._prev_sub_confirm = false
    self._prev_sub_escape  = false
    self._img_btn     = love.graphics.newImage("assets/images/menu_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/images/menu_btn_selected.png")

    self._img_bgs     = {
        love.graphics.newImage("assets/images/settings_pattern_1.png"),
        love.graphics.newImage("assets/images/settings_pattern_2.png"),
    }
    self._bg_frame    = 1
    self._bg_timer    = 0
    self._font_btn    = Fonts.new(22)
    self._font_vol    = Fonts.new(15)
    self._btn_y0      = H / 2 - (#ITEMS - 1) * BTN_GAP / 2 - BTN_H / 2
    self._sub_btn_y0  = H / 2 - #_ACTION_LIST * BTN_GAP / 2 - BTN_H / 2  -- centres 7 sub-screen rows
    return self
end

function SettingsMenu:open(opaque)
    self.is_open  = true
    self._opaque  = opaque or false
    self.selected = 1
    self._subscreen = nil
    self._capturing = nil
    self._saved = false
    -- Snapshot current key state so keys held at open time don't immediately fire
    self._prev_up      = love.keyboard.isDown("up")    or love.keyboard.isDown("w")
    self._prev_down    = love.keyboard.isDown("down")  or love.keyboard.isDown("s")
    self._prev_left    = love.keyboard.isDown("left")  or love.keyboard.isDown("a")
    self._prev_right   = love.keyboard.isDown("right") or love.keyboard.isDown("d")
    self._prev_confirm = love.keyboard.isDown("e")     or love.keyboard.isDown("f")
                      or love.keyboard.isDown("return") or love.keyboard.isDown("space")
    self._prev_escape  = love.keyboard.isDown("escape")
end

function SettingsMenu:close()
    self.is_open = false
end

function SettingsMenu:update(dt)
    self._bg_timer = self._bg_timer + dt
    if self._bg_timer >= 1 then
        self._bg_timer = self._bg_timer - 1
        self._bg_frame = (self._bg_frame % 2) + 1
    end

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
            Sound.play("menu_navigate")
        end
        if down and not self._prev_sub_down then
            self._subscreen_selected = (self._subscreen_selected % sub_count) + 1
            Sound.play("menu_navigate")
        end
        if confirm and not self._prev_sub_confirm then
            Sound.play("menu_confirm")
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

    local up      = love.keyboard.isDown("up")    or love.keyboard.isDown("w")
    local down    = love.keyboard.isDown("down")  or love.keyboard.isDown("s")
    local left    = love.keyboard.isDown("left")  or love.keyboard.isDown("a")
    local right   = love.keyboard.isDown("right") or love.keyboard.isDown("d")
    local confirm = love.keyboard.isDown("e")      or love.keyboard.isDown("f")
                 or love.keyboard.isDown("return") or love.keyboard.isDown("space")
    local escape  = love.keyboard.isDown("escape")

    if up and not self._prev_up then
        local vis = _visible_items(self._opaque)
        for j, idx in ipairs(vis) do
            if idx == self.selected then
                self.selected = vis[((j - 2) % #vis) + 1]
                break
            end
        end
        Sound.play("menu_navigate")
    end
    if down and not self._prev_down then
        local vis = _visible_items(self._opaque)
        for j, idx in ipairs(vis) do
            if idx == self.selected then
                self.selected = vis[(j % #vis) + 1]
                break
            end
        end
        Sound.play("menu_navigate")
    end
    if confirm and not self._prev_confirm then
        self:_confirm()
    end
    if escape and not self._prev_escape then
        self:close()
    end
    if left and not self._prev_left and self.selected == 2 then
        self._state:set_sfx_volume(self._state.sfx_volume - 10)
        Sound.play("menu_navigate")
    end
    if right and not self._prev_right and self.selected == 2 then
        self._state:set_sfx_volume(self._state.sfx_volume + 10)
        Sound.play("menu_navigate")
    end
    if left and not self._prev_left and self.selected == 3 then
        self._state:set_music_volume(self._state.music_volume - 10)
        Sound.play("menu_navigate")
    end
    if right and not self._prev_right and self.selected == 3 then
        self._state:set_music_volume(self._state.music_volume + 10)
        Sound.play("menu_navigate")
    end

    self._prev_up      = up
    self._prev_down    = down
    self._prev_left    = left
    self._prev_right   = right
    self._prev_confirm = confirm
    self._prev_escape  = escape
end

function SettingsMenu:_confirm()
    Sound.play("menu_confirm")
    if self.selected == 1 then
        self._state:toggle_fullscreen()
    elseif self.selected == 4 then
        self._subscreen = "keybinds"
        self._subscreen_selected = 1
        -- Snapshot so keys held at transition time don't immediately fire in the sub-screen
        self._prev_sub_up      = love.keyboard.isDown("up")   or love.keyboard.isDown(self._state.keybinds.move_up   or "w")
        self._prev_sub_down    = love.keyboard.isDown("down") or love.keyboard.isDown(self._state.keybinds.move_down or "s")
        self._prev_sub_confirm = love.keyboard.isDown(self._state.keybinds.pick_up_down or "e")
                              or love.keyboard.isDown(self._state.keybinds.interact     or "f")
                              or love.keyboard.isDown("return") or love.keyboard.isDown("space")
        self._prev_sub_escape  = love.keyboard.isDown("escape")
    elseif self.selected == 5 then
        if not self._opaque and self._on_save then
            self._on_save()
            self._saved = true
        end
    elseif self.selected == 6 then
        self:close()
    elseif self.selected == 7 then
        if self._on_leave then
            self._on_leave()
        else
            love.event.quit()
        end
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
            love.graphics.draw(self._img_bgs[self._bg_frame], 0, 0)
        else
            love.graphics.setColor(0, 0, 0, 0.55)
            love.graphics.rectangle("fill", 0, 0, W, H)
        end

        local sub_count = #_ACTION_LIST + 1
        love.graphics.setFont(self._font_btn)
        for i = 1, #_ACTION_LIST do
            local y = self._sub_btn_y0 + (i - 1) * BTN_GAP
            local img = i == self._subscreen_selected and self._img_btn_sel or self._img_btn
            local ty = y + (BTN_H - self._font_btn:getHeight()) / 2
            -- Label bar
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, BTN_X, y, 0, LABEL_SX, 1)
            love.graphics.printf(_ACTION_LABELS[i], BTN_X, ty, LABEL_W, "center")
            -- Value bar
            love.graphics.draw(img, BTN_X + LABEL_W + BAR_GAP, y, 0, VAL_SX, 1)
            if self._capturing == _ACTION_LIST[i] then
                love.graphics.printf("hit key", BTN_X + LABEL_W + BAR_GAP, ty, VAL_W, "center")
            else
                love.graphics.printf((self._state.keybinds[_ACTION_LIST[i]] or "unbound"):upper(), BTN_X + LABEL_W + BAR_GAP, ty, VAL_W, "center")
            end
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
        love.graphics.draw(self._img_bgs[self._bg_frame], 0, 0)
    else
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, W, H)
    end

    love.graphics.setFont(self._font_btn)
    local vis    = _visible_items(self._opaque)
    local btn_y0 = H / 2 - (#vis - 1) * BTN_GAP / 2 - BTN_H / 2
    for j, i in ipairs(vis) do
        local y   = btn_y0 + (j - 1) * BTN_GAP
        local img = i == self.selected and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        if i ~= 2 and i ~= 3 then
            love.graphics.draw(img, BTN_X, y)
        end

        love.graphics.setColor(1, 1, 1, 1)
        local th = self._font_btn:getHeight()
        local ty = y + (BTN_H - th) / 2
        if i == 1 then
            love.graphics.printf(self._state.fullscreen and "Window" or "Fullscreen", BTN_X, ty, BTN_W, "center")
        elseif i == 2 then
            -- Label bar
            love.graphics.draw(img, BTN_X, y, 0, LABEL_SX, 1)
            love.graphics.printf("SFX Volume", BTN_X, ty, LABEL_W, "center")
            -- Value bar
            local vx  = BTN_X + LABEL_W + BAR_GAP + 5
            local vty = y + (BTN_H - self._font_vol:getHeight()) / 2
            love.graphics.draw(img, vx, y, 0, VAL_SX, 1)
            local vol = self._state.sfx_volume
            love.graphics.setFont(self._font_vol)
            if vol > 0   then love.graphics.printf("<", vx + ARROW_PAD, vty, VAL_W,              "left")  end
            if vol < 100 then love.graphics.printf(">", vx,             vty, VAL_W - ARROW_PAD, "right") end
            love.graphics.printf(tostring(vol) .. "%", vx, vty, VAL_W, "center")
            love.graphics.setFont(self._font_btn)
        elseif i == 3 then
            -- Label bar
            love.graphics.draw(img, BTN_X, y, 0, LABEL_SX, 1)
            love.graphics.printf("Music Volume", BTN_X, ty, LABEL_W, "center")
            -- Value bar
            local vx  = BTN_X + LABEL_W + BAR_GAP + 5
            local vty = y + (BTN_H - self._font_vol:getHeight()) / 2
            love.graphics.draw(img, vx, y, 0, VAL_SX, 1)
            local vol = self._state.music_volume
            love.graphics.setFont(self._font_vol)
            if vol > 0   then love.graphics.printf("<", vx + ARROW_PAD, vty, VAL_W,              "left")  end
            if vol < 100 then love.graphics.printf(">", vx,             vty, VAL_W - ARROW_PAD, "right") end
            love.graphics.printf(tostring(vol) .. "%", vx, vty, VAL_W, "center")
            love.graphics.setFont(self._font_btn)
        else
            local label = (i == 5 and self._saved) and "Saved!"
                       or (i == 7 and not self._opaque) and "Main Menu"
                       or ITEMS[i]
            love.graphics.printf(label, BTN_X, ty, BTN_W, "center")
        end
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return SettingsMenu
