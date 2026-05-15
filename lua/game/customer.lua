local Sprite       = require("lua/core/sprite")
local SpriteSet    = require("lua/core/spriteset")
local Timer        = require("lua/core/timer")
local PLANT_DATA   = require("lua/game/data/plant_data")
local A            = require("lua/game/assets")
local U            = require("lua/game/config").U
local ColorReplace = require("lua/game/shaders/color_replace")

local CW    = 6 * U   -- 120
local CH    = 12 * U  -- 240
local BW    = 6 * U   -- bubble width  120  (matches plant sprite size)
local BH    = 6 * U   -- bubble height 120
local SPEED = 80

local REVEAL_SPEED  = 40
local PAD           = 14
local MIN_BOX_W     = 120
local TAIL_H        = 24
local BUBBLE_MARGIN = { top = 12, right = 12, bottom = 12, left = 12 }

local function draw9(img, x, y, w, h, m)
    local iw, ih = img:getDimensions()
    local function q(qx, qy, qw, qh) return love.graphics.newQuad(qx, qy, qw, qh, iw, ih) end
    local cx = iw - m.left - m.right
    local cy = ih - m.top  - m.bottom
    local dx = w  - m.left - m.right
    local dy = h  - m.top  - m.bottom
    local sx = dx / cx
    local sy = dy / cy
    love.graphics.draw(img, q(0,           0,           m.left,  m.top),    x,            y)
    love.graphics.draw(img, q(iw-m.right,  0,           m.right, m.top),    x+w-m.right,  y)
    love.graphics.draw(img, q(0,           ih-m.bottom, m.left,  m.bottom), x,            y+h-m.bottom)
    love.graphics.draw(img, q(iw-m.right,  ih-m.bottom, m.right, m.bottom), x+w-m.right,  y+h-m.bottom)
    love.graphics.draw(img, q(m.left, 0,           cx, m.top),    x+m.left, y,             0, sx, 1)
    love.graphics.draw(img, q(m.left, ih-m.bottom, cx, m.bottom), x+m.left, y+h-m.bottom,  0, sx, 1)
    love.graphics.draw(img, q(0,          m.top, m.left,  cy), x,            y+m.top, 0, 1, sy)
    love.graphics.draw(img, q(iw-m.right, m.top, m.right, cy), x+w-m.right, y+m.top, 0, 1, sy)
    love.graphics.draw(img, q(m.left, m.top, cx, cy), x+m.left, y+m.top, 0, sx, sy)
end

local function make_full_text(c)
    return c.name .. ": " .. (c.messages[c.msg_index] or "")
end

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

    local walk = Sprite.new(0, 0, CW, CH)
    walk.image = A.customer_walk

    self.sprite = SpriteSet.new()
    self.sprite:add("idle", idle)
    self.sprite:add("walk", walk)
    self.sprite:set("idle")
    self.sprite.visible = true

    self._primary    = {0.85, 0.55, 0.30, 1}
    self._secondary  = {0.40, 0.30, 0.20, 1}

    self._anim_timer = Timer.new(0.15)
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
    self.dismissed       = false
    self.accessory_sprite = nil
    self.reveal_index    = 0
    self.reveal_t        = 0
    self._full_text      = ""

    return self
end

local DEFAULT_PRIMARY   = {0.85, 0.55, 0.30, 1}
local DEFAULT_SECONDARY = {0.40, 0.30, 0.20, 1}

function Customer:show(cfg)
    self.plant_type    = cfg.plant_type or 1
    self.name          = cfg.name or "Customer"
    self.messages      = cfg.messages or {}
    self.msg_index     = 1
    self.done_talking  = #self.messages == 0
    self.dismissed     = false
    self._full_text    = make_full_text(self)
    self.reveal_index  = 0
    self.reveal_t      = 0
    self.x             = self.exit_x
    self.state         = "walking_in"
    self.sprite.visible = true
    self.bubble.visible = false
    self.heart_bubble.visible = false
    self._primary   = cfg.primary_color   or DEFAULT_PRIMARY
    self._secondary = cfg.secondary_color or DEFAULT_SECONDARY
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
    if not self.done_talking then
        self._full_text   = make_full_text(self)
        self.reveal_index = 0
        self.reveal_t     = 0
    end
