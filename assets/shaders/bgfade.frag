uniform vec4 bgcolor;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    if (texturecolor.a == 0.0) { discard; }

    texturecolor *= color;

    number r = mix(bgcolor.r, texturecolor.r, bgcolor.a);
    number g = mix(bgcolor.g, texturecolor.g, bgcolor.a);
    number b = mix(bgcolor.b, texturecolor.b, bgcolor.a);
    return vec4(r,g,b, texturecolor.a);
}
