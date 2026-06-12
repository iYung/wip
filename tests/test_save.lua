local Save      = require("lua/core/save")
local GameState = require("lua/game/game_state")

-- Stub love.filesystem with an in-memory store so tests don't touch disk.
local _fs = {}
love.filesystem.write   = function(path, content) _fs[path] = content end
love.filesystem.read    = function(path) return _fs[path], _fs[path] and #_fs[path] or 0 end
love.filesystem.getInfo = function(path) return _fs[path] and { type="file" } or nil end

local function reset_fs() _fs = {} end

-- Test 1: exists() returns false when no file
reset_fs()
assert(Save.exists() == false, "exists() should be false with no save file")
print("PASS: save: exists() false with no file")

-- Test 2: write() + exists() returns true
reset_fs()
Save.write({ x = 1 })
assert(Save.exists() == true, "exists() should be true after write()")
print("PASS: save: exists() true after write()")

-- Test 3: read() returns nil with no file
reset_fs()
assert(Save.read() == nil, "read() should return nil with no file")
print("PASS: save: read() nil with no file")

-- Test 4: read() returns nil on corrupt data
reset_fs()
love.filesystem.write("save.dat", "NOT VALID LUA }{{{")
assert(Save.read() == nil, "read() should return nil on corrupt data")
print("PASS: save: read() nil on corrupt data")

-- Test 5: round-trip preserves scalar fields
reset_fs()
local data_in = {
    version=1, currency=750, speed_level=2, growth_level=1,
    cooldown_level=3, growth_mult=1.6,
    unlocked_plants={[1]=true,[2]=true},
    stage3_counts={[1]=5,[3]=2},
    seen_scripts={["sage:1"]=true},
    player={ x=420.5, facing="left", held_item=nil },
    slots={ {item=nil},{item=nil},{item=nil} },
}
Save.write(data_in)
local data_out = Save.read()
assert(data_out ~= nil, "read() should return table after write()")
assert(data_out.currency       == 750,   "currency round-trip")
assert(data_out.speed_level    == 2,     "speed_level round-trip")
assert(data_out.growth_level   == 1,     "growth_level round-trip")
assert(data_out.cooldown_level == 3,     "cooldown_level round-trip")
assert(data_out.growth_mult    == 1.6,   "growth_mult round-trip")
assert(data_out.unlocked_plants[1] == true, "unlocked_plants[1] round-trip")
assert(data_out.unlocked_plants[2] == true, "unlocked_plants[2] round-trip")
assert(data_out.stage3_counts[1]   == 5,    "stage3_counts[1] round-trip")
assert(data_out.seen_scripts["sage:1"] == true, "seen_scripts round-trip")
assert(data_out.player.x       == 420.5, "player.x round-trip")
assert(data_out.player.facing  == "left","player.facing round-trip")
print("PASS: save: scalar fields round-trip")

-- Test 6: round-trip preserves plant item in slot
reset_fs()
local data_plant = {
    version=1, currency=0, speed_level=0, growth_level=0,
    cooldown_level=0, growth_mult=1.0,
    unlocked_plants={[1]=true}, stage3_counts={}, seen_scripts={},
    player={ x=0, facing="right", held_item=nil },
    slots={
        { item={ type="plant", plant_type=3, stage=2 } },
        { item={ type="watering_can" } },
        { item={ type="pc_store" } },
        { item=nil },
    },
}
Save.write(data_plant)
local out = Save.read()
assert(out.slots[1].item.type        == "plant",     "slot 1 type round-trip")
assert(out.slots[1].item.plant_type  == 3,           "slot 1 plant_type round-trip")
assert(out.slots[1].item.stage       == 2,           "slot 1 stage round-trip")
assert(out.slots[2].item.type        == "watering_can", "slot 2 type round-trip")
assert(out.slots[3].item.type        == "pc_store",  "slot 3 type round-trip")
assert(out.slots[4].item             == nil,         "slot 4 nil round-trip")
print("PASS: save: item slots round-trip")

-- Test 7: round-trip preserves held_item
reset_fs()
local data_held = {
    version=1, currency=0, speed_level=0, growth_level=0,
    cooldown_level=0, growth_mult=1.0,
    unlocked_plants={[1]=true}, stage3_counts={}, seen_scripts={},
    player={ x=0, facing="right", held_item={ type="grafter" } },
    slots={ {item=nil} },
}
Save.write(data_held)
local out2 = Save.read()
assert(out2.player.held_item ~= nil,                "held_item not nil after round-trip")
assert(out2.player.held_item.type == "grafter",     "held_item type round-trip")
print("PASS: save: held_item round-trip")

