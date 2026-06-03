extern Image pattern_tex;
extern vec2 pattern_size;
extern vec2 tile_size;
extern vec2 scroll;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_pos) {
    vec4 bg = Texel(tex, uv);
    if (bg.r > 0.9 && bg.g < 0.1 && bg.b < 0.1 && bg.a > 0.0) {
        vec2 world_pos = uv * tile_size + scroll;
        vec2 pat_uv = fract(world_pos / pattern_size);
        return Texel(pattern_tex, pat_uv) * color;
    }
    return bg * color;
}
