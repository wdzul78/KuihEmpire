shader_type canvas_item;
render_mode unshaded;
uniform float frame = 0.0;
uniform float frames = 2.0;
void fragment() {
 vec4 art = texture(TEXTURE,vec2(UV.x,(UV.y+frame)/frames));
 art.a *= smoothstep(0.0,0.22,UV.y)*(1.0-smoothstep(0.78,1.0,UV.y));
 COLOR = art;
}
