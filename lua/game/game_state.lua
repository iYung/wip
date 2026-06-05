local Store  = require("lua/game/store")
local Player = require("lua/game/player")
local U      = require("lua/game/config").U

local Plant      = require("lua/game/items/plant")
local WateringCan = require("lua/game/items/watering_can")
local Grafter    = require("lua/game/items/grafter")
local GarbageBin = require("lua/game/items/garbage_bin")
local PCStore    = require("lua/game/items/pc_store")
local Intercom   = require("lua/game/items/intercom")

local SLOT_WIDTH    = 10 * U  -- 200
local INITIAL_SLOTS = 5

local function _item_to_data(item)
    if item == nil then return nil end
    if item.plant_type then
        return { type = "plant", plant_type = item.plant_type, stage = item.stage }
    elseif item.name == "Watering Can" then
        return { type = "watering_can" }
    elseif item.name == "Grafter" then
        return { type = "grafter" }
    elseif item.name == "Garbage Bin" then
        return { type = "garbage_bin" }
    elseif item.name == "PC Store" then
        return { type = "pc_store" }
    elseif item.name == "Intercom" then
        return { type = "intercom" }
    else
        return nil
    end
end

local function _item_from_data(d)
    if d == nil then return nil end
    if d.type == "plant" then
        local p = Plant.new(d.plant_type)
        p.stage = d.stage
        p.sprite:set(tostring(d.stage))
        p.ready = false
        return p
    elseif d.type == "watering_can" then
        return WateringCan.new()
    elseif d.type == "grafter" then
        return Grafter.new()
    elseif d.type == "garbage_bin" then
        return GarbageBin.new()
    elseif d.type == "pc_store" then
        return PCStore.new(nil)
    elseif d.type == "intercom" then
        return Intercom.new(nil)
    else
        return nil
    end
end

local GameState = {}
GameState.__index = GameState

function GameState.new()
    local self    = setmetatable({}, GameState)
    self.store    = Store.new(INITIAL_SLOTS, SLOT_WIDTH)
    self.player   = Player.new(SLOT_WIDTH / 2)
    self.currency        = 1000
    self.speed_level     = 0
    self.growth_level    = 0
    self.cooldown_level  = 0
    self.growth_mult     = 1.0
    self.unlocked_plants = { [1] = true }
    self.stage3_counts   = {}
    self.seen_scripts    = {}
    self.has_drone       = false
    return self
end

function GameState.to_save(gs)
    local slots = {}
    for i, slot in ipairs(gs.store.slots) do
        slots[i] = { item = _item_to_data(slot.item) }
    end
    return {
        version          = 1,
        currency         = gs.currency,
        speed_level      = gs.speed_level,
        growth_level     = gs.growth_level,
        cooldown_level   = gs.cooldown_level,
        growth_mult      = gs.growth_mult,
        unlocked_plants  = gs.unlocked_plants,
        stage3_counts    = gs.stage3_counts,
        seen_scripts     = gs.seen_scripts,
        has_drone        = gs.has_drone,
        player = {
            x         = gs.player.x,
            facing    = gs.player.facing,
            held_item = _item_to_data(gs.player.held_item),
        },
        slots = slots,
    }
end

function GameState.from_save(data)
    local self = setmetatable({}, GameState)
    self.currency       = data.currency
    self.speed_level    = data.speed_level
    self.growth_level   = data.growth_level
    self.cooldown_level = data.cooldown_level
    self.growth_mult    = data.growth_mult

    self.unlocked_plants = {}
    for k, v in pairs(data.unlocked_plants) do self.unlocked_plants[k] = v end

    self.stage3_counts = {}
    for k, v in pairs(data.stage3_counts) do self.stage3_counts[k] = v end

    self.seen_scripts = {}
    for k, v in pairs(data.seen_scripts) do self.seen_scripts[k] = v end

    self.has_drone = data.has_drone or false

    self.store = Store.new(#data.slots, SLOT_WIDTH)
    for i, slot_data in ipairs(data.slots) do
        self.store.slots[i].item = _item_from_data(slot_data.item)
    end

    self.player = Player.new(data.player.x)
    self.player.facing    = data.player.facing
    self.player.held_item = _item_from_data(data.player.held_item)

    return self
end

return GameState
