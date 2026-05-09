local Item   = require("lua/game/item")
local Sprite = require("lua/core/sprite")

local PCStore = setmetatable({}, { __index = Item })
PCStore.__index = PCStore

function PCStore.new(buy_scene_factory)
    local self             = Item.new()
    setmetatable(self, PCStore)
    self.sprite            = Sprite.new(0, 0, 60, 50)
    self.sprite.color      = {0.7, 0.75, 0.9, 1}
    self.carriable         = true
    self.buy_scene_factory = buy_scene_factory
    return self
end

-- only interactable when placed in a slot and player has empty hands
function PCStore:interact(player, store, scene_manager)
    if player.held_item then return end
    if scene_manager and self.buy_scene_factory then
        scene_manager:switch(self.buy_scene_factory())
    end
end

return PCStore
