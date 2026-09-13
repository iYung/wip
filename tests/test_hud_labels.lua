math.randomseed(42)
local runner      = require("lua/headless/runner")
local StoreScene  = require("lua/game/scenes/store_scene")
local WateringCan = require("lua/game/items/watering_can")
local Grafter     = require("lua/game/items/grafter")
local Plant       = require("lua/game/items/plant")
local GoldenIdol  = require("lua/game/items/golden_idol")

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
    assert(hud.f.text == ": WATER",
        "gamepad: f text should be ': WATER', got " .. tostring(hud.f and hud.f.text))
    print("PASS: hud: gamepad mode returns {icon, text} for button labels")
end

-- ADMIRE: hint shown when hovering Golden Idol without holding anything
do
    local ctx, scene = make_scene()
    local idol = GoldenIdol.new()
    idol.win_scene_factory = function() end
    ctx.gs.store.slots[4].item = idol
    ctx.gs.player.x = 700  -- slot 4
    ctx.gs.player.held_item = nil

    local hud = scene:_hud_labels()
    assert(hud.f == "P: ADMIRE",
        "ADMIRE hint should show when hovering Golden Idol, got: " .. tostring(hud.f))
    print("PASS: hud: ADMIRE hint shown when hovering Golden Idol")
end

-- ADMIRE: hint hidden when holding the Golden Idol
do
    local ctx, scene = make_scene()
    local idol = GoldenIdol.new()
    idol.win_scene_factory = function() end
    ctx.gs.player.held_item = idol
    ctx.gs.player.x = 700  -- slot 4, empty

    local hud = scene:_hud_labels()
    assert(hud.f == nil,
        "ADMIRE hint should be hidden when holding Golden Idol, got: " .. tostring(hud.f))
    print("PASS: hud: ADMIRE hint hidden when holding Golden Idol")
end

-- PICK UP: empty-handed near carriable item shows PICK UP, no f-label
do
    local ctx, scene = make_scene()
    -- slot 1 has WateringCan by default; player stands at x=100 (slot 1)
    ctx.gs.player.x = 100
    ctx.gs.player.held_item = nil

    local hud = scene:_hud_labels()
    assert(hud.up == "W: PICK UP",
        "PICK UP hint should show when empty-handed near carriable item, got: " .. tostring(hud.up))
    assert(hud.f == nil,
        "f hint should be nil when empty-handed near WateringCan (no interact target), got: " .. tostring(hud.f))
    print("PASS: hud: PICK UP shown and f-label absent when empty-handed near WateringCan")
end

-- SWAP: holding something near a different carriable item shows SWAP in up-label
do
    local ctx, scene = make_scene()
    local plant = Plant.new(1)
    plant.ready = true
    ctx.gs.store.slots[4].item = plant
    ctx.gs.player.x = 700  -- slot 4 (Grass)

    local wc = ctx.gs.store.slots[1].item
    ctx.gs.player.held_item = wc
    ctx.gs.store.slots[1].item = nil

    local hud = scene:_hud_labels()
    assert(hud.up == "W: SWAP WITH WATERING CAN",
        "SWAP hint should show when holding item near another carriable item, got: " .. tostring(hud.up))
    print("PASS: hud: SWAP hint shown when holding WateringCan near carriable plant")
end

-- SELL + DISMISS: cashier zone, customer arrived on last message, stage-3 matching plant held
do
    local ctx, scene = make_scene()
    ctx.gs.player.x = -50   -- cashier zone (x < 0)

    local plant = Plant.new(1)   -- Grass, sell = 3
    plant.stage = 3
    ctx.gs.player.held_item = plant

    local customer = scene._customer
    customer.state        = "waiting"   -- arrived()
    customer.done_talking = true        -- on_last_message()
    customer.plant_type   = 1

    local hud = scene:_hud_labels()
    assert(hud.up == "I: DISMISS",
        "DISMISS hint should show in cashier zone when customer arrived, got: " .. tostring(hud.up))
    assert(hud.f == "P: SELL TO CUSTOMER ($3)",
        "SELL hint should show when holding matching stage-3 plant, got: " .. tostring(hud.f))
    print("PASS: hud: SELL and DISMISS hints shown in cashier zone with matching plant")
end

print("ALL TESTS PASSED")
