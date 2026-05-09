local SpriteSet = require("lua/core/spriteset")
local Sprite    = require("lua/core/sprite")
local U         = require("lua/game/config").U

local SPEED    = 220
local W        = 6 * U   -- 120
local H        = 12 * U  -- 240
local INIT_Y   = 31 * U  -- 620  player center y in world

local Player = {}
Player.__index = Player

function Player.new(x)
    local self       = setmetatable({}, Player)
    self.x           = x or 0
    self.y           = INIT_Y
    self.held_item   = nil

    local sa       = Sprite.new(0, 0, W, H)
    sa.color       = {0.30, 0.55, 1.0, 1}
    local sb       = Sprite.new(0, 0, W, H)
    sb.color       = {0.20, 0.45, 0.90, 1}

    self.sprite    = SpriteSet.new()
    self.sprite:add("a", sa)
    self.sprite:add("b", sb)
    self.sprite:set("a")

    self._anim_timer = 0
    self._anim_frame = "a"

    return self
end

function Player:update(dt, input, store)
    local moving = false
    if input:is_down("move_left") then
        self.x  = self.x - SPEED * dt
        moving  = true
    end
    if input:is_down("move_right") then
        self.x  = self.x + SPEED * dt
        moving  = true
    end

    if store then
        self.x = math.max(W / 2, math.min(store:width() - W / 2, self.x))
    end

    if moving then
        self._anim_timer = self._anim_timer + dt
        if self._anim_timer >= 0.15 then
            self._anim_timer = 0
            self._anim_frame = (self._anim_frame == "a") and "b" or "a"
            self.sprite:set(self._anim_frame)
        end
    else
        self._anim_frame = "a"
        self.sprite:set("a")
    end

    self.sprite.x = self.x - W / 2
    self.sprite.y = self.y - H / 2

    if self.held_item then
        local spr = self.held_item.sprite
        if spr then
            local active = spr._active and spr:_active() or spr
            local iw = active and active.width  or 4 * U
            local ih = active and active.height or 4 * U
            spr.x = self.x - iw / 2
            spr.y = self.y - H / 2 - ih
        end
    end
end

function Player:active_slot(store)
    return store:slot_at(self.x)
end

function Player:draw()
    self.sprite:draw()
    if self.held_item then
        self.held_item:draw()
    end
end

return Player
