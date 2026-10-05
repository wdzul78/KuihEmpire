class_name HeartRefillDialog
extends Control

var _status: Label
var _one: Button
var _full: Button
var _ad: Button

static func open(parent: Node) -> void:
	if parent.has_node("HeartRefillDialog"):
		return
	parent.add_child(HeartRefillDialog.new())

func _ready() -> void:
	name = "HeartRefillDialog"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	JourneyArt.place(self, dim, Rect2(0, 0, 1, 1))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	JourneyArt.place(self, card, Rect2(.10, .24, .80, .39))
	var stack := UIKit.vbox(20)
	card.add_child(stack)
	stack.add_child(UIKit.title(JourneyArt.localized("Aina berehat sebentar", "Aina needs a little rest"), 40))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized("Heart pulih sendiri. Sementara menunggu, boleh singgah ke gerai, resepi dan cerita.", "Hearts refill automatically. Visit your stall, recipes and stories while you wait."), 28))
	_status = UIKit.label("", 32, Palette.PINK_DARK)
	stack.add_child(_status)
	_one = UIKit.button(JourneyArt.localized("+1 Heart · 500 syiling", "+1 Heart · 500 coins"), 30, Palette.LEAF)
	_one.pressed.connect(func() -> void: HeartManager.purchase_refill(); _refresh())
	stack.add_child(_one)
	_full = UIKit.button(JourneyArt.localized("Isi penuh · 1,800 syiling", "Full refill · 1,800 coins"), 30, Palette.PINK)
	_full.pressed.connect(func() -> void: HeartManager.purchase_refill(true); _refresh())
	stack.add_child(_full)
	_ad = UIKit.button(JourneyArt.localized("Tonton iklan · +1 Heart", "Watch ad · +1 Heart"), 30)
	_ad.pressed.connect(func() -> void:
		_ad.disabled = true
		await HeartManager.watch_ad()
		_refresh()
	)
	stack.add_child(_ad)
	var close := GameButton.create(MenuText.text("close"), "back")
	close.pressed.connect(queue_free)
	stack.add_child(close)
	var home := GameButton.create(JourneyArt.localized("Kembali ke gerai", "Back to stall"), "back")
	home.pressed.connect(GameManager.go_home)
	stack.add_child(home)
	HeartManager.changed.connect(_refresh)
	EconomyManager.coins_changed.connect(func(_amount: int) -> void: _refresh())
	_refresh()

func _refresh() -> void:
	var count := HeartManager.current()
	_status.text = "%d / %d" % [count, HeartManager.MAX_HEARTS]
	if HeartManager.is_free_play_active():
		_status.text += " · Free Play " + HeartManager.time_text(HeartManager.get_free_play_remaining())
	elif count < HeartManager.MAX_HEARTS:
		_status.text += "\n+1  " + HeartManager.time_text(HeartManager.get_next_refill_remaining())
	_one.disabled = count == HeartManager.MAX_HEARTS or not EconomyManager.can_afford(HeartManager.ONE_PRICE)
	_full.disabled = count == HeartManager.MAX_HEARTS or not EconomyManager.can_afford(HeartManager.FULL_PRICE)
	_ad.visible = HeartManager.rewarded_ad_provider.is_valid()
	_ad.disabled = not HeartManager.can_watch_ad()
