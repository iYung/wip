local Item   = require("lua/game/items/item")
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U

local GoldenIdol = setmetatable({}, { __index = Item })
GoldenIdol.__index = GoldenIdol

function GoldenIdol.new()
    local self              = Item.new()
    setmetatable(self, GoldenIdol)
    self.sprite             = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image       = A.golden_idol
    self.carriable          = true
    self.name               = "Golden Idol"
    self.win_scene_factory  = nil
    return self
end

function GoldenIdol:interact(player, store, scene_manager)
    if self.win_scene_factory then
        scene_manager:switch(self.win_scene_factory())
    end
end

return GoldenIdol
