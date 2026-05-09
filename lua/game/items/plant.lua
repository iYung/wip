local Item            = require("lua/game/items/item")
local SpriteSet       = require("lua/core/spriteset")
local Sprite          = require("lua/core/sprite")
local PLANT_COOLDOWNS = require("lua/game/data/plant_cooldowns")
local U               = require("lua/game/config").U

local Plant = setmetatable({}, { __index = Item })
Plant.__index = Plant

local STAGE_COLORS = {
    {0.4, 0.85, 0.4, 1},
    {0.1, 0.65, 0.2, 1},
    {0.0, 0.40, 0.1, 1},
}

local ITEM_SIZE = 6 * U  -- 120; all items are square and same size

function Plant.new(plant_type)
    local self       = Item.new()
    setmetatable(self, Plant)
    self.plant_type  = plant_type or 1
    self.stage       = 1
    self.carriable   = true
    self.cooldown    = PLANT_COOLDOWNS[self.plant_type][1]
    self.ready       = false

    local ss = SpriteSet.new()
    for i = 1, 3 do
        local s       = Sprite.new(0, 0, ITEM_SIZE, ITEM_SIZE)
        s.color       = STAGE_COLORS[i]
        ss:add(tostring(i), s)
    end
    ss:set("1")
    self.sprite = ss

    self.bubble         = Sprite.new(0, 0, 3 * U, 3 * U)  -- 60x60
    self.bubble.color   = {1.0, 1.0, 0.0, 1.0}
    self.bubble.visible = false

    return self
end

function Plant:update(dt)
    if not self.ready and self.stage < 3 then
        self.cooldown = self.cooldown - dt
        if self.cooldown <= 0 then
            self.cooldown       = 0
            self.ready          = true
            self.bubble.visible = true
        end
    end
end

function Plant:water()
    if not self.ready then return end
    if self.stage >= 3 then return end
    self.stage          = self.stage + 1
    self.ready          = false
    self.bubble.visible = false
    self.sprite:set(tostring(self.stage))
    local next_cd = PLANT_COOLDOWNS[self.plant_type][self.stage]
    if next_cd then
        self.cooldown = next_cd
    end
end

function Plant:draw()
    self.sprite:draw()
    if self.bubble.visible then
        local active = self.sprite:_active()
        if active then
            self.bubble.x = active.x + active.width / 2 - self.bubble.width / 2
            self.bubble.y = active.y - self.bubble.height
        end
        self.bubble:draw()
    end
end

return Plant
