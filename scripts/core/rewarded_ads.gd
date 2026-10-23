extends Node
## Test-only AdMob integration. Production IDs must be configured separately.
signal finished(earned: bool)

const TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
var _sdk: Node
var _ad_id := ""
var _showing := false
var _earned := false
var _loading := false
var _load_generation := 0
var _presented_id := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("Android") and Engine.has_singleton("AdmobPlugin"):
		var sdk := Admob.new()
		sdk.is_real = false
		sdk.android_debug_application_id = TEST_APP_ID
		sdk.android_debug_rewarded_id = TEST_REWARDED_ID
		attach_sdk(sdk)
		sdk.initialize()

func attach_sdk(sdk: Node) -> void:
	_sdk = sdk
	_sdk.initialization_completed.connect(func(_status: Variant) -> void: _load())
	_sdk.rewarded_ad_loaded.connect(_loaded)
	_sdk.rewarded_ad_failed_to_load.connect(_load_failed)
	_sdk.rewarded_ad_user_earned_reward.connect(_reward)
	_sdk.rewarded_ad_dismissed_full_screen_content.connect(_dismissed)
	_sdk.rewarded_ad_failed_to_show_full_screen_content.connect(_show_failed)
	add_child(_sdk)

func _load() -> void:
	if _loading or _showing or not _ad_id.is_empty():
		return
	_loading = true
	_load_generation += 1
	var generation := _load_generation
	_sdk.load_rewarded_ad()
	get_tree().create_timer(30.0).timeout.connect(func() -> void:
		if _loading and generation == _load_generation:
			_load_failed(null, null))

func _loaded(info: Variant, _response: Variant) -> void:
	_loading = false
	_ad_id = info.get_ad_id()
	HeartManager.rewarded_ad_provider = watch
	HeartManager.changed.emit()

func _load_failed(_info: Variant, _error: Variant) -> void:
	_loading = false
	HeartManager.changed.emit()
	get_tree().create_timer(30.0).timeout.connect(_load)

func watch() -> bool:
	if _sdk == null or _showing or _ad_id.is_empty():
		return false
	_showing = true
	_earned = false
	var id := _ad_id
	_presented_id = id
	_ad_id = ""
	HeartManager.rewarded_ad_provider = Callable()
	_sdk.show_rewarded_ad.call_deferred(id)
	return await finished

func _reward(info: Variant, _reward_data: Variant) -> void:
	if _showing and info.get_ad_id() == _presented_id:
		_earned = true

func _dismissed(info: Variant) -> void:
	if _showing and info.get_ad_id() == _presented_id:
		_finish(_earned)

func _show_failed(info: Variant, _error: Variant) -> void:
	if _showing and info.get_ad_id() == _presented_id:
		_finish(false)

func _finish(earned: bool) -> void:
	_showing = false
	_presented_id = ""
	finished.emit(earned)
	_load.call_deferred()
