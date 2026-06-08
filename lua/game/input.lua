local Input = require("lua/core/input")

return Input.new({
    move_up      = {"up", "w"},
    move_down    = {"down", "s"},
    move_left    = {"left", "a"},
    move_right   = {"right", "d"},
    pick_up_down = {"e"},
    interact     = {"f"},
})
