class_name HeartRefillDialog
extends Control

var _status: Label
var _one: Button
var _full: Button
var _ad: Button
var _timer: Label
var _timer_title: Label
var _message: Label
var _home: Button
var _card: Control
var _ad_caption: Label
var _watching_ad := false
var _ad_notice := ""
const HEART = preload("res://assets/ui/hearts_v2/heart_full.png")
const COIN = preload("res://assets/ui/results_v2/gold_coin.png")

static func open(parent: Node) -> void:
	if parent.has_node("HeartRefillDialog"):
		return
	parent.add_child(HeartRefillDialog.new())

func _ready() -> void:
	name = "HeartRefillDialog"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.apply_root_theme(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .76)
	JourneyArt.place(self, dim, Rect2(0, 0, 1, 1))
	_card = Control.new()
	_card.name = "RestCard"
	JourneyArt.place(self,_card,Rect2(.06,.30,.88,.61))
	_image(_card,preload("res://assets/ui/heart_refill_v1/panel.png"),Rect2(0,0,1,1),true)
	var aina := _image(self,preload("res://assets/ui/heart_refill_v1/aina_rest.png"),Rect2(.14,.075,.72,.27))
	aina.name = "CartoonAinaRest"
	var heading := JourneyArt.label(_card,JourneyArt.localized("Aina perlukan rehat","Aina needs a little rest"),Rect2(.08,.075,.84,.075),48)
	heading.name = "RestHeading"
	var description := JourneyArt.label(_card,JourneyArt.localized("Hati akan pulih secara automatik.\nSinggah ke gerai sementara menunggu.","Hearts refill automatically.\nVisit your stall while you wait."),Rect2(.09,.16,.82,.095),32)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_image(_card,HEART,Rect2(.27,.275,.18,.115))
	_status = JourneyArt.label(_card,"",Rect2(.45,.275,.30,.115),78,Palette.WOOD_DARK)
	var clock := Panel.new()
	clock.add_theme_stylebox_override("panel",UIKit.flat_box(Color("f7e3bc"),Color("edcf94"),0,2,40))
	JourneyArt.place(_card,clock,Rect2(.25,.405,.50,.135))
	_timer_title = JourneyArt.label(clock,"",Rect2(.04,.06,.92,.35),30)
	_timer = JourneyArt.label(clock,"",Rect2(.04,.39,.92,.54),54,Palette.PINK_DARK)
	_message = JourneyArt.label(_card,"",Rect2(.08,.548,.84,.035),25,Palette.WOOD_DARK)
	_one = _purchase(JourneyArt.localized("+1 Hati","+1 Heart"),HeartManager.ONE_PRICE,"primary",false)
	_one.pressed.connect(func() -> void: HeartManager.purchase_refill(); _refresh())
	_full = _purchase(JourneyArt.localized("Isi penuh","Full refill"),HeartManager.FULL_PRICE,"secondary",true)
	_full.pressed.connect(func() -> void: HeartManager.purchase_refill(true); _refresh())
	_ad = UIKit.button("",36)
	_ad.custom_minimum_size = Vector2.ZERO
	_ad.focus_mode = Control.FOCUS_ALL
	_ad.name = "WatchAdButton"
	var blue := AtlasTexture.new()
	blue.atlas = preload("res://assets/ui/heart_refill_ads_v1/button_blue.png")
	blue.region = Rect2(30,90,2110,520)
	ButtonArt.apply(_ad,blue)
	_card.add_child(_ad)
	_image(_ad,preload("res://assets/ui/heart_refill_ads_v1/video_icon.png"),Rect2(.055,.13,.15,.74))
	_ad_caption = JourneyArt.label(_ad,"",Rect2(.22,.10,.38,.80),38,Color.WHITE)
	_image(_ad,HEART,Rect2(.64,.22,.105,.56))
	JourneyArt.label(_ad,JourneyArt.localized("+1 Hati","+1 Heart"),Rect2(.755,.10,.21,.80),34,Color.WHITE)
	_ad.tooltip_text = JourneyArt.localized("Tonton iklan hingga selesai untuk +1 Hati","Finish watching an ad to receive +1 Heart")
	_ad.pressed.connect(_request_ad)
	_home = GameButton.create("","back",42)
	_home.custom_minimum_size = Vector2.ZERO
	_home.focus_mode = Control.FOCUS_ALL
	_card.add_child(_home)
	_image(_home,preload("res://assets/menu/v2/nav_shop.png"),Rect2(.08,.12,.17,.76))
	JourneyArt.label(_home,JourneyArt.localized("Kembali ke gerai","Back to stall"),Rect2(.27,.10,.66,.80),42,Color.WHITE)
	_home.pressed.connect(func() -> void: queue_free(); GameManager.go_home())
	var close := UIKit.close_button()
	close.name = "CloseRestDialog"
	close.custom_minimum_size = Vector2.ZERO
	close.focus_mode = Control.FOCUS_ALL
	JourneyArt.place(self,close,Rect2(.85,.307,.10,.06))
	close.pressed.connect(_close)
	close.tooltip_text = MenuText.text("close")
	close.grab_focus()
	HeartManager.changed.connect(_refresh)
	EconomyManager.coins_changed.connect(func(_amount: int) -> void: _refresh())
	_refresh()

