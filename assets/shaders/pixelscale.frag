// size of the texture
uniform int width;
uniform int height;
uniform number uvmod;

varying vec4 screenPosition;

number d(vec4 a, vec4 b) {
    return abs(a.x-b.x) + abs(a.y-b.y) + abs(a.z-b.z) + abs(a.a-b.a);
}

vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
    vec4 texcolor = Texel(tex, texcoord);
    vec2 pos = vec2(texcoord.x*width, texcoord.y*height);
    vec2 frac = vec2(mod(pos.x, 1), mod(pos.y, 1));
    vec2 subfrac = vec2(mod(pos.x, 0.5), mod(pos.y, 0.5));
    vec2 b = vec2(floor(texcoord.x/uvmod)*uvmod, floor(texcoord.y/uvmod)*uvmod);

    vec4 A = Texel(tex, vec2(mod((pos.x - 1)/width, uvmod) + b.x, mod((pos.y - 1)/height, uvmod) + b.y));
    vec4 B = Texel(tex, vec2(mod((pos.x    )/width, uvmod) + b.x, mod((pos.y - 1)/height, uvmod) + b.y));
    vec4 C = Texel(tex, vec2(mod((pos.x + 1)/width, uvmod) + b.x, mod((pos.y - 1)/height, uvmod) + b.y));
    vec4 D = Texel(tex, vec2(mod((pos.x - 1)/width, uvmod) + b.x, mod((pos.y    )/height, uvmod) + b.y));
    vec4 E = Texel(tex, vec2(mod((pos.x    )/width, uvmod) + b.x, mod((pos.y    )/height, uvmod) + b.y));
    vec4 F = Texel(tex, vec2(mod((pos.x + 1)/width, uvmod) + b.x, mod((pos.y    )/height, uvmod) + b.y));
    vec4 G = Texel(tex, vec2(mod((pos.x - 1)/width, uvmod) + b.x, mod((pos.y + 1)/height, uvmod) + b.y));
    vec4 H = Texel(tex, vec2(mod((pos.x    )/width, uvmod) + b.x, mod((pos.y + 1)/height, uvmod) + b.y));
    vec4 I = Texel(tex, vec2(mod((pos.x + 1)/width, uvmod) + b.x, mod((pos.y + 1)/height, uvmod) + b.y));

    if (d(F,H) < d(E,I)) {
        if (frac.x > 0.5 && frac.y > 0.5 && subfrac.x + subfrac.y >= 0.5) {
            //texcolor = (F+H)/2.0;
            texcolor = F;
        }
    }

    if (d(D,H) < d(E,G)) {
        if (frac.x <= 0.5 && frac.y > 0.5 && 0.5-subfrac.x + subfrac.y >= 0.5) {
            //texcolor = (D+H)/2.0;
            texcolor = D;
        }
    }

    if (d(F,B) < d(E,C)) {
        if (frac.x > 0.5 && frac.y <= 0.5 && subfrac.x + 0.5-subfrac.y >= 0.5) {
            //texcolor = (F+B)/2.0;
            texcolor = B;
        }
    }

    if (d(D,B) < d(E,A)) {
        if (frac.x <= 0.5 && frac.y <= 0.5 && 0.5-subfrac.x + 0.5-subfrac.y >= 0.5) {
            //texcolor = (D+B)/2.0;
            texcolor = B;
        }
    }

    if (texcolor.a == 0.0) { discard; }

    //number c = screenPosition.z/5;
    //return vec4(c,c,c,1) * VaryingColor;
    //return vec4(screenPosition.x, screenPosition.y, 1, 1) * VaryingColor;

    return texcolor * VaryingColor;
}
