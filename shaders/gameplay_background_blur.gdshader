shader_type canvas_item;
render_mode unshaded;

uniform float blur_pixels : hint_range(0.0, 12.0) = 6.0;
varying vec4 vertex_modulation;

void vertex() {
	vertex_modulation = COLOR;
}

vec2 edge_uv(vec2 uv, vec2 pixel) {
	return clamp(uv, pixel * 0.5, vec2(1.0) - pixel * 0.5);
}

void fragment() {
	vec2 delta = TEXTURE_PIXEL_SIZE * blur_pixels;
	vec4 soft = texture(TEXTURE, edge_uv(UV, TEXTURE_PIXEL_SIZE)) * 0.20;
	soft += texture(TEXTURE, edge_uv(UV + vec2(delta.x, 0.0), TEXTURE_PIXEL_SIZE)) * 0.12;
	soft += texture(TEXTURE, edge_uv(UV - vec2(delta.x, 0.0), TEXTURE_PIXEL_SIZE)) * 0.12;
	soft += texture(TEXTURE, edge_uv(UV + vec2(0.0, delta.y), TEXTURE_PIXEL_SIZE)) * 0.12;
	soft += texture(TEXTURE, edge_uv(UV - vec2(0.0, delta.y), TEXTURE_PIXEL_SIZE)) * 0.12;
	soft += texture(TEXTURE, edge_uv(UV + delta, TEXTURE_PIXEL_SIZE)) * 0.08;
	soft += texture(TEXTURE, edge_uv(UV - delta, TEXTURE_PIXEL_SIZE)) * 0.08;
	soft += texture(TEXTURE, edge_uv(UV + vec2(delta.x, -delta.y), TEXTURE_PIXEL_SIZE)) * 0.08;
	soft += texture(TEXTURE, edge_uv(UV + vec2(-delta.x, delta.y), TEXTURE_PIXEL_SIZE)) * 0.08;
	COLOR = vertex_modulation * soft;
}
