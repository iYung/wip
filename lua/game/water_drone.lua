local Sprite = require("lua/core/sprite")
local Sound  = require("lua/game/sound")
local A      = require("lua/game/assets")

local WaterDrone = {}
WaterDrone.__index = WaterDrone

local drone_y     = 180
local DRONE_W     = 120

function WaterDrone.new(store, start_x, game_state)
    local self         = setmetatable({}, WaterDrone)
    self.state         = "idle"
    self.x             = start_x or 0
    self.y             = drone_y
    self.drone_y       = drone_y
    self.target_slot   = nil
    self.target_x      = nil
    self.speed         = 300
    self._water_timer  = 0
    self._store_ref    = store
    self._game_state   = game_state
    self._frame_timer  = 0
    self._frame        = 1
    self.sprite        = Sprite.new(0, 0, 120, 120)
    self.sprite.image  = A.water_drone
    self.sprite.scale_x = 1
    return self
end

local FRAMES     = { A.water_drone, A.water_drone2 }
local FRAME_RATE = 0.05

function WaterDrone:update(dt)
    self._frame_timer = self._frame_timer + dt
    if self._frame_timer >= FRAME_RATE then
        self._frame_timer = self._frame_timer - FRAME_RATE
        self._frame = (self._frame % 2) + 1
        self.sprite.image = FRAMES[self._frame]
    end
    if self.state == "idle" then
        for _, slot in ipairs(self._store_ref.slots) do
            if slot.item ~= nil and slot.item.plant_type ~= nil and slot.item.ready == true then
                self.target_slot = slot
                self.target_x = slot.x + self._store_ref.slot_width / 2 - DRONE_W / 2
                self.state = "flying_to"
                self.sprite.scale_x = (self.target_x < self.x) and -1 or 1
                break
            end
        end
    elseif self.state == "flying_to" then
        local diff = self.target_x - self.x
        local step = self.speed * dt
        if math.abs(diff) <= step then
            self.x = self.target_x
        else
            self.x = self.x + (diff > 0 and step or -step)
        end
        if math.abs(self.x - self.target_x) <= 4 then
            self.x = self.target_x
            self._water_timer = 0.5
            self.state = "watering"
        end
    elseif self.state == "watering" then
        self._water_timer = self._water_timer - dt
        if self._water_timer <= 0 then
            local item = self.target_slot.item
            local ok = item ~= nil and item:water()
            if ok then
                Sound.play("water_plant")
                if self._game_state and item.stage == 3 then
                    local gs = self._game_state
                    local pt = item.plant_type
                    gs.stage3_counts[pt] = (gs.stage3_counts[pt] or 0) + 1
                end
            end
            self.target_slot = nil
            self.state = "idle"
        end
    end
end

function WaterDrone:draw()
    self.sprite.x = self.x
    self.sprite.y = self.y
    self.sprite:draw()
end

return WaterDrone
