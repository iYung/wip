local Sprite     = require("lua/core/sprite")
local SpriteSet  = require("lua/core/spriteset")
local PLANT_DATA = require("lua/game/data/plant_data")
local A          = require("lua/game/assets")
local U          = require("lua/game/config").U

local CW    = 6 * U   -- 120
local CH    = 12 * U  -- 240
local BW    = 6 * U   -- bubble width  120  (matches plant sprite size)
local BH    = 6 * U   -- bubble height 120
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

    local idle = Sprite.new(0, 0, CW, CH)
    idle.image = A.customer
    idle.color = {0.85, 0.55, 0.30, 1}

    local walk = Sprite.new(0, 0, CW, CH)
    walk.image = A.customer_walk
    walk.color = {0.85, 0.55, 0.30, 1}

    self.sprite = SpriteSet.new()
    self.sprite:add("idle", idle)
    self.sprite:add("walk", walk)
    self.sprite:set("idle")
    self.sprite.visible = true

    self._anim_timer = 0
    self._anim_frame = "idle"

    self.bubble         = Sprite.new(0, 0, BW, BH)
    self.bubble.image   = A.customer_bubble
    self.bubble.visible = false

    self.heart_bubble         = Sprite.new(0, 0, BW, BH)
    self.heart_bubble.image   = A.heart_bubble
    self.heart_bubble.color   = {1, 1, 1, 1}
    self.heart_bubble.visible = false

    self.name            = "Customer"
    self.messages        = {}
    self.msg_index       = 1
    self.done_talking    = false
    self.accessory_sprite = nil

    return self
end

local DEFAULT_COLOR = {0.85, 0.55, 0.30, 1}

function Customer:show(cfg)
    self.plant_type    = cfg.plant_type or 1
    self.name          = cfg.name or "Customer"
    self.messages      = cfg.messages or {}
    self.msg_index     = 1
    self.done_talking  = #self.messages == 0
    self.x             = self.exit_x
    self.state         = "walking_in"
    self.sprite.visible = true
    self.bubble.color  = PLANT_DATA[self.plant_type].colors[3]
    self.bubble.visible = false
    self.heart_bubble.visible = false
    local color = cfg.body_color or DEFAULT_COLOR
    self.sprite.sprites.idle.color = color
    self.sprite.sprites.walk.color = color
    if cfg.accessory then
        local img = A.load_accessory(cfg.accessory)
        if img then
            self.accessory_sprite       = Sprite.new(0, 0, CW, CW)
            self.accessory_sprite.image = img
        else
            self.accessory_sprite = nil
        end
    else
        self.accessory_sprite = nil
    end
end

function Customer:advance()
    if self.done_talking then return end
    if self.msg_index < #self.messages then
        self.msg_index = self.msg_index + 1
    else
        self.done_talking = true
    end
end

function Customer:on_last_message()
    return self.done_talking
end

function Customer:serve()
    self.state              = "walking_out"
    self.bubble.visible     = false
    self.heart_bubble.visible = true
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
            self.heart_bubble.visible = false
        end
    end

    local moving = self.state == "walking_in" or self.state == "walking_out"
    if moving then
        self._anim_timer = self._anim_timer + dt
        if self._anim_timer >= 0.15 then
            self._anim_timer = 0
            self._anim_frame = (self._anim_frame == "idle") and "walk" or "idle"
            self.sprite:set(self._anim_frame)
        end
    else
        self._anim_frame = "idle"
        self.sprite:set("idle")
    end

    self.sprite.scale_x = (self.state == "walking_out") and -1 or 1
    self.sprite.x = self.x - CW / 2
    self.sprite.y = self.y - CH / 2 - 20
    self.bubble.x = self.x - BW / 2
    self.bubble.y = self.sprite.y - BH - 4
    self.heart_bubble.x = self.x - BW / 2
    self.heart_bubble.y = self.sprite.y - BH - 4
    if self.accessory_sprite then
        self.accessory_sprite.x       = self.sprite.x
        self.accessory_sprite.y       = self.sprite.y
        self.accessory_sprite.scale_x = self.sprite.scale_x
        self.accessory_sprite.visible = self.sprite.visible
    end
end

function Customer:draw()
    if self.state == "idle" then return end
    self.sprite:draw()
    if self.accessory_sprite then self.accessory_sprite:draw() end
end

function Customer:draw_bubble()
    if self.heart_bubble.visible then
        self.heart_bubble:draw()
    end
    if not self.bubble.visible then return end
    if self.done_talking then
        self.bubble:draw()
    else
        love.graphics.setColor(1, 1, 1, 0.9)
        local line = self.messages[self.msg_index] or ""
        local text = self.name .. ": " .. line
        local tw   = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, self.bubble.x + BW / 2 - tw / 2, self.bubble.y)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Customer
