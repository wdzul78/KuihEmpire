extends Button

func _ready() -> void:
	toggle_mode = true
	for state in ["normal","pressed","hover","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_style_box(UIKit.flat_box(Color("67ad38") if button_pressed else Color("b8ad97"),Color("3e8028") if button_pressed else Color("827663"),0,2,size.y*.5),Rect2(Vector2.ZERO,size))
	var radius := size.y*.38
	draw_circle(Vector2(size.x-size.y*.5 if button_pressed else size.y*.5,size.y*.5),radius,Color("fffbed"))
