class_name BootScreen
extends Control

## Splash screen. Warms the procedural art caches, then hands over to the stall
## (Master Plan section 48).

const HOLD_TIME := 1.5
const STUDIO_HOLD_TIME := 1.8
const STUDIO_LOGO := preload("res://assets/branding/keribang_logo.png")
const STUDIO_BACKGROUND := Color("100b18")

var _studio: Control
var _studio_logo: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	_build_studio_splash()
	_run()


func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var stack := UIKit.vbox(10)
	center.add_child(stack)

	stack.add_child(UIKit.brand_logo(Vector2(900, 675)))
	stack.add_child(UIKit.label("Match. Serve. Grow.", 34, Palette.WOOD))


func _build_studio_splash() -> void:
	_studio = Control.new()
	_studio.name = "StudioSplash"
	_studio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_studio.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_studio)
	var background := ColorRect.new()
	background.color = STUDIO_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_studio.add_child(background)
	_studio_logo = TextureRect.new()
	_studio_logo.texture = STUDIO_LOGO
	var logo_material := ShaderMaterial.new()
	logo_material.shader = preload("res://scripts/art/shaders/studio_logo.gdshader")
	_studio_logo.material = logo_material
	_studio_logo.modulate.a = 0.0
	_studio_logo.scale = Vector2.ONE * 0.94
	_studio_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_studio_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_studio.add_child(_studio_logo)
	resized.connect(_layout_studio)
	_layout_studio()


func _layout_studio() -> void:
	if not is_instance_valid(_studio_logo):
		return
	var width := minf(size.x * 0.60, size.y * 0.80)
	_studio_logo.size = Vector2(width, width * STUDIO_LOGO.get_height() / STUDIO_LOGO.get_width())
	_studio_logo.position = (size - _studio_logo.size) * 0.5
	_studio_logo.pivot_offset = _studio_logo.size * 0.5


func _run() -> void:
	# Keep the supplied studio artwork visible before the game's own title.
	await get_tree().process_frame
	_layout_studio()
	var appear := create_tween().set_parallel(true)
	appear.tween_property(_studio_logo, "modulate:a", 1.0, 0.6)
	appear.tween_property(_studio_logo, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await appear.finished
	await get_tree().create_timer(STUDIO_HOLD_TIME).timeout
	var reveal := create_tween()
	reveal.tween_property(_studio, "modulate:a", 0.0, 0.35)
	await reveal.finished
	_studio.queue_free()
	# Force the art cache so the first level starts instantly.
	KuihLibrary.starter_set()
	await get_tree().process_frame
	AudioManager.play(AudioManager.Sfx.TAP, 0.8, -10.0)
	# Only drive navigation when this really is the running scene.
	if not SceneManager.is_current(self):
		return
	await get_tree().create_timer(HOLD_TIME).timeout
	if not SceneManager.is_current(self):
		return
	# New players read the prologue, then start the tutorial. Returning players
	# who already read it go straight to the stall.
	if not ProgressionManager.story_read(StoryLibrary.PROLOGUE):
		await SceneManager.goto_story_then_tutorial(
			StoryLibrary.PROLOGUE, maxi(1, ProgressionManager.tutorial_index()), false
		)
		return
	GameManager.play_next()
