local Item       = require("lua/game/items/item")
local SpriteSet  = require("lua/core/spriteset")
local Sprite     = require("lua/core/sprite")
local Timer      = require("lua/core/timer")
local PLANT_DATA = require("lua/game/data/plant_data")
local A          = require("lua/game/assets")
local U          = require("lua/game/config").U
local Sound      = require("lua/core/sound")

local Plant = setmetatable({}, { __index = Item })
Plant.__index = Plant

local ITEM_SIZE = 6 * U  -- 120; all items are square and same size

function Plant.new(plant_type)
    local self       = Item.new()
    setmetatable(self, Plant)
    self.plant_type  = plant_type or 1
    self.stage       = 1
    self.carriable   = true
    self.name        = PLANT_DATA[self.plant_type].name
    self._cooldown   = Timer.new(PLANT_DATA[self.plant_type].cooldowns[1])
    self.ready       = false

    local ss = SpriteSet.new()
    for i = 1, 3 do
        local s       = Sprite.new(0, 0, ITEM_SIZE, ITEM_SIZE)
        s.image       = A["plant_" .. self.plant_type][i]
        ss:add(tostring(i), s)
    end
    ss:set("1")
    self.sprite = ss

    self.bubble         = Sprite.new(0, 0, 6 * U, 6 * U)  -- 120x120
    self.bubble.image   = A.plant_bubble
    self.bubble.color   = {1, 1, 1, 1}
    self.bubble.visible = false

    return self
end

function Plant:update(dt)
    if not self.ready and self.stage < 3 then
        if self._cooldown:update(dt) then
            self.ready          = true
            self.bubble.visible = true
            Sound.play("plant_ready")
        end
    end
end

function Plant:water()
    if not self.ready then return false end
    if self.stage >= 3 then return false end
    self.stage          = self.stage + 1
    self.ready          = false
    self.bubble.visible = false
    self.sprite:set(tostring(self.stage))
    local next_cd = PLANT_DATA[self.plant_type].cooldowns[self.stage]
    if next_cd then
        self._cooldown:reset(next_cd)
    end
    return true
end

function Plant:draw()
    self.sprite:draw()
end

function Plant:draw_bubble()
    if not self.bubble.visible then return end
    local active = self.sprite:_active()
    if active then
        self.bubble.x = active.x + active.width / 2 - self.bubble.width / 2
        self.bubble.y = active.y - self.bubble.height - 10
    end
    self.bubble:draw()
end

return Plant
