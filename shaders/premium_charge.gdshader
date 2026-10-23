shader_type canvas_item;
uniform float charge = 1.0;
void fragment() {
 vec4 food = texture(TEXTURE, UV);
 vec2 step_uv = vec2(0.018);
 float near_a = 0.0;
 float far_a = 0.0;
 for (int i = 0; i < 8; i++) {
  float angle = float(i) * 0.785398;
  vec2 offset = vec2(cos(angle),sin(angle)) * step_uv;
  near_a = max(near_a, texture(TEXTURE, clamp(UV+offset,vec2(0.0),vec2(1.0))).a);
  far_a = max(far_a, texture(TEXTURE, clamp(UV+offset*2.5,vec2(0.0),vec2(1.0))).a);
 }
 float rim = max(0.0,near_a-food.a)*charge;
 float glow = max(0.0,far_a-food.a)*charge*.45;
 vec4 tint = COLOR;
 vec3 hue = mix(vec3(1.0,.68,.02),vec3(1.0,.98,.65),rim);
 float aura = max(rim,glow);
 COLOR = vec4(mix(hue,food.rgb,food.a), max(food.a,aura))*tint;
}
