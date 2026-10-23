class_name RecipePresentation
extends Control

var _recipe: RecipeDefinition
var _discovery := false
var _done: Callable
var _details: ScrollContainer
var _error: Label
var _discovery_spacer: Control

static func artwork_control(recipe: RecipeDefinition, unlocked: bool, edge: int = 180) -> Control:
	var texture := recipe.artwork() if unlocked else null
	if texture != null:
		var image := TextureRect.new()
		image.texture = texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(edge, edge)
		image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return image
	var placeholder := UIKit.wrap_label("◇\n" + RecipeText.text("art_pending") if unlocked else "?", 32 if unlocked else 88, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
	placeholder.custom_minimum_size = Vector2(edge, edge)
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return placeholder

static func show_detail(host: Control, recipe: RecipeDefinition) -> void:
	if not RecipeBookManager.is_recipe_discovered(recipe.id):
		return
	var panel := RecipePresentation.new()
	panel._recipe = recipe
	host.add_child(panel)

static func present_pending(host: Control, done: Callable = Callable()) -> bool:
	if host.has_node("RecipeDiscoveryOverlay"):
		return true
	var pending: Array = SaveManager.data.get("pending_recipe_presentations", [])
	if pending.is_empty():
		return false
	var recipe := RecipeCatalog.find(StringName(pending[0]))
	if recipe == null:
		return false
	var panel := RecipePresentation.new()
	panel.name = "RecipeDiscoveryOverlay"
	panel._recipe = recipe
	panel._discovery = true
	panel._done = done
	host.add_child(panel)
	return true

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 300
	UIKit.apply_root_theme(self)
	# Above both the result modal (z=200) and achievement toasts (layer=115).
	var layer := CanvasLayer.new()
	layer.layer = 116
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, .65)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(veil)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(root, frame, Rect2(.06, .10, .88, .80))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	frame.add_child(margin)
	var column := UIKit.vbox(14)
	margin.add_child(column)
	column.add_child(UIKit.wrap_label(RecipeText.text("new") if _discovery else RecipeText.text("book"), 40, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UIKit.wrap_label("#%03d · %s" % [_recipe.collection_number, _recipe.text("name")], 42, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(artwork_control(_recipe, true, 250))
	if _discovery:
		var record: Dictionary = SaveManager.data.get("recipe_discovery_records", {}).get(String(_recipe.id), {})
		column.add_child(UIKit.wrap_label("+ " + (RecipeText.text("coins") % int(record.get("coins", 0))), 34, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	_discovery_spacer = Control.new()
	_discovery_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_discovery_spacer.visible = _discovery
	column.add_child(_discovery_spacer)
	_details = ScrollContainer.new()
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_details)
	var content := UIKit.vbox(16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.add_child(content)
	content.add_child(UIKit.wrap_label(RecipeText.text("research"), 30, Palette.WOOD_DARK))
	for field in ["alternative_names", "region", "state", "community", "category", "short_description", "ingredients_summary", "interesting_fact"]:
		var value := _recipe.text(field)
		if value in ["RESEARCH_REQUIRED", "KAJIAN_DIPERLUKAN"]:
			value = RecipeText.text("awaiting_review")
		content.add_child(UIKit.wrap_label(RecipeText.text(field) + ": " + value, 28, Palette.WOOD_DARK))
	content.add_child(UIKit.wrap_label(RecipeText.text("stage") % _recipe.discovery_stage, 28, Palette.WOOD_DARK))
	_details.visible = not _discovery
	if _discovery:
		var view := GameButton.create(RecipeText.text("view"), "primary", 32)
		column.add_child(view)
		view.pressed.connect(func() -> void: _details.visible = true; _discovery_spacer.visible = false; view.visible = false)
	_error = UIKit.wrap_label("", 28, Palette.PINK_DARK)
	column.add_child(_error)
	var close := GameButton.create(RecipeText.text("continue") if _discovery else RecipeText.text("close"), "primary", 36)
	column.add_child(close)
	close.pressed.connect(_close)

func _close() -> void:
	if _discovery and not RecipeBookManager.acknowledge(_recipe.id):
		_error.text = RecipeText.text("save_failed")
		return
	var host := get_parent() as Control
	# Remove immediately so the next queued popup can use the same node name.
	host.remove_child(self)
	queue_free()
	if _discovery and present_pending(host, _done):
		return
	if _done.is_valid():
		_done.call()
