class_name SpecialExecutionText
extends Control

const ANIMATION_PACE = preload("res://scripts/gameplay/animation_pace.gd")

const SHEET = preload("res://assets/ui/special_execution_v1/titles_colored.png")
const BADAK_TITLE = preload("res://assets/vfx/coconut_v1/badak_title.png")
const PUTERI_TITLE = preload("res://assets/vfx/coconut_v1/puteri_title.png")
const PREMIUM_TITLE = preload("res://assets/vfx/premium_gold_v1/title.png")
const TITLE_SHEET = preload("res://assets/vfx/selorot_unwrap_v1/titles.png")
const KETUPAT_TITLE = preload("res://assets/vfx/ketupat_raya_v1/title.png")
const KETUPAT_COMBO_TITLE = preload("res://assets/vfx/ketupat_combo_v1/title.png")

func show_ketupat(board_size: Vector2, cell: float, origin: Vector2, raya: bool = true) -> void:
	show_pisang(board_size,cell,origin)
	var graphic: TextureRect = get_node("PisangCrispyGraphic")
	graphic.name = "KetupatRayaGraphic" if raya else "KetupatGraphic"
	graphic.texture = KETUPAT_TITLE if raya else KETUPAT_COMBO_TITLE
	_tween.kill()
	var hold := GameVfx.KETUPAT_RAYA_HOLD if raya else GameVfx.KETUPAT_COMBO_HOLD
	_tween = create_tween().set_speed_scale(ANIMATION_PACE.SPEED)
	_tween.tween_property(self,"scale",Vector2.ONE,.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold+.15)
	_tween.tween_property(self,"modulate:a",0.0,.30)
	_tween.tween_callback(reset)

static func title_region(bottom: bool) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = TITLE_SHEET
	var split := TITLE_SHEET.get_height()*.41
	atlas.region = Rect2(0,split if bottom else 0,TITLE_SHEET.get_width(),TITLE_SHEET.get_height()-split if bottom else split)
	return atlas

func show_diraja(board_size: Vector2, cell: float, origin: Vector2) -> void:
	reset()
	size = Vector2(board_size.x*.96,cell*1.5)
	position = Vector2(board_size.x*.02,board_size.y-cell*1.7 if origin.y < board_size.y*.5 else cell*.12)
	pivot_offset = size*.5
	var label := Label.new()
	label.text = "Kek Lapis Diraja!"
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",int(minf(cell*.66,board_size.x*.072)))
	label.add_theme_color_override("font_color",Color("fff5a8"))
	label.add_theme_color_override("font_outline_color",Color("6b3317"))
	label.add_theme_constant_override("outline_size",maxi(2,int(cell*.055)))
	add_child(label)
	modulate.a = 1
	scale = Vector2.ONE*.55
	show()
	_tween = create_tween().set_speed_scale(ANIMATION_PACE.SPEED)
	_tween.tween_property(self,"scale",Vector2.ONE,.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(.80)
	_tween.tween_property(self,"modulate:a",0.0,.25)
	_tween.tween_callback(reset)

func show_pisang(board_size: Vector2, cell: float, origin: Vector2 = Vector2.ZERO) -> void:
	reset()
	size = Vector2(board_size.x*.94,cell*2.3)
	var title_y := board_size.y-size.y*.95 if origin.y < board_size.y*.5 else cell*.15
	position = Vector2(board_size.x*.03,title_y)
	pivot_offset = size*.5
	var title := TextureRect.new()
	title.name = "PisangCrispyGraphic"
	title.texture = title_region(true)
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.size = size
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	modulate.a = 1
	scale = Vector2.ONE*.5
	show()
	_tween = create_tween().set_speed_scale(ANIMATION_PACE.SPEED)
	_tween.tween_property(self,"scale",Vector2.ONE,.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(.75)
	_tween.tween_property(self,"modulate:a",0.0,.3)
	_tween.tween_callback(reset)
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
		BoardCell.Special.TAPAU: return 0
		BoardCell.Special.TAPAU_VERTICAL: return 4
		BoardCell.Special.DULANG: return 1
		BoardCell.Special.HANTAR: return -1
		BoardCell.Special.ORDER: return 3
	return -1

func _texture(index: int) -> Texture2D:
	if index == 4:
		return title_region(false)
	if not _textures.has(index):
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = REGIONS[index]
		_textures[index] = atlas
	return _textures[index]

func show_wave(kinds: Array, board_size: Vector2, cell: float, double_badak: bool = false) -> void:
	reset()
	var unique: Array[int] = []
	for kind in kinds:
		var index := _index(kind)
		if index >= 0 and not unique.has(index):
			unique.append(index)
	if unique.is_empty():
		return
	var row_height := minf(cell*.9,board_size.y*.13)
	if unique.has(3):
		row_height = cell*2.3
	if unique.has(1):
		row_height = minf(cell*1.85,board_size.y*.25)
	size = Vector2(board_size.x*.78,row_height*unique.size())
	if unique.has(1):
		size.x = board_size.x*.92
	position = Vector2((board_size.x-size.x)*.5,clampf(board_size.y*.46,0,board_size.y-size.y-20))
	if unique.has(1):
		position.y = clampf(board_size.y*.65,0,board_size.y-size.y-20)
	pivot_offset = size*.5
	for row in unique.size():
		var graphic := TextureRect.new()
		graphic.name = ["TapauGraphic","DulangGraphic","HantarGraphic","SpecialOrderGraphic","SelorotGraphic"][unique[row]]
		graphic.texture = _texture(unique[row])
		if unique[row] == 3:
			graphic.texture = PREMIUM_TITLE
		if unique[row] == 1:
			graphic.texture = PUTERI_TITLE if double_badak else BADAK_TITLE
		graphic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		graphic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		graphic.size = Vector2(size.x,row_height)
		graphic.position.y = row*row_height
		add_child(graphic)
	modulate.a = 1
	scale = Vector2.ONE*.55
	show()
	_tween = create_tween().set_speed_scale(ANIMATION_PACE.SPEED)
	_tween.tween_property(self,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(.65 if unique.has(1) else (.42 if unique.has(3) else .28))
	_tween.tween_property(self,"position:y",position.y-row_height*.4,.28).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(self,"modulate:a",0.0,.28)
	_tween.tween_callback(reset)
