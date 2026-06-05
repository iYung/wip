local Item   = require("lua/game/items/item")
local Sprite = require("lua/core/sprite")
local A      = require("lua/game/assets")
local U      = require("lua/game/config").U

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

local Intercom = setmetatable({}, { __index = Item })
Intercom.__index = Intercom

function Intercom.new(customer_getter)
    local self              = Item.new()
    setmetatable(self, Intercom)
    self.sprite             = Sprite.new(0, 0, 6 * U, 6 * U)
    self.sprite.image       = A.intercom
    self.carriable          = true
    self.name               = "Intercom"
    self._customer_getter   = customer_getter
    return self
end

function Intercom:set_customer_getter(fn)
    self._customer_getter = fn
end

function Intercom:draw_bubble()
    if self._customer_getter == nil then return end
    local customer = self._customer_getter()
    if customer == nil then return end
    if not (customer.bubble.visible == true
            and customer.done_talking == true
            and customer.state ~= "talking_after") then
        return
    end

    local PD       = 12
    local IMG_SIZE = 80
    local BOX_W    = IMG_SIZE + PD * 2
    local BOX_H    = IMG_SIZE + PD * 2

    local sprite_cx = self.sprite.x + self.sprite.width / 2
    local box_x     = sprite_cx - BOX_W / 2
    local box_y     = self.sprite.y - BOX_H - TAIL_H - 4

    love.graphics.setColor(1, 1, 1, 1)
    draw9(A.speech_bubble, box_x, box_y, BOX_W, BOX_H, BUBBLE_MARGIN)

    local tw = A.speech_bubble_tail:getWidth()
    love.graphics.draw(
        A.speech_bubble_tail,
        box_x + BOX_W / 2 - tw / 2,
        box_y + BOX_H - 10
    )

    local img    = A["plant_" .. customer.plant_type][3]
    local iw, ih = img:getDimensions()
    love.graphics.draw(img, box_x + PD, box_y + PD, 0, IMG_SIZE / iw, IMG_SIZE / ih)

    love.graphics.setColor(1, 1, 1, 1)
end

return Intercom
