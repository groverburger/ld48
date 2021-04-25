vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    if (texturecolor.a == 0.0) { discard; }
    return vec4(1.0, 1.0, 1.0, texturecolor.a);
}
