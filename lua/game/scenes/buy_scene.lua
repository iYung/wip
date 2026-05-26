local Scene       = require("lua/core/scene")
local Plant       = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local Grafter     = require("lua/game/items/grafter")
local config      = require("lua/game/config")
local PLANT_DATA  = require("lua/game/data/plant_data")
local A           = require("lua/game/assets")
local SPEED_TIERS    = require("lua/game/data/speed_tiers")
local GROWTH_TIERS   = require("lua/game/data/growth_tiers")
local ColorReplace   = require("lua/game/shaders/color_replace")
local CRT            = require("lua/game/shaders/crt")
local Sound          = require("lua/game/sound")

local CATALOGUE = {}

for i = 1, #PLANT_DATA do
    local pd = PLANT_DATA[i]
    CATALOGUE[#CATALOGUE + 1] = {
        label       = pd.name,
        description = pd.description,
        cost        = pd.cost,
        kind        = "plant",
        plant_type  = i,
    }
end

CATALOGUE[#CATALOGUE + 1] = {
    label       = "Watering Can",
    description = "Waters the plant in your\ncurrent slot when you press F.",
    cost        = 0,
    kind        = "tool_watering_can",
    image       = A.watering_can,
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Grafter",
    description = "Clones a stage-3 plant.\nPress F to load, E to place clone.",
    cost        = 0,
    kind        = "tool_grafter",
    image       = A.grafter_empty,
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Expand Slot",
    description = "Adds one new slot to the\nright end of the store.",
    cost        = config.SLOT_COST,
    kind        = "expand",
    image       = A.expand_slot,
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Sneakers",
    description = "New shoes.\nMove faster!",
    kind        = "speed_boost",
    image       = A.sneakers,
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Heat Lamps",
    description = "Warm your plants.",
    kind        = "growth_boost",
    image       = A.heat_lamp_icon,
}

local PREVIEW_SIZE = 160
local CENTER_X     = 640
local CENTER_Y     = 360
local ARROW_SIZE   = 60

local font_name  = love.graphics.newFont(32)
local font_desc  = love.graphics.newFont(20)
local font_price = love.graphics.newFont(26)
local font_ui    = love.graphics.newFont(16)

local BuyScene = setmetatable({}, { __index = Scene })
BuyScene.__index = BuyScene

function BuyScene.new(game_state, input, scene_manager, store_scene)
    local self           = Scene.new()
    setmetatable(self, BuyScene)
    self.game_state      = game_state
    self.input           = input
    self.scene_manager   = scene_manager
    self.store_scene     = store_scene
    self.selected        = 1
    self.canvas          = love.graphics.newCanvas(1280, 720)
    self.esc_opens_settings = true
    return self
end

function BuyScene:on_enter() end

function BuyScene:on_exit() end

function BuyScene:update(dt)
    local input = self.input
    local n     = #CATALOGUE

    if input:pressed("move_left") then
        self.selected = ((self.selected - 2) % n) + 1
        Sound.play("shop_navigate")
    elseif input:pressed("move_right") then
        self.selected = (self.selected % n) + 1
        Sound.play("shop_navigate")
    end

    if input:pressed("interact") then
        self:_confirm()
    elseif input:pressed("pick_up_down") then
        Sound.play("shop_close")
        self.scene_manager:switch(self.store_scene)
    end
end

function BuyScene:_confirm()
    local gs  = self.game_state
    local ent = CATALOGUE[self.selected]

    if ent.kind == "speed_boost" then
        if gs.speed_level >= #SPEED_TIERS then return end
        local tier = SPEED_TIERS[gs.speed_level + 1]
        if gs.currency < tier.cost then return end
        gs.currency     = gs.currency - tier.cost
        gs.speed_level  = gs.speed_level + 1
        gs.player.speed = tier.speed
        gs.player:set_speed_color(tier.color)
        Sound.play("shop_buy")
        return
    end

    if ent.kind == "growth_boost" then
        if gs.growth_level >= #GROWTH_TIERS then return end
        local tier = GROWTH_TIERS[gs.growth_level + 1]
        if gs.currency < tier.cost then return end
        gs.currency     = gs.currency - tier.cost
        gs.growth_level = gs.growth_level + 1
        gs.growth_mult  = tier.mult
        Sound.play("shop_buy")
        return
    end

    if gs.currency < ent.cost then return end

    gs.currency = gs.currency - ent.cost

    local kind = ent.kind
    if kind == "plant" then
        gs.player.held_item = Plant.new(ent.plant_type)
        gs.unlocked_plants[ent.plant_type] = true
        Sound.play("shop_buy")
        self.scene_manager:switch(self.store_scene)
    elseif kind == "tool_watering_can" then
        gs.player.held_item = WateringCan.new()
        Sound.play("shop_buy")
        self.scene_manager:switch(self.store_scene)
    elseif kind == "tool_grafter" then
        gs.player.held_item = Grafter.new()
        Sound.play("shop_buy")
        self.scene_manager:switch(self.store_scene)
    elseif kind == "expand" then
        gs.store:grow()
        Sound.play("shop_buy")
    end
end

