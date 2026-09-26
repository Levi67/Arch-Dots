// Digital Vibrance Shader for Hyprland / Hyprshade
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// ADJUST VIBRANCE HERE (1.0 = normal, 1.5 = moderate boost, 2.0 = heavy boost)
const float Vibrance = 0.75; // Recommended starting point for CS2

void main() {
    vec4 c = texture2D(tex, v_texcoord);
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float sat = maxC - minC;

    vec3 lumaWeight = vec3(0.299, 0.587, 0.114);
    float luma = dot(c.rgb, lumaWeight);

    vec3 color = mix(vec3(luma), c.rgb, 1.0 + (Vibrance * (1.0 - (sign(Vibrance) * sat))));
    gl_FragColor = vec4(color, c.a);
}