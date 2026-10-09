shader_type canvas_item;
render_mode unshaded;

// The supplied RGB artwork has pale green lettering on near-white.
// Isolate that green ink at runtime; retain native alpha for future RGBA art.
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float mask = smoothstep(0.035, 0.16, ink.g - ink.b);
	COLOR = vec4(vec3(1.0), ink.a * mask * COLOR.a);
}
