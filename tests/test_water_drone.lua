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
    local store_stub = { slot_width = 120, slots = { { x = 200, item = { plant_type = 1, ready = true } } } }
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

-- E5: Drone increments stage3_counts when it waters a plant to stage 3
do
    local item = {
        plant_type = 2,
        stage      = 2,
        ready      = true,
        water      = function(self)
            if not self.ready or self.stage >= 3 then return false end
            self.stage = self.stage + 1
            self.ready = false
            return true
        end,
    }
    local store_stub = { slots = { { x = 200, item = item } } }
    local gs_stub    = { stage3_counts = {} }
    local drone = WaterDrone.new(store_stub, 0, gs_stub)
    drone.state        = "watering"
    drone.target_slot  = store_stub.slots[1]
    drone._water_timer = 0
    drone:update(1 / 60)
    assert(gs_stub.stage3_counts[2] == 1,
        "E5: stage3_counts[2] should be 1 after drone waters plant to stage 3, got " .. tostring(gs_stub.stage3_counts[2]))
    print("PASS: water_drone: E5 drone increments stage3_counts when watering plant to stage 3")
end

-- E6: Drone does NOT increment stage3_counts when watering to stage 2
do
    local item = {
        plant_type = 1,
        stage      = 1,
        ready      = true,
        water      = function(self)
            if not self.ready or self.stage >= 3 then return false end
            self.stage = self.stage + 1
            self.ready = false
            return true
        end,
    }
    local store_stub = { slots = { { x = 200, item = item } } }
    local gs_stub    = { stage3_counts = {} }
    local drone = WaterDrone.new(store_stub, 0, gs_stub)
    drone.state        = "watering"
    drone.target_slot  = store_stub.slots[1]
    drone._water_timer = 0
    drone:update(1 / 60)
    assert(gs_stub.stage3_counts[1] == nil,
        "E6: stage3_counts[1] should remain nil when watering plant only to stage 2, got " .. tostring(gs_stub.stage3_counts[1]))
    print("PASS: water_drone: E6 drone does not increment stage3_counts for stage 1→2 water")
end

print("ALL TESTS PASSED")
