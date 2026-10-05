shader_type canvas_item;
uniform vec2 mask_size = vec2(1.0);
varying vec2 local_position;
void vertex() {
    local_position = VERTEX;
}
void fragment() {
    vec4 color = texture(TEXTURE, UV) * COLOR;
    vec2 circle_uv = local_position / max(mask_size, vec2(1.0));
    color.a *= 1.0 - smoothstep(0.48, 0.50, length(circle_uv - vec2(0.5)));
    COLOR = color;
}