end

function Customer:line_complete()
    return self.done_talking or self.reveal_index >= #self._full_text
end

function Customer:skip_reveal()
    self.reveal_index = #self._full_text
    self.reveal_t     = #self._full_text / REVEAL_SPEED
end

function Customer:on_last_message()
    return self.done_talking
end

function Customer:serve()
    self.state              = "walking_out"
    self.bubble.visible     = false
    self.heart_bubble.visible = true
end

function Customer:dismiss()
    self.state              = "walking_out"
    self.bubble.visible     = false
    self.heart_bubble.visible = false
    self.dismissed          = true
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
            self.x                 = self.exit_x
            self.state             = "idle"
            self.sprite.visible    = false
            self.bubble.visible    = false
            self.heart_bubble.visible = false
        end
    end

    if self.bubble.visible and not self.done_talking then
        self.reveal_t     = self.reveal_t + dt
        self.reveal_index = math.min(
            #self._full_text,
            math.floor(self.reveal_t * REVEAL_SPEED)
        )
    end

    local moving = self.state == "walking_in" or self.state == "walking_out"
    if moving then
        if self._anim_timer:update(dt) then
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
    ColorReplace.apply(self._primary, self._secondary)
    self.sprite:draw()
    if self.accessory_sprite then self.accessory_sprite:draw() end
    ColorReplace.clear()
end

function Customer:draw_bubble()
    if self.heart_bubble.visible then
        self.heart_bubble:draw()
    end
    if not self.bubble.visible then return end
    if self.done_talking then
        local PD       = 12
        local IMG_SIZE = 80
        local BOX_W    = IMG_SIZE + PD * 2
        local BOX_H    = IMG_SIZE + PD * 2

        local box_x = self.x - BOX_W / 2
        local box_y = self.sprite.y - BOX_H - TAIL_H - 4

        love.graphics.setColor(1, 1, 1, 1)
        draw9(A.speech_bubble, box_x, box_y, BOX_W, BOX_H, BUBBLE_MARGIN)

        local tw = A.speech_bubble_tail:getWidth()
        love.graphics.draw(
            A.speech_bubble_tail,
            box_x + BOX_W / 2 - tw / 2,
            box_y + BOX_H - 10
        )

        local img    = A["plant_" .. self.plant_type][3]
        local iw, ih = img:getDimensions()
        love.graphics.draw(img, box_x + PD, box_y + PD, 0, IMG_SIZE / iw, IMG_SIZE / ih)

        love.graphics.setColor(1, 1, 1, 1)
    else
        local font     = love.graphics.getFont()
        local revealed = string.sub(self._full_text, 1, self.reveal_index)
        local text_w   = font:getWidth(self._full_text)
        local text_h   = font:getHeight()
        local box_w    = math.max(MIN_BOX_W, text_w + PAD * 2)
        local box_h    = text_h + PAD * 2
        local box_x    = self.bubble.x + BW / 2 - box_w / 2
        local box_y    = self.bubble.y - box_h - TAIL_H + 4

        love.graphics.setColor(1, 1, 1, 1)
        draw9(A.speech_bubble, box_x, box_y, box_w, box_h, BUBBLE_MARGIN)
        local tw = A.speech_bubble_tail:getWidth()
        love.graphics.draw(A.speech_bubble_tail, box_x + box_w / 2 - tw / 2, box_y + box_h - 10)
        love.graphics.setColor(0.08, 0.07, 0.10, 0.95)
        love.graphics.print(revealed, box_x + PAD, box_y + BUBBLE_MARGIN.top / 2 + PAD / 2)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Customer
