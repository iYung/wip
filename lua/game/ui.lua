local A = require("lua/game/assets")

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

local PAD         = 14
local line_height = 20

local function draw_hud_box(labels, font, margin)
    if #labels == 0 then return end
    margin = margin or 10

    local content_w = 0
    for _, label in ipairs(labels) do
        local lw = font:getWidth(label)
        if lw > content_w then content_w = lw end
    end

    local content_h = #labels * line_height
    local box_w     = content_w + PAD * 2
    local box_h     = content_h + PAD * 2
    local box_x     = margin
    local box_y     = 720 - margin - box_h

    love.graphics.setColor(1, 1, 1, 1)
    draw9(A.speech_bubble, box_x, box_y, box_w, box_h, { top = 12, right = 12, bottom = 12, left = 12 })
end

local COIN_SIZE = 32

local function draw_currency_bubble(currency, x, y, font)
    local coin_h    = COIN_SIZE
    local coin_w    = A.coin:getWidth() * (coin_h / A.coin:getHeight())
    local num_str   = tostring(currency)
    local num_w     = font:getWidth(num_str)
    local content_w = coin_w + 4 + num_w
    local content_h = math.max(coin_h, font:getHeight())
    local box_w     = content_w + PAD * 2
    local box_h     = content_h + PAD * 2

    love.graphics.setColor(1, 1, 1, 1)
    draw9(A.speech_bubble, x, y, box_w, box_h, { top = 12, right = 12, bottom = 12, left = 12 })

    local coin_y = math.floor(y + PAD + (content_h - coin_h) / 2)
    love.graphics.draw(A.coin, x + PAD, coin_y, 0, coin_h / A.coin:getHeight(), coin_h / A.coin:getHeight())

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    local text_y = math.floor(y + PAD + (content_h - font:getHeight()) / 2)
    love.graphics.print(num_str, x + PAD + coin_w + 4, text_y)
    love.graphics.setColor(1, 1, 1, 1)
end

return { draw9 = draw9, draw_hud_box = draw_hud_box, draw_currency_bubble = draw_currency_bubble }
