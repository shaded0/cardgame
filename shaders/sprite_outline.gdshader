shader_type canvas_item;

// Adds a dark outline around opaque pixels for character readability.
// Apply as material on AnimatedSprite2D nodes.

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
uniform float outline_width : hint_range(0.5, 4.0) = 1.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    if (col.a > 0.1) {
        COLOR = col;
        return;
    }

    // Sample neighbors to detect edge of opaque region
    vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
    float a = 0.0;
    a += texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a;
    a += texture(TEXTURE, UV + vec2(ps.x, 0.0)).a;
    a += texture(TEXTURE, UV + vec2(0.0, -ps.y)).a;
    a += texture(TEXTURE, UV + vec2(0.0, ps.y)).a;
    // Diagonals for smoother outline
    a += texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a * 0.7;
    a += texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a * 0.7;
    a += texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a * 0.7;
    a += texture(TEXTURE, UV + vec2(ps.x, ps.y)).a * 0.7;

    if (a > 0.1) {
        COLOR = outline_color;
    } else {
        COLOR = col;
    }
}
