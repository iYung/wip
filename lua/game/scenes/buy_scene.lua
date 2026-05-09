local Scene       = require("lua/core/scene")
local Plant       = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local Grafter     = require("lua/game/items/grafter")
local config      = require("lua/game/config")
local PLANT_DATA  = require("lua/game/data/plant_data")

local CATALOGUE = {}

for i = 1, #PLANT_DATA do
    local pd = PLANT_DATA[i]
    CATALOGUE[#CATALOGUE + 1] = {
        label       = pd.name,
        description = pd.description,
        cost        = pd.cost,
        kind        = "plant",
        plant_type  = i,
        color       = pd.colors[1],
    }
end

CATALOGUE[#CATALOGUE + 1] = {
    label       = "Watering Can",
    description = "Waters the plant in your\ncurrent slot when you press F.",
    cost        = 0,
    kind        = "tool_watering_can",
    color       = {0.3, 0.6, 1.0, 1},
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Grafter",
    description = "Clones a stage-3 plant.\nPress F to load, E to place clone.",
    cost        = 0,
    kind        = "tool_grafter",
    color       = {1.0, 0.5, 0.0, 1},
}
CATALOGUE[#CATALOGUE + 1] = {
    label       = "Expand Slot",
    description = "Adds one new slot to the\nright end of the store.",
    cost        = config.SLOT_COST,
    kind        = "expand",
    color       = {0.8, 0.8, 0.8, 1},
}

local PREVIEW_SIZE = 120
local CENTER_X     = 640
local CENTER_Y     = 360

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
    self.selected        = 1
    return self
end

function BuyScene:on_enter() end

function BuyScene:on_exit() end

function BuyScene:update(dt)
    local input = self.input
    local n     = #CATALOGUE

    if input:pressed("move_left") then
        self.selected = ((self.selected - 2) % n) + 1
    elseif input:pressed("move_right") then
        self.selected = (self.selected % n) + 1
    end

    if input:pressed("interact") then
        self:_confirm()
    elseif input:pressed("pick_up_down") then
        self.scene_manager:switch(self.store_scene)
    end
end

function BuyScene:_confirm()
    local gs  = self.game_state
    local ent = CATALOGUE[self.selected]

    if gs.currency < ent.cost then return end

    gs.currency = gs.currency - ent.cost

    local kind = ent.kind
    if kind == "plant" then
        gs.player.held_item = Plant.new(ent.plant_type)
    elseif kind == "tool_watering_can" then
        gs.player.held_item = WateringCan.new()
    elseif kind == "tool_grafter" then
        gs.player.held_item = Grafter.new()
    elseif kind == "expand" then
        gs.store:grow()
    end

    self.scene_manager:switch(self.store_scene)
end

function BuyScene:draw()
    local gs       = self.game_state
    local currency = gs.currency
    local ent      = CATALOGUE[self.selected]
    local can_buy  = currency >= ent.cost

    -- overlay
    love.graphics.setColor(0, 0, 0, 0.88)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- currency top-right
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Currency: " .. currency, 1100, 20, 0, 1.2, 1.2)

    -- item preview rectangle
    love.graphics.setColor(ent.color)
    love.graphics.rectangle("fill",
        CENTER_X - PREVIEW_SIZE / 2,
        CENTER_Y - 140 - PREVIEW_SIZE / 2,
        PREVIEW_SIZE, PREVIEW_SIZE)

    -- item name
    love.graphics.setColor(1, 1, 1, 1)
    local font        = love.graphics.getFont()
    local name_scale  = 2
    local name_w      = font:getWidth(ent.label) * name_scale
    love.graphics.print(ent.label, CENTER_X - name_w / 2, CENTER_Y - 40, 0, name_scale, name_scale)

    -- description
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local desc_lines = {}
    for line in (ent.description .. "\n"):gmatch("([^\n]*)\n") do
        desc_lines[#desc_lines + 1] = line
    end
    local desc_scale = 1.2
    for i, line in ipairs(desc_lines) do
        local lw = font:getWidth(line) * desc_scale
        love.graphics.print(line, CENTER_X - lw / 2, CENTER_Y + 10 + (i - 1) * 24, 0, desc_scale, desc_scale)
    end

    -- price
    if can_buy then
        love.graphics.setColor(0.4, 1.0, 0.4, 1)
    else
        love.graphics.setColor(0.6, 0.3, 0.3, 1)
    end
    local price_scale = 1.6
    local price_str   = "$" .. ent.cost
    local price_w     = font:getWidth(price_str) * price_scale
    love.graphics.print(price_str, CENTER_X - price_w / 2, CENTER_Y + 80, 0, price_scale, price_scale)

    -- cycle arrows
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print("<", CENTER_X - 220, CENTER_Y - 40, 0, 2.5, 2.5)
    love.graphics.print(">", CENTER_X + 190, CENTER_Y - 40, 0, 2.5, 2.5)

    -- index dots
    local dot_gap = 18
    local dot_start = CENTER_X - (#CATALOGUE - 1) * dot_gap / 2
    for i = 1, #CATALOGUE do
        if i == self.selected then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.4, 0.4, 0.4, 1)
        end
        love.graphics.circle("fill", dot_start + (i - 1) * dot_gap, CENTER_Y + 130, 5)
    end

    -- controls hint
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.print("A/D cycle   F buy   E cancel", 460, 680, 0, 1.1, 1.1)

    love.graphics.setColor(1, 1, 1, 1)
end

return BuyScene
