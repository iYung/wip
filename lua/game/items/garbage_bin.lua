local Item   = require("lua/game/items/item")
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U

local GarbageBin = setmetatable({}, { __index = Item })
GarbageBin.__index = GarbageBin

function GarbageBin.new()
    local self          = Item.new()
    setmetatable(self, GarbageBin)
    self.sprite         = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image   = A.garbage_bin
    self.carriable      = true
    self.name           = "Garbage Bin"
    self.is_garbage_bin = true
    return self
end

return GarbageBin
