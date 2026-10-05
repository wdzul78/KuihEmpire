shader_type canvas_item;

uniform vec2 region_origin = vec2(0.0);
uniform vec2 region_size = vec2(1.0);
uniform vec2 display_size = vec2(1024.0, 768.0);
uniform float radius = 36.0;

void fragment() {
	vec2 local_uv = (UV - region_origin) / region_size;
	vec2 half_size = display_size * 0.5;
	vec2 q = abs((local_uv - vec2(0.5)) * display_size) - (half_size - vec2(radius));
	float edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	COLOR.a *= 1.0 - smoothstep(-1.0, 1.0, edge);
}
