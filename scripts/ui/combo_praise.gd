class_name ComboPraise
extends Control

const WORDS := {3: "Sedapnya!", 4: "Terbaik!", 5: "Padu Teruk!"}
const ART := {
	3: preload("res://assets/ui/combo_praise_v1/sedapnya.png"),
	4: preload("res://assets/ui/combo_praise_v1/terbaik.png"),
	5: preload("res://assets/ui/combo_praise_v1/padu_teruk.png"),
}
const REGIONS := {3: Rect2(16,70,1898,641),4: Rect2(17,65,1913,663),5: Rect2(25,80,1996,620)}
var _graphic: TextureRect
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	_graphic = TextureRect.new()
	_graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_graphic)
	hide()

func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	hide()

func show_combo(count: int, board_size: Vector2) -> void:
	if not WORDS.has(count):
		return
	reset()
	size = Vector2(board_size.x*.94, minf(125,board_size.y*.26))
	position = Vector2(board_size.x*.03,board_size.y*.02)
	pivot_offset = size*.5
	var caption: String = WORDS[count]
	var atlas := AtlasTexture.new()
	atlas.atlas = ART[count]
	atlas.region = REGIONS[count]
	atlas.filter_clip = true
	_graphic.texture = atlas
	_graphic.size = size
	_graphic.accessibility_name = caption
	accessibility_name = caption
	modulate.a = 1
	scale = Vector2.ONE*.55
	rotation = -.055
	show()
	AudioManager.play_combo(count)
	_tween = create_tween()
	_tween.tween_property(self,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self,"rotation",.025,.22)
	_tween.tween_property(self,"rotation",0.0,.14).set_trans(Tween.TRANS_SINE)
	_tween.tween_interval(.42)
	_tween.tween_property(self,"position:y",position.y-25,.25)
	_tween.parallel().tween_property(self,"modulate:a",0.0,.25)
	_tween.tween_callback(hide)
