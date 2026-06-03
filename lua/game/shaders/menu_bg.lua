local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/menu_bg.glsl")

return {
    apply = function(pattern_img, bg_img, scroll_x, scroll_y)
        shader:send("pattern_tex",  pattern_img)
        shader:send("pattern_size", {pattern_img:getDimensions()})
        shader:send("tile_size",    {bg_img:getDimensions()})
        shader:send("scroll",       {scroll_x, scroll_y})
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