func _image(host: Control, texture: Texture2D, rect: Rect2, stretch: bool = false) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE if stretch else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	JourneyArt.place(host,image,rect)
	return image

func _purchase(caption: String, price: int, role: String, full: bool) -> Button:
	var button := GameButton.create("",role,42)
	button.custom_minimum_size = Vector2.ZERO
	button.focus_mode = Control.FOCUS_ALL
	_card.add_child(button)
	if full:
		for index in 3:
			_image(button,HEART,Rect2(.06+index*.052,.22+absf(index-1)*.08,.11,.55))
	else:
		_image(button,HEART,Rect2(.075,.16,.14,.67))
		JourneyArt.label(button,"+",Rect2(.155,.43,.07,.35),38,Color.WHITE)
	JourneyArt.label(button,caption,Rect2(.24,.10,.36,.80),42,Color.WHITE)
	_image(button,COIN,Rect2(.61,.27,.075,.45))
	var amount := "1,800" if price == 1800 else str(price)
	var price_text := amount+JourneyArt.localized(" syiling"," coins")
	JourneyArt.label(button,price_text,Rect2(.69,.10,.265,.80),32,Color.WHITE)
	button.tooltip_text = caption+" · "+price_text
	return button

func _close() -> void:
	AudioManager.play(AudioManager.Sfx.TAP)
	queue_free()

func _request_ad() -> void:
	if _watching_ad or not HeartManager.can_watch_ad():
		return
	_watching_ad = true
	_ad_notice = ""
	_refresh()
	_finish_ad(weakref(self))

static func _finish_ad(dialog_ref: WeakRef) -> void:
	var completed := await HeartManager.watch_ad()
	var dialog: HeartRefillDialog = dialog_ref.get_ref()
	if dialog == null or dialog.is_queued_for_deletion():
		return
	dialog._watching_ad = false
	dialog._ad_notice = JourneyArt.localized("+1 Hati diterima!","+1 Heart received!") if completed else JourneyArt.localized("Iklan tidak selesai. Tiada hati digunakan.","Ad not completed. No hearts spent.")
	dialog._refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _refresh() -> void:
	var count := HeartManager.current()
	_status.text = "%d / %d" % [count, HeartManager.MAX_HEARTS]
	if HeartManager.is_free_play_active():
		_timer_title.text = JourneyArt.localized("Main percuma","Free play")
		_timer.text = HeartManager.time_text(HeartManager.get_free_play_remaining())
	elif count < HeartManager.MAX_HEARTS:
		_timer_title.text = JourneyArt.localized("Hati seterusnya","Next heart")
		_timer.text = HeartManager.time_text(HeartManager.get_next_refill_remaining())
	else:
		_timer_title.text = JourneyArt.localized("Hati sudah penuh!","Hearts are full!")
		_timer.text = "5 / 5"
	_one.disabled = count == HeartManager.MAX_HEARTS or not EconomyManager.can_afford(HeartManager.ONE_PRICE)
	_full.disabled = count == HeartManager.MAX_HEARTS or not EconomyManager.can_afford(HeartManager.FULL_PRICE)
	_ad.visible = true
	_ad.disabled = _watching_ad or not HeartManager.can_watch_ad()
	_ad_caption.text = JourneyArt.localized("Memuatkan…","Loading…") if _watching_ad else JourneyArt.localized("Tonton iklan","Watch ad")
	_message.text = JourneyArt.localized("Syiling tidak mencukupi","Not enough coins") if count < HeartManager.MAX_HEARTS and not EconomyManager.can_afford(HeartManager.ONE_PRICE) else ""
	if not _ad_notice.is_empty():
		_message.text = _ad_notice
	elif _watching_ad:
		_message.text = JourneyArt.localized("Selesaikan iklan untuk menerima hati","Finish the ad to receive your heart")
	elif not HeartManager.rewarded_ad_provider.is_valid():
		_message.text = JourneyArt.localized("Iklan belum tersedia","Ads are not available yet")
	elif int(HeartManager.state()["rewarded_heart_ads_used_today"]) >= HeartManager.AD_CAP:
		_message.text = JourneyArt.localized("Had iklan hari ini dicapai","Daily ad limit reached")
	elif count < HeartManager.MAX_HEARTS:
		_message.text = JourneyArt.localized("Pilihan percuma","Free option")
	for button in [_ad,_one,_full]:
		for child in button.get_children():
			if child is Control and not child is ButtonArt:
				child.modulate = Color(.72,.72,.72) if button.disabled else Color.WHITE
	var rows := [_ad,_one,_full,_home]
	for index in rows.size():
		var button: Button = rows[index]
		button.anchor_left = .08
		button.anchor_right = .92
		button.anchor_top = .59+index*(.094 if _ad.visible else .125)
		button.anchor_bottom = button.anchor_top+(.087 if _ad.visible else .108)
