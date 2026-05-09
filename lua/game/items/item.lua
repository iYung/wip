local Sprite = require("lua/core/sprite")

local Item = {}
Item.__index = Item

function Item.new()
    local self     = setmetatable({}, Item)
    self.sprite    = Sprite.new(0, 0, 40, 40)
    self.carriable = true
    return self
end

function Item:update(dt) end

function Item:interact(player, store, scene_manager) end

function Item:draw()
    self.sprite:draw()
end

return Item
