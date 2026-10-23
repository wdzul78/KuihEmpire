extends Control
## Presentation only. The transaction is already saved before this animation starts.
var stage := 0.0
var focus := Vector2.ZERO
var elapsed := 0.0
var caption: Label
var stretch_to_fit := false
var paired_lamps := false
var paired_offset := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 250
	caption = UIKit.wrap_label("", 34, Palette.WOOD_DARK)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(self, badge, Rect2(.12,.78,.76,.075))
	badge.add_child(caption)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if stage < 1.0:
		return
	var pulse := sin(clampf((stage - 1.0) / 2.0, 0, 1) * PI)
	for index in 22:
		var angle := index * TAU / 22.0 + elapsed * .32
		var radius := (45 + fmod(elapsed * 100 + index * 17, 140)) * size.x / 540.0
		var point := focus + Vector2.from_angle(angle) * radius
		var glow := Color("ffd66b") if index % 2 == 0 else Color("fffbea")
		glow.a = pulse * .85
		var length := (5 + sin(index + elapsed * 4) * 2) * size.x / 540.0
		draw_line(point - Vector2(length,0), point + Vector2(length,0), glow, 2, true)
		draw_line(point - Vector2(0,length), point + Vector2(0,length), glow, 2, true)

func play(old_texture: Texture2D, new_texture: Texture2D, target: Rect2, removing: bool) -> void:
	focus = target.get_center()
	var ms: bool = SaveManager.get_setting("language", "en") == "ms"
	caption.text = "Mengangkat hiasan lama…" if ms else "Lifting the old decoration…"
	if old_texture != null:
		var old := _object(old_texture, target)
		var lift := create_tween().set_parallel(true)
		lift.tween_property(old, "position:y", old.position.y - size.y * .12, .40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		lift.tween_property(old, "modulate:a", 0.0, .40)
		await lift.finished
		old.queue_free()
	else:
		await get_tree().create_timer(.22).timeout
	stage = 1.0
	caption.text = "Membersihkan ruang…" if ms else "Making room…"
	await get_tree().create_timer(.32).timeout
	stage = 1.8
	caption.text = "Memasang pilihan anda…" if ms else "Placing your choice…"
	if new_texture != null and not removing:
		var fresh := _object(new_texture, target)
		fresh.pivot_offset = target.size * .5
		fresh.position.y -= size.y * .09
		fresh.scale = Vector2(.72,.72)
		fresh.modulate.a = 0
		var land := create_tween().set_parallel(true)
		land.tween_property(fresh, "position", target.position, .58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		land.tween_property(fresh, "scale", Vector2.ONE, .58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		land.tween_property(fresh, "modulate:a", 1.0, .20)
		await land.finished
	else:
		await get_tree().create_timer(.40).timeout
	stage = 2.4
	caption.text = "Siap! Gerai makin berseri." if ms else "Done! Your stall is looking lovely."
	await get_tree().create_timer(.45).timeout

func _object(texture: Texture2D, target: Rect2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	if paired_lamps:
		var left := AtlasTexture.new()
		left.atlas = texture
		left.region = Rect2(Vector2.ZERO,Vector2(texture.get_width()*.5,texture.get_height()))
		sprite.texture = left
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE if stretch_to_fit else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.z_index = -1
	add_child(sprite)
	sprite.position = target.position
	sprite.size = target.size
	if paired_lamps:
		var right := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(texture.get_width()*.5,0),Vector2(texture.get_width()*.5,texture.get_height()))
		right.texture = atlas
		right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.add_child(right)
		right.position = paired_offset
		right.size = target.size
	return sprite

func play_structure(old_texture: Texture2D, target: Rect2) -> void:
	focus = Vector2(size.x * .5, size.y * .43)
	var ms: bool = SaveManager.get_setting("language", "en") == "ms"
	caption.text = "Menyiapkan naik taraf…" if ms else "Restoring your stall…"
	var cover := _object(old_texture, target)
	cover.stretch_mode = TextureRect.STRETCH_SCALE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float reveal = 0.0; void fragment(){ vec4 c=texture(TEXTURE,UV); float edge=UV.y*0.8+sin(UV.x*24.0)*0.025; c.a *= smoothstep(reveal-0.08,reveal,edge); COLOR=c; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	cover.material = material
	stage = 1.0
	await get_tree().create_timer(.3).timeout
	var reveal := create_tween()
	reveal.tween_method(func(value: float) -> void:
		material.set_shader_parameter("reveal", value)
		stage = 1.0 + value
	, 0.0, 1.1, 1.35)
	await reveal.finished
	cover.queue_free()
	caption.text = "Siap! Gerai makin berseri." if ms else "Done! Your stall is looking lovely."
	await get_tree().create_timer(.5).timeout
