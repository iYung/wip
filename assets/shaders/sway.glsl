extern float time;
extern float amplitude;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_pos) {
    vec2 shifted_uv = vec2(uv.x + sin(time * 0.6) * amplitude * (1.0 - uv.y), uv.y);
    return Texel(tex, shifted_uv) * color;
}
