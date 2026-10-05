class_name ButtonArt
extends Control

var texture: Texture2D
var button: Button
var _mode := -1

static func apply(target: Button, art: Texture2D) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var background := ButtonArt.new()
	background.texture = art
	background.button = target
	background.show_behind_parent = true
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(background)

func _ready() -> void:
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	if button.get_draw_mode() != _mode:
		_mode = button.get_draw_mode()
		queue_redraw()

func _draw() -> void:
	if texture == null or size.y <= 0:
		return
	# Scale the rounded ends uniformly; stretch only the middle of the sprite.
	var factor := size.y / texture.get_height()
	var skin := StyleBoxTexture.new()
	skin.texture = texture
	skin.texture_margin_left = texture.get_height() * .5
	skin.texture_margin_right = texture.get_height() * .5
	skin.modulate_color = Color(.65, .65, .65) if _mode == BaseButton.DRAW_DISABLED else Color(.88, .88, .88) if _mode == BaseButton.DRAW_PRESSED else Color(1.06, 1.06, 1.06) if _mode == BaseButton.DRAW_HOVER else Color.WHITE
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * factor)
	draw_style_box(skin, Rect2(Vector2.ZERO, size / factor))
	draw_set_transform(Vector2.ZERO)
