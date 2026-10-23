class_name ComboPraise
extends Control

## Total kuih actually cleared during one move, including cascades/specials.
const THRESHOLDS := [7, 13, 19, 25, 31]
const WORDS := {7: "Bagus!", 13: "Sedapnyaaa!", 19: "Terbaek!", 25: "Padu Teruuk!", 31: "Steadey Bos!!!"}
## Existing voice IDs stay stable; order Sedapnya before Terbaik.
const VOICE_TIERS := {7: 1, 13: 3, 19: 2, 25: 4, 31: 5}
const ART := {
	7: preload("res://assets/ui/combo_praise_v2/bagus.png"),
	13: preload("res://assets/ui/combo_praise_v1/sedapnya.png"),
	19: preload("res://assets/ui/combo_praise_v1/terbaik.png"),
	25: preload("res://assets/ui/combo_praise_v1/padu_teruk.png"),
	31: preload("res://assets/ui/combo_praise_v2/steadey_bos.png"),
}
const REGIONS := {13: Rect2(16,70,1898,641),19: Rect2(17,65,1913,663),25: Rect2(25,80,1996,620)}
var _graphic: TextureRect
var _tween: Tween
var _last_milestone := 0

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
	_last_milestone = 0
	_clear_presentation()

func _clear_presentation() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	hide()

func show_combo(count: int, board_size: Vector2) -> void:
	var milestone := 0
	for threshold in THRESHOLDS:
		if count >= threshold:
			milestone = threshold
	if milestone == 0 or milestone <= _last_milestone:
		return
	count = milestone # One burst crossing several tiers shows only the highest.
	_clear_presentation()
	_last_milestone = count
	size = Vector2(board_size.x*.94, minf(190,board_size.y*.36))
	position = Vector2(board_size.x*.03,board_size.y*.02)
	pivot_offset = size*.5
	var caption: String = WORDS[count]
	var atlas := AtlasTexture.new()
	atlas.atlas = ART[count]
	atlas.region = REGIONS.get(count, ART[count].get_image().get_used_rect())
	atlas.filter_clip = true
	_graphic.texture = atlas
	_graphic.size = size
	_graphic.accessibility_name = caption
	accessibility_name = caption
	modulate.a = 1
	scale = Vector2.ONE*.55
	rotation = -.055
	show()
	var voice: int = VOICE_TIERS[count]
	AudioManager.play_combo(voice, count)
	_tween = create_tween()
	_tween.tween_property(self,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self,"rotation",.025,.22)
	_tween.tween_property(self,"rotation",0.0,.14).set_trans(Tween.TRANS_SINE)
	_tween.tween_interval(maxf(.42,AudioManager.combo_duration(voice)-.36))
	_tween.tween_property(self,"position:y",position.y-25,.25)
	_tween.parallel().tween_property(self,"modulate:a",0.0,.25)
	_tween.tween_callback(hide)
