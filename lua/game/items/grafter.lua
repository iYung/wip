local Item       = require("lua/game/items/item")
local Plant      = require("lua/game/items/plant")
local Sprite     = require("lua/core/sprite")
local PLANT_DATA = require("lua/game/data/plant_data")
local A          = require("lua/game/assets")
local U          = require("lua/game/config").U
local Sound      = require("lua/core/sound")

local Grafter = setmetatable({}, { __index = Item })
Grafter.__index = Grafter


function Grafter.new()
    local self           = Item.new()
    setmetatable(self, Grafter)
    self.carriable       = true
    self.name            = "Grafter"
    self.sprite          = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image    = A.grafter_empty

    self.bubble          = Sprite.new(0, 0, 6 * U, 6 * U)
    self.bubble.image    = A.grafter_no_space_bubble
    self.bubble.visible  = false
    self._bubble_timer   = 0

    return self
end

function Grafter:update(dt)
    if self._bubble_timer > 0 then
        self._bubble_timer = self._bubble_timer - dt
        if self._bubble_timer <= 0 then
            self._bubble_timer  = 0
            self.bubble.visible = false
        end
    end
end

function Grafter:interact(player, store, scene_manager)
    if player.held_item ~= self then return end

    local slot = player:active_slot(store)
    if not slot or not slot.item or not slot.item.plant_type then return end
    if slot.item.stage < 3 then return end

    local plant        = slot.item
    local player_index = slot.index

    -- Find nearest empty slot; ties go to lower index
    local best_slot = nil
    local best_dist = math.huge
    for _, s in ipairs(store.slots) do
        if s.item == nil then
            local dist = math.abs(s.index - player_index)
            if dist < best_dist or (dist == best_dist and s.index < best_slot.index) then
                best_slot = s
                best_dist = dist
            end
        end
    end

    if best_slot then
        -- Reset source plant to stage 1
        plant.stage          = 1
        plant._cooldown:reset(PLANT_DATA[plant.plant_type].cooldowns[1])
        plant.ready          = false
        plant.bubble.visible = false
        plant.sprite:set("1")

        -- Spawn clone into nearest empty slot
        best_slot.item = Plant.new(plant.plant_type)
        Sound.play("clone_success")
    else
        -- No empty slot — show bubble
        self.bubble.visible = true
        self._bubble_timer  = 1.5
        Sound.play("fail")
    end
end

function Grafter:draw_bubble()
    if not self.bubble.visible then return end
    self.bubble.x = self.sprite.x + self.sprite.width / 2 - self.bubble.width / 2
    self.bubble.y = self.sprite.y - self.bubble.height - 10
    self.bubble:draw()
end

function Grafter:draw()
    self.sprite:draw()
end

return Grafter
