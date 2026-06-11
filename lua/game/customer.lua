local Sprite       = require("lua/core/sprite")
local SpriteSet    = require("lua/core/spriteset")
local Timer        = require("lua/core/timer")
local PLANT_DATA   = require("lua/game/data/plant_data")
local A            = require("lua/game/assets")
local U            = require("lua/game/config").U
local ColorReplace = require("lua/game/shaders/color_replace")
local Sound        = require("lua/game/sound")
local UI           = require("lua/game/ui")

local CW    = 6 * U   -- 120
local CH    = 12 * U  -- 240
local BW    = 6 * U   -- bubble width  120  (matches plant sprite size)
local BH    = 6 * U   -- bubble height 120
local REVEAL_SPEED  = 40
local PAD           = 14
local MIN_BOX_W     = 120
local MAX_BOX_W     = 18 * U  -- 360
local TAIL_H        = 24
local BUBBLE_MARGIN = { top = 12, right = 12, bottom = 12, left = 12 }

local function make_full_text(c)
    return c.messages[c.msg_index] or ""
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
    self.after_messages  = {}
    self.after_msg_index = 1
    self.done_after      = true
    self.accessory_sprite = nil
    self.reveal_index    = 0
    self.reveal_t        = 0
    self._full_text      = ""

    return self
end

local DEFAULT_PRIMARY   = {0.85, 0.55, 0.30, 1}
local DEFAULT_SECONDARY = {0.40, 0.30, 0.20, 1}

function Customer:show(cfg)
    self.plant_type      = cfg.plant_type or 1
    self.name            = cfg.name or "Customer"
    self.messages        = cfg.messages or {}
    self.msg_index       = 1
    self.done_talking    = #self.messages == 0
    self.dismissed       = false
    self.after_messages  = cfg.after_messages or {}
    self.after_msg_index = 1
    self.done_after      = #(cfg.after_messages or {}) == 0
    self._full_text      = make_full_text(self)
    self.reveal_index    = 0
    self.reveal_t        = 0
    self.x               = self.exit_x
    self.state           = "walking_in"
    self.sprite.visible  = true
    self.bubble.visible  = false
    self.heart_bubble.visible = false
    self.speed        = cfg.walk_speed or 80
    self._voice_pitch = cfg.voice_pitch or 1.0
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
    if self.state == "talking_after" then
        return self.reveal_index >= #self._full_text
    end
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
    self.bubble.visible = false
    if not self.done_after then
        self.state        = "talking_after"
        self._full_text   = self.after_messages[1]
        self.reveal_index = 0
        self.reveal_t     = 0
        self.bubble.visible = true
    else
        self.state = "walking_out"
        self.heart_bubble.visible = true
    end
end

