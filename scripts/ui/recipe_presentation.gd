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
	# Kuih that are also board tiles show their tile art until a recipe painting exists.
	var tile := String(recipe.gameplay_reference_id).trim_prefix("tile:")
	if unlocked and KuihLibrary.has(StringName(tile)):
		var icon := KuihIcon.new()
		icon.kuih = KuihLibrary.get_kuih(StringName(tile))
		icon.custom_minimum_size = Vector2(edge, edge)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return icon
	var placeholder := UIKit.wrap_label("◇\n" + RecipeText.text("art_pending") if unlocked else "?", 34 if unlocked else 88, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER)
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
	# Same ribbon frame as the stall's task-complete card; only the height changes,
	# and that stretches the plain middle of the frame, never the ribbon.
	var dialog := GeraiSkin.dialog(RecipeText.text("new") if _discovery else RecipeText.text("book"), true, .94)
	var frame: PanelContainer = dialog.panel
	JourneyArt.place(root, frame, Rect2(.03, .19, .94, .50) if _discovery else Rect2(.03, .05, .94, .90))
	var column: VBoxContainer = dialog.stack
	column.add_child(UIKit.wrap_label("#%03d · %s" % [_recipe.collection_number, _recipe.text("name")], 50, Palette.WOOD_DARK, HORIZONTAL_ALIGNMENT_CENTER))
	var artwork := artwork_control(_recipe, true, 280)
	artwork.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(artwork)
	if _discovery:
		var record: Dictionary = SaveManager.data.get("recipe_discovery_records", {}).get(String(_recipe.id), {})
		column.add_child(UIKit.wrap_label("+ " + (RecipeText.text("coins") % int(record.get("coins", 0))), 44, Palette.LEAF_DEEP, HORIZONTAL_ALIGNMENT_CENTER))
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
	content.add_child(UIKit.wrap_label(RecipeText.text("research"), 32, Palette.WOOD_DARK))
	for field in ["alternative_names", "region", "state", "community", "category", "short_description", "ingredients_summary", "interesting_fact"]:
		var value := _recipe.text(field)
		if value in ["RESEARCH_REQUIRED", "KAJIAN_DIPERLUKAN"]:
			value = RecipeText.text("awaiting_review")
		content.add_child(UIKit.wrap_label(RecipeText.text(field) + ": " + value, 34, Palette.WOOD_DARK))
	# Kuih met in a tutorial were never a stage reward, so don't send players to one.
	var source := str(SaveManager.data.get("recipe_discovery_records", {}).get(String(_recipe.id), {}).get("source", ""))
	if source not in ["introduction", "migration"]:
		content.add_child(UIKit.wrap_label(RecipeText.text("stage") % _recipe.discovery_stage, 34, Palette.WOOD_DARK))
	_details.visible = not _discovery
	_error = UIKit.wrap_label("", 30, Palette.PINK_DARK)
	column.add_child(_error)
	var actions := UIKit.hbox(14)
	column.add_child(actions)
	if _discovery:
		var view := GameButton.create(RecipeText.text("view"), "secondary", 38)
		view.custom_minimum_size.y = 100
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(view)
		view.pressed.connect(func() -> void:
			# Grow to full height so the details have room; the art gives way.
			frame.anchor_top = .05
			frame.anchor_bottom = .95
			artwork.custom_minimum_size = Vector2(180, 180)
			_details.visible = true
			_discovery_spacer.visible = false
			view.visible = false
		)
	var close := GameButton.create(RecipeText.text("continue") if _discovery else RecipeText.text("close"), "primary", 40)
	close.custom_minimum_size.y = 100
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(close)
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
