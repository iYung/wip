math.randomseed(42)
local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local WateringCan = require("lua/game/items/watering_can")
local Grafter     = require("lua/game/items/grafter")
local Plant       = require("lua/game/items/plant")

local function make_scene()
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current
    ctx.input._map = { pick_up_down = {"w"}, interact = {"p"} }
    ctx.input.key_for = function(self, action)
        local keys = self._map[action]
        return keys and keys[1]
    end
    return ctx, scene
end

-- Slot layout: 1=WateringCan(x=100), 2=GarbageBin(x=300), 3=PCStore(x=500)
-- slots 4(x=700) and 5(x=900) are empty by default.

-- WATER: hint hidden when plant not ready
do
    local ctx, scene = make_scene()
    local plant = Plant.new(1)
    plant.ready = false
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4

    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil

    local hud = scene:_hud_labels()
    assert(hud.f == nil,
        "WATER hint should be hidden when plant not ready, got: " .. tostring(hud.f))
    print("PASS: hud: WATER hint hidden when plant not ready")
end

-- WATER: hint shown when plant is ready
do
    local ctx, scene = make_scene()
    local plant = Plant.new(1)
    plant.ready = true
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4

    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil

    local hud = scene:_hud_labels()
    assert(hud.f == "P: WATER",
        "WATER hint should show when plant is ready, got: " .. tostring(hud.f))
    print("PASS: hud: WATER hint shown when plant is ready")
end

-- CLONE: hint shown for stage-3 plant (no loaded_plant check)
do
    local ctx, scene = make_scene()
    local plant = Plant.new(1)
    plant.stage = 3
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4

    local grafter = Grafter.new()
    ctx.gs.player.held_item = grafter

    local hud = scene:_hud_labels()
    assert(hud.f == "P: CLONE",
        "CLONE hint should show for stage-3 plant, got: " .. tostring(hud.f))
    print("PASS: hud: CLONE hint shown for stage-3 plant")
end

-- CLONE: hint hidden for stage-1 plant
do
    local ctx, scene = make_scene()
    local plant = Plant.new(1)
    plant.stage = 1
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4

    local grafter = Grafter.new()
    ctx.gs.player.held_item = grafter

    local hud = scene:_hud_labels()
    assert(hud.f == nil,
        "CLONE hint should be hidden for non-stage-3 plant, got: " .. tostring(hud.f))
    print("PASS: hud: CLONE hint hidden for stage-1 plant")
end

-- Gamepad mode: _hud_labels returns {icon, text} table for button labels
do
    local ctx, scene = make_scene()
    -- add icon_key_for stub simulating gamepad mode
    ctx.input.icon_key_for = function(self, action)
        local icons = { interact = "btn_a", pick_up_down = "btn_y", cancel = "btn_b" }
        return icons[action]
    end

    local plant = Plant.new(1)
    plant.ready = true
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4

    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil

    local hud = scene:_hud_labels()
    assert(type(hud.f) == "table",
        "gamepad: f label should be a table, got " .. tostring(hud.f))
    assert(hud.f.icon == "btn_a",
        "gamepad: f icon should be 'btn_a', got " .. tostring(hud.f and hud.f.icon))
    assert(hud.f.text == "WATER",
        "gamepad: f text should be 'WATER', got " .. tostring(hud.f and hud.f.text))
    print("PASS: hud: gamepad mode returns {icon, text} for button labels")
end

print("ALL TESTS PASSED")
