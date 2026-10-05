extends Node

signal changed
signal free_play_started(seconds: int)

const MAX_HEARTS := 5
const REFILL_SECONDS := 1800
const ONE_PRICE := 500
const FULL_PRICE := 1800
const AD_CAP := 3
var test_now := -1
## Set by a real rewarded-ad adapter. It must return true only after completion.
var rewarded_ad_provider: Callable
var _ad_busy := false
var _tick := 0.0

func now() -> int:
	return test_now if test_now >= 0 else int(Time.get_unix_time_from_system())

func state() -> Dictionary:
	return SaveManager.data["hearts"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()

func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		refresh()
		changed.emit()

func _save() -> void:
	SaveManager.mark_dirty()
	changed.emit()

func refresh() -> void:
	var h := state()
	var timestamp := now()
	var updated := false
	var day := Time.get_date_string_from_unix_time(timestamp)
	if h["rewarded_heart_ads_reset_date"] != day:
		h["rewarded_heart_ads_reset_date"] = day
		h["rewarded_heart_ads_used_today"] = 0
		updated = true
	if int(h["current_hearts"]) >= MAX_HEARTS:
		if int(h["last_heart_refill_timestamp"]) != 0:
			h["last_heart_refill_timestamp"] = 0
			updated = true
	else:
		var start := int(h["last_heart_refill_timestamp"])
		if start <= 0 or start > timestamp:
			h["last_heart_refill_timestamp"] = timestamp
			updated = true
		else:
			var count := int((timestamp - start) / REFILL_SECONDS)
			if count > 0:
				h["current_hearts"] = mini(MAX_HEARTS, int(h["current_hearts"]) + count)
				h["last_heart_refill_timestamp"] = 0 if int(h["current_hearts"]) == MAX_HEARTS else start + count * REFILL_SECONDS
				updated = true
	if updated:
		_save()

func current() -> int:
	refresh()
	return int(state()["current_hearts"])

func get_free_play_remaining() -> int:
	return maxi(0, int(state()["free_play_end_timestamp"]) - now())

func is_free_play_active() -> bool:
	return get_free_play_remaining() > 0

func get_next_refill_remaining() -> int:
	refresh()
	if int(state()["current_hearts"]) == MAX_HEARTS:
		return 0
	return maxi(0, REFILL_SECONDS - (now() - int(state()["last_heart_refill_timestamp"])))

func can_start_stage(tutorial: bool = false) -> bool:
	return tutorial or is_free_play_active() or current() > 0

func consume_on_failure(tutorial: bool = false) -> void:
	if tutorial:
		return
	refresh()
	var h := state()
	h["win_streak"] = 0
	if not is_free_play_active() and int(h["current_hearts"]) > 0:
		if int(h["current_hearts"]) == MAX_HEARTS:
			h["last_heart_refill_timestamp"] = now()
		h["current_hearts"] = int(h["current_hearts"]) - 1
		h["hearts_spent"] = int(h["hearts_spent"]) + 1
	_save()

func add_heart(amount: int = 1) -> void:
	refresh()
	state()["current_hearts"] = clampi(int(state()["current_hearts"]) + maxi(0, amount), 0, MAX_HEARTS)
	if int(state()["current_hearts"]) == MAX_HEARTS:
		state()["last_heart_refill_timestamp"] = 0
	_save()

func full_refill() -> void:
	add_heart(MAX_HEARTS)

func purchase_refill(full: bool = false) -> bool:
	if current() == MAX_HEARTS:
		return false
	var price := FULL_PRICE if full else ONE_PRICE
	if not EconomyManager.spend_coins(price):
		return false
	add_heart(MAX_HEARTS if full else 1)
	state()["coins_spent"] = int(state()["coins_spent"]) + price
	_save()
	return true

func start_free_play(seconds: int) -> void:
	if seconds <= 0:
		return
	state()["free_play_end_timestamp"] = maxi(int(state()["free_play_end_timestamp"]), now() + seconds)
	_save()
	free_play_started.emit(seconds)

func reward_win(stage: int, tutorial: bool = false) -> int:
	if tutorial:
		return 0
	var h := state()
	h["win_streak"] = int(h["win_streak"]) + 1
	var bonus := 0
	if int(h["win_streak"]) >= 3:
		bonus = 900
		h["win_streak"] = 0
	if stage in [10, 20, 30] and not h["milestones"].has(str(stage)):
		h["milestones"].append(str(stage))
		bonus = 1800
	if bonus > 0:
		start_free_play(bonus)
	_save()
	return bonus

func can_watch_ad() -> bool:
	refresh()
	return rewarded_ad_provider.is_valid() and not _ad_busy and current() < MAX_HEARTS and int(state()["rewarded_heart_ads_used_today"]) < AD_CAP

func watch_ad() -> bool:
	if not can_watch_ad():
		return false
	var completed := await request_rewarded_ad()
	if not completed:
		return false
	refresh()
	if int(state()["rewarded_heart_ads_used_today"]) >= AD_CAP:
		return false
	state()["rewarded_heart_ads_used_today"] = int(state()["rewarded_heart_ads_used_today"]) + 1
	add_heart()
	return true

func request_rewarded_ad() -> bool:
	if _ad_busy or not rewarded_ad_provider.is_valid():
		return false
	_ad_busy = true
	var completed: Variant = await rewarded_ad_provider.call()
	_ad_busy = false
	return typeof(completed) == TYPE_BOOL and completed == true

func time_text(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]
