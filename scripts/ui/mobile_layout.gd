class_name MobileLayout
extends RefCounted

## Artwork fills the viewport; interactive UI stays inside the device safe area.
static func safe_rect(root: Control) -> Rect2:
	var full := Rect2(Vector2.ZERO,root.size)
	if OS.get_name() not in ["Android","iOS"]:
		return full
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if not safe.has_area():
		return full
	# Safe area is in screen pixels; canvas coordinates include stretch scaling.
	var screen_to_canvas := root.get_viewport().get_screen_transform().affine_inverse()
	var canvas_to_local := root.get_global_transform_with_canvas().affine_inverse()
	var transform := canvas_to_local * screen_to_canvas
	return (transform * safe).intersection(full)

static func inset_offsets(full_size: Vector2, safe: Rect2, anchors: Vector4) -> Vector4:
	var delta := safe.size-full_size
	return Vector4(safe.position.x+delta.x*anchors.x,safe.position.y+delta.y*anchors.y,
		safe.position.x+delta.x*anchors.z,safe.position.y+delta.y*anchors.w)

static func bind(root: Control, excluded: Array[String] = []) -> void:
	var controls: Array[Control] = []
	for child in root.get_children():
		if child is Control and String(child.name) not in excluded:
			controls.append(child)
	var fit := func() -> void:
		var safe := safe_rect(root)
		for child in controls:
			if not is_instance_valid(child):
				continue
			var offsets := Vector4(child.offset_left,child.offset_top,child.offset_right,child.offset_bottom)
			var previous: Vector4 = child.get_meta("mobile_safe_insets",Vector4.ZERO)
			var original := offsets-previous
			var anchors := Vector4(child.anchor_left,child.anchor_top,child.anchor_right,child.anchor_bottom)
			var insets := inset_offsets(root.size,safe,anchors)
			child.offset_left = original.x+insets.x
			child.offset_top = original.y+insets.y
			child.offset_right = original.z+insets.z
			child.offset_bottom = original.w+insets.w
			child.set_meta("mobile_safe_insets",insets)
	root.resized.connect(fit)
	fit.call_deferred()
