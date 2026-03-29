shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.45;
uniform float radius : hint_range(0.0, 1.0) = 0.65;
uniform float softness : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float vignette = smoothstep(radius, radius + softness, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * intensity);
}
