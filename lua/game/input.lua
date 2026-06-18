local Input = require("lua/core/input")

return Input.new({
    move_up      = {"w"},
    move_down    = {"s"},
    move_left    = {"a"},
    move_right   = {"d"},
    interact     = {"space"},
    pick_up      = {"o"},
    put_down     = {"p"},
})
