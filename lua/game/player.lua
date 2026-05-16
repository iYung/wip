local SpriteSet = require("lua/core/spriteset")
local Sprite    = require("lua/core/sprite")
local Timer     = require("lua/core/timer")
local CONFIG     = require("lua/game/config")
local A          = require("lua/game/assets")
local U          = CONFIG.U
local ZONE_WIDTH = CONFIG.ZONE_WIDTH

local BASE_SPEED = 220
local W          = 6 * U   -- 120
local H          = 12 * U  -- 240
local INIT_Y     = 31 * U + 5  -- 625  player center y in world

local _color_shader = love.graphics.newShader([[
    extern vec4 replace_color;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec4 pixel = Texel(tex, tc);
        if (pixel.r > 0.9 && pixel.g < 0.1 && pixel.b < 0.1 && pixel.a > 0.0) {
            return vec4(replace_color.rgb, pixel.a) * color;
        }
        return pixel * color;
    }
]])

local Player = {}
Player.__index = Player

function Player.new(x)
    local self       = setmetatable({}, Player)
    self.x           = x or 0
    self.y           = INIT_Y
    self.held_item   = nil
    self.speed       = BASE_SPEED
    self._speed_color = nil

    local idle      = Sprite.new(0, 0, W, H); idle.image      = A.player_idle
    local walk      = Sprite.new(0, 0, W, H); walk.image      = A.player_walk
    local idle_held = Sprite.new(0, 0, W, H); idle_held.image = A.player_idle_held
    local walk_held = Sprite.new(0, 0, W, H); walk_held.image = A.player_walk_held

    self.sprite = SpriteSet.new()
    self.sprite:add("idle",      idle)
    self.sprite:add("walk",      walk)
    self.sprite:add("idle_held", idle_held)
    self.sprite:add("walk_held", walk_held)
    self.sprite:set("idle")

    self._anim_timer = Timer.new(0.15)
    self._anim_frame = "idle"
    self.facing      = "right"

    return self
end

function Player:set_speed_level(level, color)
    self._speed_color = color
end

function Player:update(dt, input, store)
    local moving = false
    if input:is_down("move_left") then
        self.x      = self.x - self.speed * dt
        self.facing = "left"
        moving      = true
    end
    if input:is_down("move_right") then
        self.x      = self.x + self.speed * dt
        self.facing = "right"
        moving      = true
    end

    if store then
        self.x = math.max(-ZONE_WIDTH + W / 2, math.min(store:width() - W / 2, self.x))
    end

    local idle_key = self.held_item and "idle_held" or "idle"
    local walk_key = self.held_item and "walk_held" or "walk"

    if moving then
        if self._anim_timer:update(dt) then
            self._anim_frame = (self._anim_frame == idle_key) and walk_key or idle_key
            self.sprite:set(self._anim_frame)
        end
    else
        self._anim_frame = idle_key
        self.sprite:set(idle_key)
    end

    self.sprite.x       = self.x - W / 2
    self.sprite.y       = self.y - H / 2
    self.sprite.scale_x = self.facing == "left" and -1 or 1

    if self.held_item then
        local spr = self.held_item.sprite
        if spr then
            spr.x = self.x - spr.width  / 2
            spr.y = self.y - H / 2 - spr.height
        end
    end
end

function Player:active_slot(store)
    return store:slot_at(self.x)
end

function Player:draw()
    if self._speed_color then
        _color_shader:send("replace_color", self._speed_color)
        love.graphics.setShader(_color_shader)
    end
    self.sprite:draw()
    if self._speed_color then
        love.graphics.setShader()
    end
    if self.held_item then
        self.held_item:draw()
        if self.held_item.draw_bubble then
            self.held_item:draw_bubble()
        end
    end
end

return Player
