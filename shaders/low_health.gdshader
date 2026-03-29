shader_type canvas_item;

// Red pulsing vignette overlay when player health is low.
// Set health_ratio uniform from script (0.0 = dead, 1.0 = full).

uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float pulse_speed : hint_range(1.0, 6.0) = 3.0;
uniform float threshold : hint_range(0.1, 0.5) = 0.35;

void fragment() {
    if (health_ratio >= threshold) {
        COLOR = vec4(0.0);
        return;
    }

    float severity = 1.0 - (health_ratio / threshold);
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * 0.3 + 0.7;

    vec2 uv = UV - 0.5;
    float dist = length(uv);

    // Red vignette that intensifies as health drops
    float vignette = smoothstep(0.3, 0.8, dist);
    float alpha = vignette * severity * pulse * 0.45;

    COLOR = vec4(0.8, 0.05, 0.0, alpha);
}
