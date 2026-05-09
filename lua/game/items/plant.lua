local Item       = require("lua/game/items/item")
local SpriteSet  = require("lua/core/spriteset")
local Sprite     = require("lua/core/sprite")
local PLANT_DATA = require("lua/game/data/plant_data")
local U          = require("lua/game/config").U

local Plant = setmetatable({}, { __index = Item })
Plant.__index = Plant

local ITEM_SIZE = 6 * U  -- 120; all items are square and same size

function Plant.new(plant_type)
    local self       = Item.new()
    setmetatable(self, Plant)
    self.plant_type  = plant_type or 1
    self.stage       = 1
    self.carriable   = true
    self.cooldown    = PLANT_DATA[self.plant_type].cooldowns[1]
    self.ready       = false

    local colors = PLANT_DATA[self.plant_type].colors
    local ss = SpriteSet.new()
    for i = 1, 3 do
        local s       = Sprite.new(0, 0, ITEM_SIZE, ITEM_SIZE)
        s.color       = colors[i]
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
    local next_cd = PLANT_DATA[self.plant_type].cooldowns[self.stage]
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
