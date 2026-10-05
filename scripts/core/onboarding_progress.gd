class_name OnboardingProgress
extends RefCounted

const GIFT_COINS := 500
const FREE_PLAY_SECONDS := 3600
const RESTORE_COST := 300

static func state() -> Dictionary:
	return SaveManager.data.onboarding

static func pending() -> bool:
	return ProgressionManager.tutorial_done() and not state().shop_intro_done

static func restored() -> bool:
	return state().restored

static func claim_gift() -> bool:
	if not ProgressionManager.tutorial_done() or state().gift_claimed:
		return false
	state().gift_claimed = true
	EconomyManager.add_coins(GIFT_COINS)
	HeartManager.start_free_play(FREE_PLAY_SECONDS)
	SaveManager.save_game()
	return true

static func restore_stall() -> bool:
	if restored() or not EconomyManager.spend_coins(RESTORE_COST):
		return false
	state().restored = true
	SaveManager.save_game()
	LocationManager.location_state_changed.emit(&"family_stall")
	AudioManager.play(AudioManager.Sfx.UNLOCK)
	return true

static func finish_intro() -> void:
	state().shop_intro_done = true
	SaveManager.save_game()
