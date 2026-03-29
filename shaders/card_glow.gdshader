shader_type canvas_item;

// Pulsing glow border effect for card slots.
// When a card is playable, the border pulses with fiery energy.

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float border_width : hint_range(0.005, 0.05) = 0.02;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Distance from edge
    float dx = min(UV.x, 1.0 - UV.x);
    float dy = min(UV.y, 1.0 - UV.y);
    float edge_dist = min(dx, dy);

    // Pulsing glow at borders
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5);
    float glow = smoothstep(border_width * 2.0, 0.0, edge_dist);
    glow *= pulse * glow_intensity;

    // Add flickering variation
    float flicker = sin(TIME * 7.0 + UV.x * 10.0) * 0.15 + 0.85;
    glow *= flicker;

    vec3 final_color = tex.rgb + glow_color.rgb * glow;
    COLOR = vec4(final_color, tex.a);
}
