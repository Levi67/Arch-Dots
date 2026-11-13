#version 440
// Procedural snowfall in 3 parallax layers + an optional snow pile along the bottom.
// Everything is computed from `time`, so nothing is stored per flake.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;       // seconds
    float density;    // 1 = normal, >1 heavier
    float speed;      // fall speed multiplier
    float pile;       // 0..1 pile fill
    float pileHeight; // px at full fill
    float seed;       // per-screen variation
    vec2 resolution;  // px
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// one layer of flakes on a grid of `cell` px; every cell may hold one flake.
// returns (core, halo): halo is a faint dark ring so flakes read on light wallpapers too
vec2 flakes(vec2 px, float cell, float fall, float radius, float prob, float salt) {
    vec2 uv = px / cell;
    uv.y -= time * fall * speed / cell;
    uv.x += 0.35 * sin(time * 0.4 + uv.y * 0.9 + salt);  // gentle drift

    vec2 id = floor(uv);
    vec2 f = fract(uv);
    vec2 key = id + vec2(salt, seed);

    float h = hash(key);
    if (h > clamp(prob * density, 0.0, 0.95))
        return vec2(0.0);

    vec2 c = vec2(0.2 + 0.6 * hash(key + 1.7), 0.2 + 0.6 * hash(key + 3.1));
    c.x += 0.12 * sin(time * (0.6 + h) + h * 6.2831);    // wobble

    float r = radius * (0.6 + 0.6 * hash(key + 5.3));
    float d = length((f - c) * cell);
    float a = 1.0 - smoothstep(r * 0.4, r, d);            // soft round dot
    float halo = (1.0 - smoothstep(r, r * 1.9, d)) * (1.0 - a);
    float o = 0.7 + 0.3 * hash(key + 7.9);
    return vec2(a * o, halo * o);
}

void main() {
    vec2 px = qt_TexCoord0 * resolution;

    vec2 s = vec2(0.0);
    s += flakes(px, 30.0, 30.0, 1.9, 0.50, 11.0) * 0.7;   // far
    s += flakes(px, 52.0, 52.0, 3.0, 0.42, 23.0) * 0.85;  // mid
    s += flakes(px, 86.0, 84.0, 4.4, 0.34, 37.0);         // near
    s += flakes(px, 170.0, 130.0, 7.5, 0.16, 53.0);       // big soft foreground flakes
    float core = clamp(s.x, 0.0, 1.0);
    float halo = clamp(s.y, 0.0, 1.0) * 0.22;

    // white core over a faint blue-grey halo (premultiplied)
    vec3 col = vec3(1.0) * core + vec3(0.25, 0.32, 0.42) * halo * (1.0 - core);
    float a = core + halo * (1.0 - core);
    col = a > 0.0 ? col / a : col; // un-premultiply for the pile mix below

    if (pile > 0.001) {
        float x = px.x + seed * 997.0;
        float n = 0.55 + 0.22 * sin(x * 0.0041) + 0.14 * sin(x * 0.0113 + 1.3) + 0.09 * sin(x * 0.029 + 4.1);
        float ground = resolution.y - pileHeight * pile * n;
        float inside = smoothstep(ground - 1.0, ground + 1.0, px.y);
        if (inside > 0.0) {
            // bright crust on top, slightly blue deeper down, a few static sparkles
            float depth = clamp((px.y - ground) / max(pileHeight * pile, 1.0), 0.0, 1.0);
            vec3 snow = mix(vec3(0.98, 0.99, 1.0), vec3(0.78, 0.85, 0.94), smoothstep(0.0, 1.0, depth));
            float sparkle = step(0.997, hash(floor(px / 2.0) + seed));
            snow = mix(snow, vec3(1.0), sparkle * 0.8);
            col = mix(col, snow, inside);
            a = max(a, inside);
        }
    }

    fragColor = vec4(col * a, a) * qt_Opacity;
}
