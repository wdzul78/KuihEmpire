extends Node

## Audio hub (autoload: `AudioManager`).
##
## CC0 recordings and custom layered SFX live in audio/sfx. SfxSynth remains a
## fallback. Two music voices crossfade between the menu and puzzle themes.
##
## Settings live in the save file: `settings.sfx` and `settings.music`.

const SFX_VOICES := 10
const MUSIC_FADE := 1.4

enum Sfx {
	TAP,
	SWAP,
	INVALID,
	MATCH,
	SPECIAL,
	SERVE,
	FAIL,
	REWARD,
	UNLOCK,
	PACK,
	DROP,
	LINE_CLEAR,
	TAPAU_BLAST,
	TRAY_BLAST,
	ORDER_BURST,
	SUCCESS,
	HANTAR_CREATE,
	HANTAR_LAUNCH,
	HANTAR_HIT,
	CROSS_BLAST,
	SPATULA,
	SHUFFLE,
	HANTAR_EXIT,
}

const MENU_MUSIC := "res://audio/music/menu.ogg"
const GAMEPLAY_MUSIC := "res://audio/music/cozy_puzzle_gameplay.ogg"
const FILE_SFX := {
	Sfx.TAP: "tap", Sfx.SWAP: "swap", Sfx.INVALID: "invalid_connect_v1/puzzle_tile_adjust_connect_05",
	Sfx.MATCH: "match_jump_v1/little_jump_up_01", Sfx.SPECIAL: "v2/special_create", Sfx.SERVE: "v2/serve",
	Sfx.FAIL: "fail", Sfx.REWARD: "v2/reward", Sfx.UNLOCK: "v2/unlock",
	Sfx.PACK: "pack", Sfx.DROP: "drop", Sfx.LINE_CLEAR: "v2/line_clear",
	Sfx.TAPAU_BLAST: "v2/directional_tapau", Sfx.TRAY_BLAST: "v2/tray_burst",
	Sfx.ORDER_BURST: "v2/order_burst", Sfx.SUCCESS: "win_pack_v1/big_game_win_pack1_01",
	Sfx.HANTAR_CREATE: "v2/hantar_create", Sfx.HANTAR_LAUNCH: "delivery_rotor_v1/rotor_launch",
	Sfx.HANTAR_HIT: "delivery_rotor_v1/claw_pickup", Sfx.CROSS_BLAST: "v2/cross_tapau",
	Sfx.HANTAR_EXIT: "delivery_rotor_v1/rotor_exit",
	Sfx.SPATULA: "v2/spatula", Sfx.SHUFFLE: "v2/shuffle",
}

static var instance: AudioManager

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _match_variants: Array[AudioStreamWAV] = []
var _last_match_variant := -1
const CASCADE_NOTES := [0, 2, 4, 7, 9, 12, 14, 16]
var _next_voice: int = 0
var _music_player: AudioStreamPlayer
var _music_other: AudioStreamPlayer
var _music_tween: Tween
var _music_path := ""
var _music_ducked := false
var _suspended := false
var _music_gain := -18.0
var _cache: Dictionary = {}
var sfx_enabled: bool = true
var music_enabled: bool = true


func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS

	_streams[Sfx.TAP] = SfxSynth.tap()
	_streams[Sfx.SWAP] = SfxSynth.swap()
	_streams[Sfx.INVALID] = SfxSynth.invalid()
	_streams[Sfx.SPECIAL] = SfxSynth.special()
	_streams[Sfx.SERVE] = SfxSynth.serve()
	_streams[Sfx.FAIL] = SfxSynth.fail()
	_streams[Sfx.REWARD] = SfxSynth.reward()
	_streams[Sfx.UNLOCK] = SfxSynth.unlock()
	_streams[Sfx.PACK] = SfxSynth.pack()
	_streams[Sfx.DROP] = SfxSynth.drop()
	_streams[Sfx.LINE_CLEAR] = SfxSynth.line_clear()
	_streams[Sfx.TAPAU_BLAST] = SfxSynth.special_activation(BoardCell.Special.TAPAU)
	_streams[Sfx.TRAY_BLAST] = SfxSynth.special_activation(BoardCell.Special.DULANG)
	_streams[Sfx.ORDER_BURST] = SfxSynth.special_activation(BoardCell.Special.ORDER)
	_streams[Sfx.SUCCESS] = SfxSynth.success()
	_streams[Sfx.HANTAR_CREATE] = SfxSynth.pack()
	_streams[Sfx.HANTAR_LAUNCH] = SfxSynth.delivery_launch()
	_streams[Sfx.HANTAR_HIT] = SfxSynth.delivery_hit()
	_streams[Sfx.HANTAR_EXIT] = SfxSynth.delivery_launch()
	for which in FILE_SFX:
		var path := "res://audio/sfx/%s.wav" % FILE_SFX[which]
		if ResourceLoader.exists(path):
			_streams[which] = load(path)

	if _streams.has(Sfx.MATCH):
		_match_variants.append(_streams[Sfx.MATCH] as AudioStreamWAV)

	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_voices.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.name = "MusicCurrent"
	_music_player.volume_db = -18.0
	add_child(_music_player)
	_music_other = AudioStreamPlayer.new()
	_music_other.name = "MusicOutgoing"
	_music_other.volume_db = -60.0
	add_child(_music_other)


