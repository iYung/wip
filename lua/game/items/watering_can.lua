local Item   = require("lua/game/items/item")
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U
local Sound  = require("lua/game/sound")

local WateringCan = setmetatable({}, { __index = Item })
WateringCan.__index = WateringCan

function WateringCan.new()
    local self        = Item.new()
    setmetatable(self, WateringCan)
    self.sprite       = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image = A.watering_can
    self.carriable    = true
    self.name         = "Watering Can"
    return self
end

function WateringCan:interact(player, store, scene_manager)
    local slot = player:active_slot(store)
    if slot and slot.item and slot.item.water then
        if slot.item:water() then
            Sound.play("water_plant")
        end
    end
end

return WateringCan
