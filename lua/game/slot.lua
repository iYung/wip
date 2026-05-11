local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U

local SLOT_HEIGHT = 10 * U  -- 200
local SLOT_Y      = 30 * U  -- 600  world y of slot top

local Slot = {}
Slot.__index = Slot

function Slot.new(index, slot_width)
    local self       = setmetatable({}, Slot)
    self.index       = index
    self.slot_width  = slot_width or 120
    self.x           = (index - 1) * self.slot_width
    self.y           = SLOT_Y
    self.item        = nil

    self.bg       = Sprite.new(self.x, self.y, self.slot_width, SLOT_HEIGHT)
    self.bg.image = A.slot
    self.bg.color = {1, 1, 1, 1}

    self.highlighted = false

    return self
end

function Slot:update(dt)
    if not self.item then return end
    self.item:update(dt)
    local spr = self.item.sprite
    if spr then
        spr.x = self.x + (self.slot_width - spr.width)  / 2
        spr.y = self.y + (SLOT_HEIGHT     - spr.height) / 2 - 80
    end
end

function Slot:draw()
    self.bg:draw()
    if self.highlighted then
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.rectangle("fill", self.x, self.y, self.slot_width, SLOT_HEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
    end
    if self.item then
        self.item:draw()
    end
end

return Slot
