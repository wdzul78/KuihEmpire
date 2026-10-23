shader_type canvas_item;
// Retain the supplied candy silhouette and its dark edge, with a contrasting
// solid face instead of gold highlights disappearing against cream panels.
void fragment() {
	vec4 glyph = texture(TEXTURE, UV);
	float face = smoothstep(0.20, 0.42, dot(glyph.rgb, vec3(0.299,0.587,0.114)));
	vec3 ink = clamp(COLOR.rgb / max(glyph.rgb, vec3(0.001)), vec3(0.0), vec3(1.0));
	vec3 lettering = mix(vec3(0.20,0.075,0.025), ink, face);
	COLOR = vec4(lettering, COLOR.a);
}
