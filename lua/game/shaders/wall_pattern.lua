local Shader = require("lua/core/shader")

local shader = Shader.load("assets/shaders/wall_pattern.glsl")

return {
    apply = function(pattern_img, world_x, world_y, tile_img)
        shader:send("pattern_tex",  pattern_img)
        shader:send("pattern_size", {pattern_img:getDimensions()})
        shader:send("world_origin", {world_x, world_y})
        shader:send("tile_size",    {tile_img:getDimensions()})
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}