func apply_settings(settings: Dictionary) -> void:
	sfx_enabled = bool(settings.get("sfx", true))
	music_enabled = bool(settings.get("music", true))
	_music_player.stream_paused = not music_enabled or _suspended
	_music_other.stream_paused = not music_enabled or _suspended


func play(which: Sfx, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_enabled or _suspended:
		return
	var stream: AudioStream = _streams.get(which, null)
	if stream == null:
		return
	var player := _take_voice()
	player.stream = stream
	player.pitch_scale = clampf(pitch + randf_range(-0.03, 0.03), 0.4, 2.4)
	player.volume_db = volume_db
	player.play()


## Cascades pitch upward so long chains feel like a streak.
func play_match(step: int) -> void:
	var pitch := pow(2.0, float(CASCADE_NOTES[clampi(step,0,7)]) / 12.0)
	if not _match_variants.is_empty():
		var index := randi_range(0,_match_variants.size()-1)
		if index == _last_match_variant and _match_variants.size() > 1:
			index = (index+1) % _match_variants.size()
		_last_match_variant = index
		play_stream(_match_variants[index],pitch,-7.0)
		return
	if _streams.has(Sfx.MATCH):
		play(Sfx.MATCH, pitch, -7.0)
		return
	var key := "match_%d" % mini(step, 7)
	var stream: AudioStream = _cache.get(key, null)
	if stream == null:
		stream = SfxSynth.match(step)
		_cache[key] = stream
	play_stream(stream, 1.0, -3.0)


func play_combo(count: int) -> void:
	if count not in [3,4,5] or not sfx_enabled or _suspended:
		return
	var key := "combo_praise_%d" % count
	if not _cache.has(key):
		_cache[key] = SfxSynth.combo(count)
	play_stream(_cache[key],1.0,-5.0)


func play_stream(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_enabled or _suspended or stream == null:
		return
	var player := _take_voice()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func play_music(path: String) -> void:
	if path == _music_path and _music_player.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var resource: Resource = load(path)
	var stream := resource as AudioStream
	if stream != null:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		if _music_tween != null and _music_tween.is_valid():
			_music_tween.kill()
		var outgoing := _music_player
		_music_player = _music_other
		_music_other = outgoing
		_music_player.stop()
		_music_player.stream = stream
		_music_path = path
		_music_gain = -20.0 if path == GAMEPLAY_MUSIC else -18.0
		_music_ducked = false
		_music_player.volume_db = -60.0
		_music_player.play()
		_music_player.stream_paused = not music_enabled or _suspended
		_music_tween = create_tween().set_parallel(true)
		_music_tween.tween_property(_music_player, "volume_db", _music_gain, MUSIC_FADE)
		_music_tween.tween_property(outgoing, "volume_db", -60.0, MUSIC_FADE)
		_music_tween.chain().tween_callback(outgoing.stop)


func set_music_ducked(ducked: bool) -> void:
	if ducked == _music_ducked:
		return
	_music_ducked = ducked
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_other.stop()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", _music_gain - (8.0 if ducked else 0.0), .3)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_suspended = true
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_suspended = false
	else:
		return
	if not is_instance_valid(_music_player):
		return
	_music_player.stream_paused = _suspended or not music_enabled
	_music_other.stream_paused = _suspended or not music_enabled
	if _suspended:
		for voice in _voices:
			voice.stop()


func stop_music() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_player.stop()
	_music_other.stop()
	_music_player.stream = null
	_music_other.stream = null
	_music_path = ""


func _exit_tree() -> void:
	stop_music()
	_music_player.stream = null
	_music_other.stream = null
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_match_variants.clear()
	_streams.clear()
	_cache.clear()


func _take_voice() -> AudioStreamPlayer:
	if _voices.is_empty():
		return _music_player
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	return player


## Haptics are best effort and a no-op on desktop.
func haptic(duration_ms: int = 18, amplitude: float = 0.4) -> void:
	if not sfx_enabled:
		return
	if not bool(SaveManager.get_setting("haptics", true)):
		return
	Input.vibrate_handheld(duration_ms, amplitude)


func play_special(kind: int) -> void:
	var sound := Sfx.TAPAU_BLAST
	if kind == BoardCell.Special.DULANG:
		sound = Sfx.TRAY_BLAST
	elif kind == BoardCell.Special.ORDER:
		sound = Sfx.ORDER_BURST
	play(sound, 1.0, -4)
