#version 440
// Frosted-glass dressing for a bar bubble, drawn over the (blurred, tinted) bubble:
//  - glass: top sheen + thin bright rim
//  - frost: soft icy glow along the inner edge
//  - snow globe: soft white dots swirling around inside
// Everything is clipped to the bubble's pill shape.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;     // seconds
    float radius;   // pill corner radius in px
    float count;    // number of flakes (<= 32)
    float seed;     // per-bubble variation
    float frost;    // 0..1 frost/glass strength
    vec2 size;      // px
};

float hash(float n) {
    return fract(sin(n * 127.1 + seed * 311.7) * 43758.5453);
}

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 px = qt_TexCoord0 * size;
    vec2 uv = qt_TexCoord0;

    float sd = sdRoundBox(px - size * 0.5, size * 0.5, min(radius, min(size.x, size.y) * 0.5));
    float inside = 1.0 - smoothstep(-1.0, 0.5, sd);
    float depth = -sd; // px from the edge, inwards

    // ---- glass ----
    float sheen = 0.28 * (1.0 - smoothstep(0.0, 0.45, uv.y)) * smoothstep(0.0, 3.0, depth);
    float rim = (1.0 - smoothstep(0.0, 1.8, depth)) * (0.65 + 0.35 * (1.0 - uv.y));

    // ---- frost: a soft, even icy glow along the inner edge ----
    float edgeFrost = (1.0 - smoothstep(0.0, 6.0, depth)) * 0.35;

    float glass = clamp((sheen + edgeFrost + rim) * frost, 0.0, 1.0);

    // ---- snow globe flakes ----
    float a = 0.0;
    for (int i = 0; i < 32; ++i) {
        if (float(i) >= count)
            break;
        float f = float(i);
        float h1 = hash(f), h2 = hash(f + 0.13), h3 = hash(f + 0.29), h4 = hash(f + 0.47);

        float dir = h4 > 0.5 ? 1.0 : -1.0;
        float ang = time * (0.35 + 0.6 * h3) * dir + h1 * 6.2831;
        float orbit = size.y * (0.18 + 0.3 * h2);
        vec2 drift = vec2((h2 - 0.5) * 16.0, (h3 - 0.5) * 10.0) * time;
        vec2 pad = vec2(8.0);
        vec2 p = vec2(h1, h3) * size + drift + orbit * vec2(cos(ang), 0.7 * sin(ang * 1.3));
        p = mod(p + pad, size + 2.0 * pad) - pad;

        float r = 1.0 + 1.5 * h4;
        float d = length(px - p);
        a += (1.0 - smoothstep(r * 0.3, r, d)) * (0.6 + 0.4 * h2);
    }
    a = clamp(a, 0.0, 1.0);

    // glass bevel: a cool darker band along the lower inner edge (refraction), so the
    // bubble keeps its shape even over light wallpapers
    float shade = (1.0 - smoothstep(0.0, 4.0, depth)) * smoothstep(0.35, 1.0, uv.y) * 0.45 * frost;

    float w = clamp(max(a, glass), 0.0, 1.0) * inside;
    float k = shade * (1.0 - w) * inside;
    vec3 dark = vec3(0.16, 0.24, 0.34);
    fragColor = vec4(vec3(w) + dark * k, w + k) * qt_Opacity;
}
