vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_pos) {
    // barrel distortion
    vec2 c = uv * 2.0 - 1.0;
    vec2 offset = c.yx * c.yx * 0.008;
    c += c * offset;
    c = c * 0.5 + 0.5;

    if (c.x < 0.0 || c.x > 1.0 || c.y < 0.0 || c.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // chromatic aberration
    float ab = 0.00025;
    float r = Texel(tex, c + vec2(ab,  0.0)).r;
    float g = Texel(tex, c).g;
    float b = Texel(tex, c - vec2(ab,  0.0)).b;
    vec4 pixel = vec4(r, g, b, Texel(tex, c).a);

    // scanlines
    float line = sin(c.y * 720.0 * 3.14159265);
    pixel.rgb *= mix(0.93, 1.0, clamp(line * line, 0.0, 1.0));

    // vignette
    vec2 v = c * (1.0 - c.yx);
    pixel.rgb *= clamp(pow(v.x * v.y * 16.0, 0.08), 0.0, 1.0);

    return pixel * color;
}
