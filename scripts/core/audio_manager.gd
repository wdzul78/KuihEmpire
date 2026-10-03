extends Node

## Audio hub (autoload: `AudioManager`).
##
## All SFX are synthesised at boot by [SfxSynth] so the game sounds alive without
## shipping any audio files. Music files can be dropped into
## `res://audio/music/` later; missing files are simply skipped.
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
}

static var instance: AudioManager

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_player: AudioStreamPlayer
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

	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_voices.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	_music_player.volume_db = -8.0
	add_child(_music_player)


func apply_settings(settings: Dictionary) -> void:
	sfx_enabled = bool(settings.get("sfx", true))
	music_enabled = bool(settings.get("music", true))
	if not music_enabled:
		stop_music()
	elif _music_player.stream != null and not _music_player.playing:
		_music_player.play()


func play(which: Sfx, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_enabled:
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
	var key := "match_%d" % mini(step, 7)
	var stream: AudioStream = _cache.get(key, null)
	if stream == null:
		stream = SfxSynth.match(step)
		_cache[key] = stream
	play_stream(stream, 1.0, -3.0)


func play_stream(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_enabled or stream == null:
		return
	var player := _take_voice()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func play_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var resource: Resource = load(path)
	var stream := resource as AudioStream
	if stream != null:
		_music_player.stream = stream
		if music_enabled:
			_music_player.play()


func stop_music() -> void:
	_music_player.stop()


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
