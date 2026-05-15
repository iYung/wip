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

local Player = {}
Player.__index = Player

local function make_sprite_set(idle_img, walk_img, idle_held_img, walk_held_img)
    local idle      = Sprite.new(0, 0, W, H); idle.image      = idle_img
    local walk      = Sprite.new(0, 0, W, H); walk.image      = walk_img
    local idle_held = Sprite.new(0, 0, W, H); idle_held.image = idle_held_img
    local walk_held = Sprite.new(0, 0, W, H); walk_held.image = walk_held_img
    local ss = SpriteSet.new()
    ss:add("idle",      idle)
    ss:add("walk",      walk)
    ss:add("idle_held", idle_held)
    ss:add("walk_held", walk_held)
    ss:set("idle")
    return ss
end

function Player.new(x)
    local self       = setmetatable({}, Player)
    self.x           = x or 0
    self.y           = INIT_Y
    self.held_item   = nil
    self.speed       = BASE_SPEED

    self.sprite_sets = {}
    self.sprite_sets[0] = make_sprite_set(
        A.player_idle, A.player_walk, A.player_idle_held, A.player_walk_held)
    for lvl = 1, 3 do
        local p = "player_spd" .. lvl .. "_"
        self.sprite_sets[lvl] = make_sprite_set(
            A[p .. "idle"]      or A.player_idle,
            A[p .. "walk"]      or A.player_walk,
            A[p .. "idle_held"] or A.player_idle_held,
            A[p .. "walk_held"] or A.player_walk_held)
    end

    self._anim_timer = Timer.new(0.15)
    self._anim_frame = "idle"
    self.facing      = "right"

    self:set_speed_level(0)

    return self
end

function Player:set_speed_level(level)
    self.sprite = self.sprite_sets[level]
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
    self.sprite:draw()
    if self.held_item then
        self.held_item:draw()
        if self.held_item.draw_bubble then
            self.held_item:draw_bubble()
        end
    end
end

return Player
