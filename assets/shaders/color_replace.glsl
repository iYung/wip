extern vec4 replace_color_a;
extern vec4 replace_color_b;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc);
    if (pixel.r > 0.9 && pixel.g < 0.1 && pixel.b < 0.1 && pixel.a > 0.0) {
        return vec4(replace_color_a.rgb, pixel.a) * color;
    }
    if (pixel.b > 0.9 && pixel.r < 0.1 && pixel.g < 0.1 && pixel.a > 0.0) {
        return vec4(replace_color_b.rgb, pixel.a) * color;
    }
    return pixel * color;
}