function BuyScene:draw()
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    local gs       = self.game_state
    local currency = gs.currency
    local ent      = CATALOGUE[self.selected]

    local display_cost, display_desc, can_buy
    if ent.kind == "speed_boost" then
        if gs.speed_level >= #SPEED_TIERS then
            display_cost = "---"
            display_desc = "Max speed reached."
            can_buy      = false
        else
            local tier   = SPEED_TIERS[gs.speed_level + 1]
            display_cost = "$" .. tier.cost
            display_desc = ent.description
            can_buy      = currency >= tier.cost
        end
    elseif ent.kind == "growth_boost" then
        if gs.growth_level >= #GROWTH_TIERS then
            display_cost = "---"
            display_desc = "Max growth reached."
            can_buy      = false
        else
            local tier   = GROWTH_TIERS[gs.growth_level + 1]
            display_cost = "$" .. tier.cost
            display_desc = ent.description .. "\n" .. math.floor(tier.mult * 100 - 100) .. "% faster"
            can_buy      = currency >= tier.cost
        end
    else
        display_cost = "$" .. ent.cost
        display_desc = ent.description
        can_buy      = currency >= ent.cost
    end

    -- background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(A.buy_bg, 0, 0)

    local prev_font = love.graphics.getFont()

    -- currency top-right
    love.graphics.setFont(font_ui)
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.print("Currency: " .. currency, 56, 44)

    -- build desc lines early so we can measure total height
    local desc_lines = {}
    for line in (display_desc .. "\n"):gmatch("([^\n]*)\n") do
        desc_lines[#desc_lines + 1] = line
    end

    local gap1    = 40   -- preview → name
    local gap2    = 20   -- name → description
    local gap3    = 28   -- description → price
    local line_h  = 28
    local total_h = PREVIEW_SIZE
                  + gap1 + font_name:getHeight()
                  + gap2 + #desc_lines * line_h
                  + gap3 + font_price:getHeight()
    local y = math.floor((720 - total_h) / 2)

    -- item preview
    if ent.kind == "plant" then
        local img = A["plant_" .. ent.plant_type][3]
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img,
            CENTER_X - PREVIEW_SIZE / 2, y,
            0,
            PREVIEW_SIZE / img:getWidth(),
            PREVIEW_SIZE / img:getHeight())
    elseif ent.kind == "speed_boost" and ent.image then
        local next_tier = SPEED_TIERS[gs.speed_level + 1]
        if next_tier then ColorReplace.apply(next_tier.color) end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ent.image,
            CENTER_X - PREVIEW_SIZE / 2, y,
            0,
            PREVIEW_SIZE / ent.image:getWidth(),
            PREVIEW_SIZE / ent.image:getHeight())
        if next_tier then ColorReplace.clear() end
    elseif ent.image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ent.image,
            CENTER_X - PREVIEW_SIZE / 2, y,
            0,
            PREVIEW_SIZE / ent.image:getWidth(),
            PREVIEW_SIZE / ent.image:getHeight())
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle("fill", CENTER_X - PREVIEW_SIZE / 2, y, PREVIEW_SIZE, PREVIEW_SIZE)
    end
    y = y + PREVIEW_SIZE + gap1

    -- item name
    love.graphics.setFont(font_name)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    local name_w = font_name:getWidth(ent.label)
    love.graphics.print(ent.label, CENTER_X - name_w / 2, y)
    y = y + font_name:getHeight() + gap2

    -- description
    love.graphics.setFont(font_desc)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    for i, line in ipairs(desc_lines) do
        local lw = font_desc:getWidth(line)
        love.graphics.print(line, CENTER_X - lw / 2, y + (i - 1) * line_h)
    end
    y = y + #desc_lines * line_h + gap3

    -- price
    love.graphics.setFont(font_price)
    if can_buy then
        love.graphics.setColor(0.1, 0.45, 0.1, 1)
    else
        love.graphics.setColor(0.5, 0.1, 0.1, 1)
    end
    local price_w = font_price:getWidth(display_cost)
    love.graphics.print(display_cost, CENTER_X - price_w / 2, y)

    -- cycle arrows (unchanged)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(A.arrow_left,  CENTER_X - 230 - ARROW_SIZE / 2, CENTER_Y - ARROW_SIZE / 2)
    love.graphics.draw(A.arrow_right, CENTER_X + 230 - ARROW_SIZE / 2, CENTER_Y - ARROW_SIZE / 2)

    -- index dots
    local dot_size  = 20
    local dot_gap   = 22
    local dot_start = CENTER_X - (#CATALOGUE - 1) * dot_gap / 2
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #CATALOGUE do
        local img = (i == self.selected) and A.dot_active or A.dot_inactive
        love.graphics.draw(img, dot_start + (i - 1) * dot_gap - dot_size / 2, CENTER_Y + 252)
    end

    -- controls hint
    love.graphics.setFont(font_ui)
    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    local hints = { "A/D: CYCLE", "F: BUY", "E: CANCEL" }
    local y = 652
    for _, hint in ipairs(hints) do
        love.graphics.print(hint, 56, y)
        y = y - 20
    end

    love.graphics.setFont(prev_font)

    love.graphics.setCanvas(prev_canvas)
    love.graphics.setColor(1, 1, 1, 1)
    CRT.apply()
    love.graphics.draw(self.canvas, 0, 0)
    CRT.clear()
end

return BuyScene
