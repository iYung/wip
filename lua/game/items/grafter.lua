local Item       = require("lua/game/items/item")
local Plant      = require("lua/game/items/plant")
local Sprite     = require("lua/core/sprite")
local PLANT_DATA = require("lua/game/data/plant_data")
local A          = require("lua/game/assets")
local U          = require("lua/game/config").U

local Grafter = setmetatable({}, { __index = Item })
Grafter.__index = Grafter

local COLOR_EMPTY  = {1.0, 0.5, 0.0, 1}
local COLOR_LOADED = {1.0, 0.9, 0.0, 1}

function Grafter.new()
    local self        = Item.new()
    setmetatable(self, Grafter)
    self.carriable    = true
    self.loaded_plant = nil
    self.name         = "Grafter"
    self.sprite       = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image = A.grafter_empty
    return self
end

function Grafter:interact(player, store, scene_manager)
    if player.held_item ~= self then return end
    if self.loaded_plant then return end

    local slot = player:active_slot(store)
    if not slot or not slot.item or not slot.item.plant_type then return end
    if slot.item.stage < 3 then return end

    local plant          = slot.item
    plant.stage          = 1
    plant.cooldown       = PLANT_DATA[plant.plant_type].cooldowns[1]
    plant.ready          = false
    plant.bubble.visible = false
    plant.sprite:set("1")

    self.loaded_plant    = Plant.new(plant.plant_type)
    self.sprite.image    = A.grafter_loaded
end

function Grafter:unload()
    self.loaded_plant = nil
    self.sprite.image = A.grafter_empty
end

function Grafter:draw()
    self.sprite:draw()
    if self.loaded_plant then
        self.loaded_plant.sprite.x = self.sprite.x
        self.loaded_plant.sprite.y = self.sprite.y - self.sprite.height
        self.loaded_plant:draw()
    end
end

return Grafter
