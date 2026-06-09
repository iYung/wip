math.randomseed(42)
local runner     = require("lua/headless/runner")
local StoreScene = require("lua/game/scenes/store_scene")

local function make_scene()
    local ctx = runner.setup(function(gs, input, sm)
        return StoreScene.new(gs, input, sm)
    end)
    local scene = ctx.sm.current
    ctx.input._map = { pick_up_down = {"e"}, interact = {"f"} }
    ctx.input.key_for = function(self, action)
        local keys = self._map[action]
        return keys and keys[1]
    end
    ctx.gs.player.x = -100  -- cashier zone
    return ctx, scene
end

local function stub_customer(name, state)
    return {
        name  = name,
        state = state,
        active          = function(self) return self.state ~= "idle" end,
        arrived         = function(self) return self.state == "waiting" end,
        line_complete   = function(self) return true end,
        on_last_message = function(self) return false end,
    }
end

-- hovering named customer while waiting → "HOVERING <NAME>"
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Sir Moneyton", "waiting")
    local hud = scene:_hud_labels()
    assert(hud.slot == "HOVERING SIR MONEYTON",
        "expected 'HOVERING SIR MONEYTON', got " .. tostring(hud.slot))
    print("PASS: cashier hover: named customer waiting shows HOVERING <name>")
end

-- hovering generic customer while waiting → "HOVERING CUSTOMER"
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Customer", "waiting")
    local hud = scene:_hud_labels()
    assert(hud.slot == "HOVERING CUSTOMER",
        "expected 'HOVERING CUSTOMER', got " .. tostring(hud.slot))
    print("PASS: cashier hover: generic customer waiting shows HOVERING CUSTOMER")
end

-- hovering named customer in talking_after → "HOVERING <NAME>"
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Mayor Bloom", "talking_after")
    local hud = scene:_hud_labels()
    assert(hud.slot == "HOVERING MAYOR BLOOM",
        "expected 'HOVERING MAYOR BLOOM', got " .. tostring(hud.slot))
    print("PASS: cashier hover: named customer talking_after shows HOVERING <name>")
end

-- customer walking_in → no slot label
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Romeo", "walking_in")
    local hud = scene:_hud_labels()
    assert(hud.slot == nil or hud.slot == false,
        "expected no slot label while walking_in, got " .. tostring(hud.slot))
    print("PASS: cashier hover: no slot label while customer walking_in")
end

-- customer walking_out → no slot label
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Romeo", "walking_out")
    local hud = scene:_hud_labels()
    assert(hud.slot == nil or hud.slot == false,
        "expected no slot label while walking_out, got " .. tostring(hud.slot))
    print("PASS: cashier hover: no slot label while customer walking_out")
end

-- no customer present → no slot label
do
    local ctx, scene = make_scene()
    scene._customer = nil
    local hud = scene:_hud_labels()
    assert(hud.slot == nil or hud.slot == false,
        "expected no slot label with no customer, got " .. tostring(hud.slot))
    print("PASS: cashier hover: no slot label when no customer present")
end

-- idle customer → no slot label
do
    local ctx, scene = make_scene()
    scene._customer = stub_customer("Customer", "idle")
    local hud = scene:_hud_labels()
    assert(hud.slot == nil or hud.slot == false,
        "expected no slot label when customer is idle, got " .. tostring(hud.slot))
    print("PASS: cashier hover: no slot label when customer idle")
end

print("ALL TESTS PASSED")
