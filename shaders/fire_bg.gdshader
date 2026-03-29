shader_type canvas_item;

// Animated fire/ember background effect for menus.
// Uses layered noise scrolling to simulate rising flames.

uniform float speed : hint_range(0.1, 3.0) = 0.8;
uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform vec4 fire_color_hot : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform vec4 fire_color_mid : source_color = vec4(0.8, 0.2, 0.05, 1.0);
uniform vec4 fire_color_cool : source_color = vec4(0.15, 0.02, 0.0, 1.0);
uniform vec4 base_color : source_color = vec4(0.06, 0.06, 0.1, 1.0);

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

float fbm(vec2 p) {
    float val = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        val += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return val;
}

void fragment() {
    vec2 uv = UV;

    // Fire rises from bottom
    float fire_y = 1.0 - uv.y;

    // Distorted scrolling UV for flame movement
    vec2 fire_uv = vec2(uv.x * 3.0, uv.y * 4.0 - TIME * speed);
    float n1 = fbm(fire_uv);
    float n2 = fbm(fire_uv * 1.5 + vec2(5.2, 1.3) + TIME * speed * 0.3);

    // Combine noise layers for flame shape
    float flame = n1 * 0.6 + n2 * 0.4;

    // Fade flames toward top and edges
    flame *= smoothstep(0.0, 0.4, fire_y);
    flame *= smoothstep(0.0, 0.15, uv.x) * smoothstep(0.0, 0.15, 1.0 - uv.x);
    flame *= intensity;

    // Color gradient based on flame intensity
    vec3 fire_col = mix(fire_color_cool.rgb, fire_color_mid.rgb, smoothstep(0.1, 0.35, flame));
    fire_col = mix(fire_col, fire_color_hot.rgb, smoothstep(0.35, 0.6, flame));

    // Blend fire over base color
    vec3 final_color = mix(base_color.rgb, fire_col, flame * 1.5);

    // Add subtle ember particles
    float ember = step(0.97, noise(uv * 20.0 + vec2(0.0, -TIME * 2.0)));
    ember *= smoothstep(0.0, 0.5, fire_y);
    final_color += vec3(1.0, 0.5, 0.1) * ember * 0.4;

    COLOR = vec4(final_color, 1.0);
}
