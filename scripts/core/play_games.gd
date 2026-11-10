extends Node

## Google Play Games (autoload: `PlayGames`): sign-in, cloud save, achievements
## and leaderboards through the GodotPlayGameServices plugin.
##
## Everything is optional. On PC, in tests, or when the player is not signed in,
## every call does nothing and the local save stays the only save.

signal changed()

const SAVE_NAME := "kuih_empire_progress"
const SAVE_FORMAT := 1
## Seconds between cloud uploads while playing; pausing the app uploads at once.
const UPLOAD_GAP := 45.0

var available := false
var signed_in := false
var _sign_in: PlayGamesSignInClient
var _snapshots: PlayGamesSnapshotsClient
var _achievements: PlayGamesAchievementsClient
var _leaderboards: PlayGamesLeaderboardsClient
## Cloud copy has been compared with this device; uploads wait until then.
var _cloud_checked := false
var _upload_pending := false
var _upload_timer: SceneTreeTimer
var _pending_cloud: Dictionary = {}
var _layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() != "Android" or not Engine.has_singleton("GodotPlayGameServices"):
		return
	var plugin := get_node_or_null("/root/GodotPlayGameServices")
	if plugin == null or plugin.initialize() != 0:
		return
	available = true
	_sign_in = PlayGamesSignInClient.new()
	_snapshots = PlayGamesSnapshotsClient.new()
	_achievements = PlayGamesAchievementsClient.new()
	_leaderboards = PlayGamesLeaderboardsClient.new()
	for client in [_sign_in, _snapshots, _achievements, _leaderboards]:
		add_child(client)
	_sign_in.user_authenticated.connect(_authenticated)
	_snapshots.game_loaded.connect(_cloud_loaded)
	_snapshots.game_saved.connect(_cloud_saved)
	_snapshots.conflict_emitted.connect(_cloud_conflict)
	SaveManager.saved.connect(_local_saved)
	AchievementManager.achievement_unlocked.connect(_achievement_unlocked)
	GameplayEvents.stage_completed.connect(_stage_completed)
	# Play Games signs returning players in by itself; this asks for the result.
	_sign_in.is_authenticated.call_deferred()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and _upload_pending:
		_upload()

## Opens Google's sign-in sheet for a player who is not signed in yet.
func sign_in() -> void:
	if available and not signed_in:
		_sign_in.sign_in()

func show_achievements() -> void:
	if signed_in:
		_achievements.show_achievements()

func show_leaderboards() -> void:
	if signed_in and PlayGamesIds.has_leaderboards():
		_leaderboards.show_all_leaderboards()

func _authenticated(is_authenticated: bool) -> void:
	var first := is_authenticated and not signed_in
	signed_in = is_authenticated
	changed.emit()
	if not first:
		return
	_sync_achievements()
	_submit_scores()
	_snapshots.load_game(SAVE_NAME, false)

# --- Cloud save -------------------------------------------------------------

static func progress_of(save: Dictionary) -> Vector2i:
	var stage := 0
	var stars := 0
	var levels: Dictionary = save.get("levels", {})
	for key in levels:
		var record: Variant = levels[key]
		var earned := int(record.get("stars", 0)) if record is Dictionary else int(record)
		if earned > 0:
			stage = maxi(stage, int(key))
			stars += earned
	return Vector2i(stage, stars)

## True when the cloud copy is further along than this device.
static func cloud_is_ahead(cloud: Dictionary, local: Dictionary) -> bool:
	var a := progress_of(cloud)
	var b := progress_of(local)
	if a.x != b.x:
		return a.x > b.x
	return a.y > b.y

static func pack(save: Dictionary) -> PackedByteArray:
	var text := JSON.stringify({"format": SAVE_FORMAT, "data": save})
	var packed := text.to_utf8_buffer()
	var zipped := packed.compress(FileAccess.COMPRESSION_GZIP)
	# Base64 keeps every byte plain ASCII on its way through the plugin's JSON.
	return ("%d:%s" % [packed.size(), Marshalls.raw_to_base64(zipped)]).to_ascii_buffer()

static func unpack(bytes: PackedByteArray) -> Dictionary:
	var text := bytes.get_string_from_ascii()
	var split := text.find(":")
	if split <= 0:
		return {}
	var zipped := Marshalls.base64_to_raw(text.substr(split + 1))
	var raw := zipped.decompress(int(text.substr(0, split)), FileAccess.COMPRESSION_GZIP)
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not parsed is Dictionary or int(parsed.get("format", 0)) != SAVE_FORMAT or not parsed.get("data") is Dictionary:
		return {}
	return parsed["data"]

func _cloud_loaded(snapshot: PlayGamesSnapshot) -> void:
	if _cloud_checked:
		return
	var cloud := unpack(snapshot.content) if snapshot != null else {}
	if not cloud.is_empty() and cloud_is_ahead(cloud, SaveManager.data):
		_ask_restore(cloud)
		return
	_cloud_checked = true
	_upload()

