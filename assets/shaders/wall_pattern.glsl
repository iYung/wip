extern Image pattern_tex;
extern vec2 world_origin;
extern vec2 tile_size;
extern vec2 pattern_size;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_pos) {
    vec4 wall = Texel(tex, uv);
    if (wall.r > 0.9 && wall.g < 0.1 && wall.b < 0.1 && wall.a > 0.0) {
        vec2 world_pos = world_origin + uv * tile_size;
        vec2 pat_uv = fract(world_pos / pattern_size);
        return Texel(pattern_tex, pat_uv) * color;
    }
    return wall * color;
}
