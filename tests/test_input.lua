local Input = require("lua/core/input")

-- key_for returns the first key for a known action
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("pick_up_down") == "g",
        "key_for('pick_up_down') should return 'g', got " .. tostring(input:key_for("pick_up_down")))
    print("PASS: input: key_for returns first key for pick_up_down")
end

-- key_for returns the first key for interact
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("interact") == "h",
        "key_for('interact') should return 'h', got " .. tostring(input:key_for("interact")))
    print("PASS: input: key_for returns first key for interact")
end

-- key_for returns nil for an unknown action
do
    local input = Input.new({ pick_up_down = {"g"}, interact = {"h"} })
    assert(input:key_for("unknown") == nil,
        "key_for('unknown') should return nil, got " .. tostring(input:key_for("unknown")))
    print("PASS: input: key_for returns nil for unknown action")
end

print("ALL TESTS PASSED")
