shader_type canvas_item;

uniform vec4 accent : source_color = vec4(1.0, 0.33, 0.64, 1.0);

void fragment() {
	vec4 painted = texture(TEXTURE, UV);
	// Recolor only the existing red/pink fabric, preserving its silhouette.
	// Sky, wood, foliage and cream stripes remain fully transparent here.
	float fabric = smoothstep(0.08, 0.20, painted.r - painted.g)
		* smoothstep(0.035, 0.12, painted.r - painted.b)
		* smoothstep(0.82, 0.96, painted.b / max(painted.g, 0.001));
	vec3 shaded = accent.rgb * painted.r;
	COLOR = vec4(shaded, painted.a * fabric);
}
