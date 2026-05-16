local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/color_replace.glsl")

local _no_color = {0, 0, 0, 0}

return {
    apply = function(primary, secondary)
        shader:send("replace_color_a", primary)
        shader:send("replace_color_b", secondary or _no_color)
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
