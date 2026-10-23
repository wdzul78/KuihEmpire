extends Node
var problems := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		problems += 1
		push_error(message)
func _ready() -> void:
	var fx := GameVfx.new()
	add_child(fx)
	fx.begin_order_chain()
	var colors := {}
	for i in 12:
		var origin := Vector2(i*50,100)
		fx.order_electric(origin,PackedVector2Array([Vector2(100,200)]),50)
		var effect: Dictionary = fx.effects.back()
		check(not colors.has(effect.color),"each activation has a different electric color")
		colors[effect.color] = true
		check(effect.chain_index == i,"activation color order includes every chain wave")
		check(fx.order_origin_color(origin) == effect.color,"impact uses the same origin color")
	fx.begin_order_chain()
	fx.order_electric(Vector2.ZERO,PackedVector2Array(),50)
	check(fx.effects.back().color == GameVfx.ORDER_CHAIN_COLORS[0],"new move resets to the first color")
	fx.free()
	print("Order chain colors: %s (%d problems)" % ["PASS" if problems == 0 else "FAIL",problems])
	get_tree().quit(problems)
