local Store  = require("lua/game/store")
local Player = require("lua/game/player")
local U      = require("lua/game/config").U

local SLOT_WIDTH    = 10 * U  -- 200
local INITIAL_SLOTS = 7

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self    = setmetatable({}, GameState)
    self.store    = Store.new(INITIAL_SLOTS, SLOT_WIDTH)
    self.player   = Player.new(SLOT_WIDTH / 2)
    self.currency        = 20
    self.speed_level     = 0
    self.unlocked_plants = { [1] = true }
    self.stage3_counts   = {}
    self.seen_scripts    = {}
    return self
end

return GameState