function Customer:advance_after()
    if self.done_after then return end
    if not self:line_complete() then
        self:skip_reveal()
        return
    end
    if self.after_msg_index < #self.after_messages then
        self.after_msg_index = self.after_msg_index + 1
        self._full_text      = self.after_messages[self.after_msg_index]
        self.reveal_index    = 0
        self.reveal_t        = 0
    else
        self.done_after             = true
        self.state                  = "walking_out"
        self.bubble.visible         = false
        self.heart_bubble.visible   = true
    end
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
        self.x = self.x + self.speed * dt
        if self.x >= self.target_x then
            self.x              = self.target_x
            self.state          = "waiting"
            self.bubble.visible = true
        end
    elseif self.state == "walking_out" then
        self.x = self.x - self.speed * dt
        if self.x <= self.exit_x then
            self.x                 = self.exit_x
            self.state             = "idle"
            self.sprite.visible    = false
            self.bubble.visible    = false
            self.heart_bubble.visible = false
        end
    end

    if self.bubble.visible and (not self.done_talking or self.state == "talking_after") then
        local prev_index  = self.reveal_index
        self.reveal_t     = self.reveal_t + dt
        self.reveal_index = math.min(
            #self._full_text,
            math.floor(self.reveal_t * REVEAL_SPEED)
        )
        if self.reveal_index > prev_index then
            Sound.play_animalese(self._voice_pitch)
        end
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
    self.bubble.y = self.sprite.y - 9
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
    if self.done_talking and self.state ~= "talking_after" then
        local PD       = 12
        local IMG_SIZE = 80
        local BOX_W    = IMG_SIZE + PD * 2
        local BOX_H    = IMG_SIZE + PD * 2

        local box_x = self.x - BOX_W / 2
        local box_y = self.sprite.y - BOX_H - TAIL_H - 4

        love.graphics.setColor(1, 1, 1, 1)
        UI.draw9(A.speech_bubble, box_x, box_y, BOX_W, BOX_H, BUBBLE_MARGIN)

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
        -- reveal_index counts bytes; clamp to a UTF-8 character boundary so
        -- string.sub never returns a string that ends mid-multibyte-sequence.
        -- Continuation bytes are 0x80-0xBF; start bytes are >= 0xC0.
        local idx = self.reveal_index
        while idx > 0 and (string.byte(self._full_text, idx) or 0) >= 0x80
                      and (string.byte(self._full_text, idx) or 0) <  0xC0 do
            idx = idx - 1
        end
        if (string.byte(self._full_text, idx) or 0) >= 0xC0 then
            idx = idx - 1
        end
        local text_h   = font:getHeight()
        local _, lines = font:getWrap(self._full_text, MAX_BOX_W - PAD * 2)
        local widest_line_width = 0
        for _, line in ipairs(lines) do
            local lw = font:getWidth(line)
            if lw > widest_line_width then widest_line_width = lw end
        end
        local box_w = math.min(MAX_BOX_W, math.max(MIN_BOX_W, widest_line_width + PAD * 2))
        local box_h = text_h * #lines + PAD * 2
        local box_x = self.bubble.x + BW / 2 - box_w / 2
        local box_y = self.bubble.y - box_h - TAIL_H + 4

        -- Build rendered_lines by walking the full-text wrap points with a byte
        -- offset, so partial words never cause line-break flicker.
        local rendered_lines = {}
        local remaining = idx
        for _, line in ipairs(lines) do
            if remaining <= 0 then break end
            local visible = math.min(remaining, #line)
            rendered_lines[#rendered_lines + 1] = string.sub(line, 1, visible)
            remaining = remaining - #line - 1
        end
        -- DEBUG: print rendered_lines once when fully revealed
        if idx == #self._full_text and not self._debug_printed then
            self._debug_printed = true
            io.write("DBG lines(" .. #rendered_lines .. "):")
            for di, dl in ipairs(rendered_lines) do
                io.write(" [" .. di .. "]='" .. dl .. "'")
            end
            io.write("  full='" .. self._full_text .. "'\n")
            io.flush()
        end
        if idx < #self._full_text then self._debug_printed = nil end

        love.graphics.setColor(1, 1, 1, 1)
        UI.draw9(A.speech_bubble, box_x, box_y, box_w, box_h, BUBBLE_MARGIN)
        local tw = A.speech_bubble_tail:getWidth()
        love.graphics.draw(A.speech_bubble_tail, box_x + box_w / 2 - tw / 2, box_y + box_h - 10)

        love.graphics.setColor(0.08, 0.07, 0.10, 0.95)
        for i, line in ipairs(rendered_lines) do
            local lx = box_x + PAD
            local ly = box_y + BUBBLE_MARGIN.top / 2 + PAD / 2 + (i - 1) * text_h
            love.graphics.print(line, lx, ly)
            -- Re-draw each period shifted right to widen the ~2 px glyph so it
            -- survives nearest-neighbour canvas downsampling.  Use the full-prefix
            -- width so kerning is accounted for, then print at +1 and +2 to get
            -- ~4 px of ink coverage.
            for j = 1, #line do
                if line:sub(j, j) == "." then
                    local px = font:getWidth(line:sub(1, j - 1))
                    love.graphics.print(".", lx + px + 1, ly)
                    love.graphics.print(".", lx + px + 2, ly)
                end
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Customer
