local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/sway.glsl")

return {
    apply = function(time, amplitude)
        shader:send("time",      time)
        shader:send("amplitude", amplitude)
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
