math.randomseed(42)
local runner    = require("lua/headless/runner")
local WaterDrone = require("lua/game/water_drone")

-- E1: New drone starts in "idle" state
do
    local store_stub = { slots = {} }
    local drone = WaterDrone.new(store_stub, 0)
    assert(drone.state == "idle",
        "E1: drone.state should be 'idle', got " .. tostring(drone.state))
    assert(drone.x == 0,
        "E1: drone.x should be 0, got " .. tostring(drone.x))
    assert(drone.target_slot == nil,
        "E1: drone.target_slot should be nil, got " .. tostring(drone.target_slot))
    print("PASS: water_drone: E1 new drone starts in idle state")
end

-- E2: Drone transitions to "flying_to" when a plant is ready
do
    local store_stub = { slots = { { x = 200, item = { plant_type = 1, ready = true } } } }
    local drone = WaterDrone.new(store_stub, 0)
    drone:update(0)
    assert(drone.state == "flying_to",
        "E2: drone.state should be 'flying_to', got " .. tostring(drone.state))
    assert(drone.target_slot == store_stub.slots[1],
        "E2: drone.target_slot should be slots[1], got " .. tostring(drone.target_slot))
    print("PASS: water_drone: E2 drone transitions to flying_to when plant is ready")
end

-- E3: Drone calls water() and transitions to idle
do
    local item = {
        plant_type = 1,
        ready      = true,
        water      = function(self) self.ready = false; return true end,
    }
    local store_stub = { slots = { { x = 200, item = item } } }
    local drone = WaterDrone.new(store_stub, 0)
    drone.state        = "watering"
    drone.target_slot  = store_stub.slots[1]
    drone._water_timer = 0
    drone:update(1 / 60)
    assert(drone.state == "idle",
        "E3: drone.state should be 'idle' after watering, got " .. tostring(drone.state))
    assert(drone.target_slot == nil,
        "E3: drone.target_slot should be nil after watering, got " .. tostring(drone.target_slot))
    assert(store_stub.slots[1].item.ready == false,
        "E3: item.ready should be false after water() was called")
    print("PASS: water_drone: E3 drone calls water() and returns to idle")
end

-- E4: Drone stays at current x after watering (no return-to-home)
do
    local item = {
        plant_type = 1,
        ready      = true,
        water      = function(self) self.ready = false; return true end,
    }
    local store_stub = { slots = { { x = 200, item = item } } }
    local drone = WaterDrone.new(store_stub, 0)
    drone.x            = 500
    drone.state        = "watering"
    drone.target_slot  = store_stub.slots[1]
    drone._water_timer = 0
    drone:update(1 / 60)
    assert(drone.x == 500,
        "E4: drone.x should remain 500 after watering, got " .. tostring(drone.x))
    print("PASS: water_drone: E4 drone stays at current x after watering")
end

print("ALL TESTS PASSED")
