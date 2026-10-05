class_name SpecialExecutionText
extends Control

const SHEET = preload("res://assets/ui/special_execution_v1/titles_colored.png")
const REGIONS := [Rect2(58,203,539,226),Rect2(670,204,549,222),Rect2(45,816,551,215),Rect2(651,829,572,176)]
var _textures: Dictionary = {}
var _tween: Tween

func _ready() -> void:
	name = "SpecialExecutionText"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 35
	hide()

func reset() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	hide()

func _index(kind: int) -> int:
	match kind:
		BoardCell.Special.TAPAU, BoardCell.Special.TAPAU_VERTICAL: return 0
		BoardCell.Special.DULANG: return 1
		BoardCell.Special.HANTAR: return 2
		BoardCell.Special.ORDER: return 3
	return -1

func _texture(index: int) -> Texture2D:
	if not _textures.has(index):
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = REGIONS[index]
		_textures[index] = atlas
	return _textures[index]

func show_wave(kinds: Array, board_size: Vector2, cell: float) -> void:
	reset()
	var unique: Array[int] = []
	for kind in kinds:
		var index := _index(kind)
		if index >= 0 and not unique.has(index):
			unique.append(index)
	if unique.is_empty():
		return
	var row_height := minf(cell*.9,board_size.y*.13)
	size = Vector2(board_size.x*.78,row_height*unique.size())
	position = Vector2((board_size.x-size.x)*.5,clampf(board_size.y*.46,0,board_size.y-size.y-20))
	pivot_offset = size*.5
	for row in unique.size():
		var graphic := TextureRect.new()
		graphic.name = ["TapauGraphic","DulangGraphic","HantarGraphic","SpecialOrderGraphic"][unique[row]]
		graphic.texture = _texture(unique[row])
		graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		graphic.size = Vector2(size.x,row_height)
		graphic.position.y = row*row_height
		add_child(graphic)
	modulate.a = 1
	scale = Vector2.ONE*.55
	show()
	_tween = create_tween()
	_tween.tween_property(self,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(.28)
	_tween.tween_property(self,"position:y",position.y-row_height*.4,.28).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(self,"modulate:a",0.0,.28)
	_tween.tween_callback(reset)
