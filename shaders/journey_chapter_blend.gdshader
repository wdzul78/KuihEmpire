shader_type canvas_item;
render_mode unshaded;
uniform sampler2D above_map : source_color, filter_linear;
uniform sampler2D below_map : source_color, filter_linear;
uniform bool has_above = false;
uniform bool has_below = false;
uniform float feather = 0.035;
void fragment() {
 vec4 own = texture(TEXTURE, UV);
 // Both sides evaluate the same 50/50 edge sample at the chapter boundary.
 // Feathering into each illustration removes the abrupt full-width cut.
 if (has_above && UV.y < feather) {
  float weight = 0.5 * (1.0-smoothstep(0.0,feather,UV.y));
  own = mix(own,texture(above_map,vec2(UV.x,1.0-UV.y)),weight);
 }
 if (has_below && UV.y > 1.0-feather) {
  float weight = 0.5*smoothstep(1.0-feather,1.0,UV.y);
  own = mix(own,texture(below_map,vec2(UV.x,1.0-UV.y)),weight);
 }
 COLOR = own;
}
