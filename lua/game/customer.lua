local Sprite     = require("lua/core/sprite")
local PLANT_DATA = require("lua/game/data/plant_data")
local U          = require("lua/game/config").U

local CW    = 6 * U   -- 120
local CH    = 12 * U  -- 240
local BW    = 3 * U   -- bubble width  60
local BH    = 3 * U   -- bubble height 60
local SPEED = 80

local Customer = {}
Customer.__index = Customer

function Customer.new(target_x, exit_x, y)
    local self        = setmetatable({}, Customer)
    self.state        = "idle"
    self.plant_type   = 1
    self.x            = exit_x
    self.y            = y
    self.target_x     = target_x
    self.exit_x       = exit_x

    self.sprite         = Sprite.new(0, 0, CW, CH)
    self.sprite.color   = {0.85, 0.55, 0.30, 1}
    self.sprite.visible = false

    self.bubble         = Sprite.new(0, 0, BW, BH)
    self.bubble.visible = false

    return self
end

function Customer:show(plant_type)
    self.plant_type       = plant_type or 1
    self.x                = self.exit_x
    self.state            = "walking_in"
    self.sprite.visible   = true
    self.bubble.color     = PLANT_DATA[self.plant_type].colors[3]
    self.bubble.visible   = false
end

function Customer:serve()
    self.state          = "walking_out"
    self.bubble.visible = false
end

function Customer:arrived()
    return self.state == "waiting"
end

function Customer:active()
    return self.state ~= "idle"
end

function Customer:update(dt)
    if self.state == "walking_in" then
        self.x = self.x + SPEED * dt
        if self.x >= self.target_x then
            self.x              = self.target_x
            self.state          = "waiting"
            self.bubble.visible = true
        end
    elseif self.state == "walking_out" then
        self.x = self.x - SPEED * dt
        if self.x <= self.exit_x then
            self.x              = self.exit_x
            self.state          = "idle"
            self.sprite.visible = false
            self.bubble.visible = false
        end
    end

    self.sprite.x = self.x - CW / 2
    self.sprite.y = self.y - CH / 2
    self.bubble.x = self.x - BW / 2
    self.bubble.y = self.sprite.y - BH - 4
end

function Customer:draw()
    if self.state == "idle" then return end
    self.sprite:draw()
    if self.bubble.visible then
        self.bubble:draw()
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(PLANT_DATA[self.plant_type].name, self.bubble.x, self.bubble.y - 16)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Customer
