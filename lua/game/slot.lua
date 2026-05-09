local Sprite = require("lua/core/sprite")
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

    self.bg          = Sprite.new(self.x + 1, self.y + 1, self.slot_width - 2, SLOT_HEIGHT - 2)
    self.bg.color    = {0.22, 0.18, 0.14, 1}
    self.border      = Sprite.new(self.x, self.y, self.slot_width, SLOT_HEIGHT)
    self.border.color = {0.35, 0.28, 0.20, 1}

    return self
end

function Slot:update(dt)
    if not self.item then return end
    self.item:update(dt)
    local spr = self.item.sprite
    if spr then
        spr.x = self.x + 3 * U
        spr.y = self.y + 2 * U
    end
end

function Slot:draw()
    self.border:draw()
    self.bg:draw()
    if self.item then
        self.item:draw()
    end
end

return Slot
