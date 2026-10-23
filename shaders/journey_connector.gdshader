shader_type canvas_item;
render_mode unshaded;
uniform float frame = 0.0;
void fragment() {
 vec4 art = texture(TEXTURE,vec2(UV.x,(UV.y+frame)*0.5));
 art.a *= smoothstep(0.0,0.22,UV.y)*(1.0-smoothstep(0.78,1.0,UV.y));
 COLOR = art;
}