-- Test 8: GameState.to_save / from_save round-trip restores currency and levels
reset_fs()
local gs = GameState.new()
gs.currency       = 1234
gs.speed_level    = 1
gs.growth_level   = 2
gs.cooldown_level = 1
gs.growth_mult    = 1.25
gs.unlocked_plants[2] = true
gs.stage3_counts[1]   = 7
gs.seen_scripts["sage:1"] = true

local saved = GameState.to_save(gs)
Save.write(saved)
local loaded_data = Save.read()
local gs2 = GameState.from_save(loaded_data)

assert(gs2.currency       == 1234,  "from_save: currency")
assert(gs2.speed_level    == 1,     "from_save: speed_level")
assert(gs2.growth_level   == 2,     "from_save: growth_level")
assert(gs2.cooldown_level == 1,     "from_save: cooldown_level")
assert(gs2.growth_mult    == 1.25,  "from_save: growth_mult")
assert(gs2.unlocked_plants[2] == true,      "from_save: unlocked_plants")
assert(gs2.stage3_counts[1]   == 7,         "from_save: stage3_counts")
assert(gs2.seen_scripts["sage:1"] == true,  "from_save: seen_scripts")
print("PASS: save: GameState round-trip restores scalars")

-- Test 9: from_save restores plant in slot with correct type and stage
reset_fs()
local Plant = require("lua/game/items/plant")
local gs3 = GameState.new()
gs3.store.slots[1].item = Plant.new(2)
gs3.store.slots[1].item.stage = 3
gs3.store.slots[1].item.sprite:set("3")

local saved3 = GameState.to_save(gs3)
Save.write(saved3)
local gs4 = GameState.from_save(Save.read())

local item = gs4.store.slots[1].item
assert(item ~= nil,           "from_save: plant in slot 1 exists")
assert(item.plant_type == 2,  "from_save: plant_type restored")
assert(item.stage      == 3,  "from_save: plant stage restored")
assert(item.ready      == false, "from_save: plant ready=false (cooldown restarted)")
print("PASS: save: plant restored from save with correct type/stage")

-- Test 10: from_save restores player position and facing
reset_fs()
local gs5 = GameState.new()
gs5.player.x      = 999.5
gs5.player.facing = "left"

local saved5 = GameState.to_save(gs5)
Save.write(saved5)
local gs6 = GameState.from_save(Save.read())

assert(gs6.player.x      == 999.5, "from_save: player.x restored")
assert(gs6.player.facing == "left","from_save: player.facing restored")
print("PASS: save: player position and facing restored")

-- Test 11: from_save restores slot count
reset_fs()
local gs7 = GameState.new()
gs7.store:grow()
gs7.store:grow()
assert(#gs7.store.slots == 7, "setup: 7 slots")

local saved7 = GameState.to_save(gs7)
Save.write(saved7)
local gs8 = GameState.from_save(Save.read())
assert(#gs8.store.slots == 7, "from_save: slot count restored, got " .. #gs8.store.slots)
print("PASS: save: slot count restored")

-- Test 12: from_save applies speed tier to player when speed_level > 0
reset_fs()
local SPEED_TIERS = require("lua/game/data/speed_tiers")
local gs_sp = GameState.new()
gs_sp.speed_level = 2
gs_sp.player.speed = SPEED_TIERS[2].speed
Save.write(GameState.to_save(gs_sp))
local gs_sp2 = GameState.from_save(Save.read())
assert(gs_sp2.player.speed == SPEED_TIERS[2].speed,
    "from_save: player speed should match speed_level 2, got " .. tostring(gs_sp2.player.speed))
print("PASS: save: from_save applies speed tier to player")

-- Test 13: from_save keeps base speed when speed_level == 0
reset_fs()
local gs_base = GameState.new()
Save.write(GameState.to_save(gs_base))
local gs_base2 = GameState.from_save(Save.read())
assert(gs_base2.player.speed == 220,
    "from_save: player speed should be 220 at speed_level 0, got " .. tostring(gs_base2.player.speed))
print("PASS: save: from_save keeps base speed when speed_level is 0")

-- Test 14: from_save restores secondary speed color when speed_level > 0
reset_fs()
local gs_col = GameState.new()
gs_col.speed_level = 1
Save.write(GameState.to_save(gs_col))
local gs_col2 = GameState.from_save(Save.read())
local sec = gs_col2.player._speed_secondary
assert(sec ~= nil, "from_save: _speed_secondary should not be nil at speed_level 1")
local expected = SPEED_TIERS[1].secondary
assert(sec[1] == expected[1] and sec[2] == expected[2] and sec[3] == expected[3],
    "from_save: _speed_secondary should match tier secondary color")
print("PASS: save: from_save restores secondary speed color")

print("ALL TESTS PASSED")
