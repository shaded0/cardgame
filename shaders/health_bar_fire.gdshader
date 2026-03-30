shader_type canvas_item;

// Animated gradient with inner glow for health/mana bars.
// Gives the bars a molten, living feel.

uniform vec4 color_left : source_color = vec4(1.0, 0.15, 0.1, 1.0);
uniform vec4 color_right : source_color = vec4(0.9, 0.4, 0.1, 1.0);
uniform float shimmer_speed : hint_range(0.5, 5.0) = 2.0;
uniform float shimmer_intensity : hint_range(0.0, 0.5) = 0.15;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Animated gradient
    vec3 grad = mix(color_left.rgb, color_right.rgb, UV.x);

    // Shimmer wave moving right
    float shimmer = noise(vec2(UV.x * 8.0 - TIME * shimmer_speed, UV.y * 2.0));
    shimmer = shimmer * shimmer_intensity;

    // Inner glow (brighter in center vertically)
    float center_glow = 1.0 - abs(UV.y - 0.5) * 2.0;
    center_glow = pow(center_glow, 2.0) * 0.3;

    // Top-edge highlight for 3D bevel look
    float top_highlight = smoothstep(0.15, 0.0, UV.y) * 0.35;

    // Bottom-edge shadow for depth
    float bottom_shadow = smoothstep(0.85, 1.0, UV.y) * 0.25;

    vec3 final_color = grad + shimmer + center_glow + top_highlight - bottom_shadow;

    // Only apply where the original texture has color (the fill)
    COLOR = vec4(final_color, tex.a);
}