func _cloud_saved(is_saved: bool, _name: String, _description: String) -> void:
	if not is_saved:
		_upload_pending = true

func _cloud_conflict(conflict: PlayGamesSnapshotConflict) -> void:
	push_warning("PlayGames: cloud save conflict %s; the next upload retries." % conflict.conflict_id)
	_upload_pending = true

func _local_saved() -> void:
	if not signed_in or not _cloud_checked:
		return
	_upload_pending = true
	if _upload_timer == null or _upload_timer.time_left <= 0.0:
		_upload_timer = get_tree().create_timer(UPLOAD_GAP)
		_upload_timer.timeout.connect(_upload_if_pending)

func _upload_if_pending() -> void:
	if _upload_pending:
		_upload()

func _upload() -> void:
	if not signed_in or not _cloud_checked:
		return
	_upload_pending = false
	var progress := progress_of(SaveManager.data)
	_snapshots.save_game(SAVE_NAME, "Stage %d · ★ %d" % [progress.x, progress.y], pack(SaveManager.data), 0, progress.x)

# --- Restore prompt ---------------------------------------------------------

func _ask_restore(cloud: Dictionary) -> void:
	_pending_cloud = cloud
	var theirs := progress_of(cloud)
	var ours := progress_of(SaveManager.data)
	_layer = CanvasLayer.new()
	_layer.name = "CloudRestore"
	_layer.layer = 120
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, .65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.cream_box())
	card.custom_minimum_size.x = root.get_viewport_rect().size.x * .88
	center.add_child(card)
	var stack := UIKit.vbox(22)
	card.add_child(stack)
	stack.add_child(UIKit.title(JourneyArt.localized("Progres Google Play", "Google Play progress"), 46))
	stack.add_child(UIKit.wrap_label(JourneyArt.localized(
		"Akaun Google Play anda ada progres yang lebih jauh.\n\nGoogle Play: Stage %d · ★ %d\nTelefon ini: Stage %d · ★ %d\n\nGuna progres Google Play?",
		"Your Google Play account has further progress.\n\nGoogle Play: Stage %d · ★ %d\nThis phone: Stage %d · ★ %d\n\nUse the Google Play progress?"
	) % [theirs.x, theirs.y, ours.x, ours.y], 36))
	var use_cloud := GameButton.create(JourneyArt.localized("Guna progres Google Play", "Use Google Play progress"))
	use_cloud.name = "UseCloudSave"
	use_cloud.pressed.connect(_restore_cloud, CONNECT_DEFERRED)
	stack.add_child(use_cloud)
	stack.add_child(UIKit.wrap_label(JourneyArt.localized(
		"Jika anda kekalkan telefon ini, progres Google Play akan diganti.",
		"If you keep this phone's progress, the Google Play progress will be replaced."
	), 28))
	var keep := GameButton.create(JourneyArt.localized("Kekalkan telefon ini", "Keep this phone"), "secondary")
	keep.name = "KeepLocalSave"
	keep.pressed.connect(_keep_local, CONNECT_DEFERRED)
	stack.add_child(keep)

func _close_prompt() -> void:
	if _layer != null:
		_layer.queue_free()
		_layer = null
	_pending_cloud = {}
	_cloud_checked = true

func _restore_cloud() -> void:
	var cloud := _pending_cloud
	_close_prompt()
	if cloud.is_empty() or not SaveManager.restore(cloud):
		return
	AchievementManager.refresh()
	AudioManager.apply_settings(SaveManager.data.get("settings", {}))
	SceneManager.goto(SceneManager.HOME)

func _keep_local() -> void:
	_close_prompt()
	_upload()

# --- Achievements and leaderboards ------------------------------------------

func _achievement_unlocked(definition: AchievementDefinition) -> void:
	var id := PlayGamesIds.achievement(definition.id)
	if signed_in and not id.is_empty():
		_achievements.unlock_achievement(id)

## Unlocks on Play Games whatever was earned before signing in (repeats are harmless).
func _sync_achievements() -> void:
	for definition in AchievementManager.definitions:
		var id := PlayGamesIds.achievement(definition.id)
		if not id.is_empty() and AchievementManager.state(definition.id).get("unlocked", false):
			_achievements.unlock_achievement(id)

func _stage_completed(_id: int, _stars: int, _score: int, _used_booster: bool) -> void:
	_submit_scores.call_deferred()

func _submit_scores() -> void:
	if not signed_in:
		return
	if not PlayGamesIds.LEADERBOARD_STARS.is_empty():
		_leaderboards.submit_score(PlayGamesIds.LEADERBOARD_STARS, ProgressionManager.total_stars())
	if not PlayGamesIds.LEADERBOARD_STAGE.is_empty():
		_leaderboards.submit_score(PlayGamesIds.LEADERBOARD_STAGE, ProgressionManager.highest_cleared())
