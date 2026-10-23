extends Node

class Info extends RefCounted:
	var id: String
	func _init(value: String) -> void: id = value
	func get_ad_id() -> String: return id

class FakeSdk extends Node:
	signal initialization_completed(status: Variant)
	signal rewarded_ad_loaded(info: Variant, response: Variant)
	signal rewarded_ad_failed_to_load(info: Variant, error: Variant)
	signal rewarded_ad_user_earned_reward(info: Variant, reward: Variant)
	signal rewarded_ad_dismissed_full_screen_content(info: Variant)
	signal rewarded_ad_failed_to_show_full_screen_content(info: Variant, error: Variant)
	var loads := 0
	var shows := 0
	var initialized := false
	func initialize() -> void:
		initialized = true
		initialization_completed.emit(null)
	func load_rewarded_ad() -> void: loads += 1
	func show_rewarded_ad(_id: String) -> void: shows += 1

var result := false
var completions := 0

func request() -> void:
	result = await HeartManager.watch_ad()
	completions += 1

func frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	SaveManager.save_path = "user://rewarded_ads_test.json"
	SaveManager.reset()
	HeartManager.test_now = 1000000
	HeartManager.state()["current_hearts"] = 0
	HeartManager.state()["last_heart_refill_timestamp"] = HeartManager.now()
	var sdk := FakeSdk.new()
	RewardedAds.initialize_sdk(sdk)
	assert(sdk.initialized)
	assert(sdk.loads == 1 and not HeartManager.can_watch_ad())
	sdk.rewarded_ad_failed_to_load.emit(null, null)
	assert(not HeartManager.can_watch_ad())
	RewardedAds._load()
	sdk.rewarded_ad_loaded.emit(Info.new("first"), null)
	assert(HeartManager.can_watch_ad())
	request()
	assert(not await HeartManager.watch_ad())
	await frame()
	assert(sdk.shows == 1)
	sdk.rewarded_ad_user_earned_reward.emit(Info.new("stale"), null)
	sdk.rewarded_ad_dismissed_full_screen_content.emit(Info.new("first"))
	await frame()
	assert(not result and HeartManager.current() == 0 and completions == 1)
	sdk.rewarded_ad_loaded.emit(Info.new("second"), null)
	request()
	await frame()
	sdk.rewarded_ad_user_earned_reward.emit(Info.new("second"), null)
	sdk.rewarded_ad_user_earned_reward.emit(Info.new("second"), null)
	assert(HeartManager.current() == 0)
	sdk.rewarded_ad_dismissed_full_screen_content.emit(Info.new("second"))
	await frame()
	assert(result and HeartManager.current() == 1 and completions == 2)
	assert(int(HeartManager.state()["rewarded_heart_ads_used_today"]) == 1)
	sdk.rewarded_ad_loaded.emit(Info.new("third"), null)
	request()
	await frame()
	sdk.rewarded_ad_failed_to_show_full_screen_content.emit(Info.new("third"), null)
	await frame()
	assert(not result and HeartManager.current() == 1 and completions == 3)
	print("PASS AdMob adapter: loading/failure, cancellation, stale callback, duplicate reward/tap, earned reward and show failure")
	get_tree().quit()
