local Slot        = require("lua/game/slot")
local WallPattern = require("lua/game/shaders/wall_pattern")

local Store = {}
Store.__index = Store

function Store.new(initial_count, slot_width)
    local self       = setmetatable({}, Store)
    self.slot_width  = slot_width
    self.slots       = {}
    for i = 1, initial_count do
        self.slots[i] = Slot.new(i, self.slot_width)
    end
    return self
end

function Store:width()
    return #self.slots * self.slot_width
end

function Store:grow()
    local idx = #self.slots + 1
    self.slots[idx] = Slot.new(idx, self.slot_width)
end

function Store:slot_at(x)
    local idx = math.floor(x / self.slot_width) + 1
    idx = math.max(1, math.min(#self.slots, idx))
    return self.slots[idx]
end

function Store:update(dt)
    for _, slot in ipairs(self.slots) do
        slot:update(dt)
    end
end

function Store:draw_bg(A)
    local n  = #self.slots
    local sw = self.slot_width
    love.graphics.setColor(1, 1, 1, 1)

    local use_shader = A.wall_pattern ~= nil

    local function draw_wall(img, x)
        if use_shader then WallPattern.apply(A.wall_pattern, x, 0.0, img) end
        love.graphics.draw(img, x, 0)
        if use_shader then WallPattern.clear() end
    end

    local g = 0
    while g * 4 < n do
        for i = g * 4, g * 4 + 1 do
            if i < n then draw_wall(A.store_wall, i * sw) end
        end
        local r0, r1 = g * 4 + 2, g * 4 + 3
        if r1 < n - 1 then
            draw_wall(A.store_window, r0 * sw)
        else
            for i = r0, r1 do
                if i < n then draw_wall(A.store_wall, i * sw) end
            end
        end
        g = g + 1
    end

end

function Store:draw()
    for _, slot in ipairs(self.slots) do
        slot:draw()
    end
end

function Store:draw_bubbles()
    for _, slot in ipairs(self.slots) do
        if slot.item and slot.item.draw_bubble then
            slot.item:draw_bubble()
        end
    end
end

return Store
