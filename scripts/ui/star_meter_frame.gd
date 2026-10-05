class_name StarMeterFrame
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	ResourceBarArt.draw_frame(self, "star")
