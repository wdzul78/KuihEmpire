class_name SfxSynth
extends RefCounted

## Generates every game sound from scratch at boot.
##
## The project ships no audio files yet, so short procedural tones keep the game
## feel alive (swap, match, serve, reward) without blocking on an art/audio drop
## and without any licensing questions (Master Plan section 53).

const RATE := 22050
const PEAK := 30000


static func _make(duration: float, gen: Callable) -> AudioStreamWAV:
	var count := maxi(1, int(duration * float(RATE)))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / float(RATE)
		var v := clampf(float(gen.call(t, duration)), -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * float(PEAK)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream


static func _noise(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Soft woody tick for taps and menu presses.
static func tap() -> AudioStreamWAV:
	return _make(0.08, func(t: float, _d: float) -> float:
		return (sin(t * TAU * 720.0) * 0.6 + sin(t * TAU * 1440.0) * 0.2) * exp(-t * 52.0)
	)


## Quick airy whoosh for a tile swap.
static func swap() -> AudioStreamWAV:
	var rng := _noise(11)
	var buf: Array[float] = []
	for i in 64:
		buf.append(rng.randf_range(-1.0, 1.0))
	return _make(0.16, func(t: float, d: float) -> float:
		var idx := clampi(int(t / d * 63.0), 0, 63)
		var env := sin(PI * (t / d))
		return buf[idx] * env * 0.35 + sin(t * TAU * 320.0) * env * 0.15
	)


## Low bump for an illegal swap.
static func invalid() -> AudioStreamWAV:
	return _make(0.20, func(t: float, _d: float) -> float:
		var env := exp(-t * 16.0)
		return (sin(t * TAU * 150.0) * 0.7 + sin(t * TAU * 96.0) * 0.3) * env
	)


## Bright ping that climbs a little with every cascade step.
static func match(step: int) -> AudioStreamWAV:
	var semis := mini(step, 8) * 2
	var freq := 660.0 * pow(2.0, float(semis) / 12.0)
	return _make(0.24, func(t: float, _d: float) -> float:
		var env := exp(-t * 12.0)
		return (
			sin(t * TAU * freq) * 0.55
			+ sin(t * TAU * freq * 2.0) * 0.22
			+ sin(t * TAU * freq * 3.0) * 0.08
		) * env
	)


## Shimmer for creating or firing a special tile.
static func special() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	return _make(0.55, func(t: float, _d: float) -> float:
		var value := 0.0
		for i in notes.size():
			var start := float(i) * 0.08
			if t < start:
				continue
			var local := t - start
			value += sin(local * TAU * float(notes[i])) * exp(-local * 9.0) * 0.3
		return value
	)


## Bell + happy chime when an order is served.
static func serve() -> AudioStreamWAV:
	var notes := [659.25, 830.61, 987.77, 1318.5]
	return _make(0.85, func(t: float, _d: float) -> float:
		var value := 0.0
		for i in notes.size():
			var start := float(i) * 0.10
			if t < start:
				continue
			var local := t - start
			value += sin(local * TAU * float(notes[i])) * exp(-local * 5.0) * 0.26
		value += sin(t * TAU * 2200.0) * exp(-t * 26.0) * 0.10
		return value
	)


## Gentle descending "so close" sting. Never harsh - cozy games do not punish.
static func fail() -> AudioStreamWAV:
	var notes := [523.25, 440.0, 349.23]
	return _make(0.90, func(t: float, _d: float) -> float:
		var value := 0.0
		for i in notes.size():
			var start := float(i) * 0.18
			if t < start:
				continue
			var local := t - start
			value += sin(local * TAU * float(notes[i])) * exp(-local * 4.0) * 0.24
		return value
	)


## Coin and fanfare for the result screen.
static func reward() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	return _make(1.20, func(t: float, _d: float) -> float:
		var value := 0.0
		for i in notes.size():
			var start := float(i) * 0.11
			if t < start:
				continue
			var local := t - start
			value += sin(local * TAU * float(notes[i])) * exp(-local * 3.2) * 0.22
		return value
	)


## Rising shimmer for recipe / chapter unlocks.
static func unlock() -> AudioStreamWAV:
	return _make(1.10, func(t: float, d: float) -> float:
		var sweep := 420.0 + 620.0 * (t / d)
		var value := sin(t * TAU * sweep) * 0.28
		value += sin(t * TAU * sweep * 1.5) * 0.14
		return value * exp(-t * 1.8)
	)


## Paper rustle for packing kuih into a box.
static func pack() -> AudioStreamWAV:
	var rng := _noise(29)
	var buf: Array[float] = []
	for i in 48:
		buf.append(rng.randf_range(-1.0, 1.0))
	return _make(0.28, func(t: float, d: float) -> float:
		var idx := clampi(int(t / d * 47.0), 0, 47)
		var env := sin(PI * pow(t / d, 0.7))
		return buf[idx] * env * 0.30
	)


## Soft wooden clack when a kuih lands in a tray.
static func drop() -> AudioStreamWAV:
	return _make(0.12, func(t: float, _d: float) -> float:
		return (sin(t * TAU * 240.0) * 0.5 + sin(t * TAU * 480.0) * 0.2) * exp(-t * 34.0)
	)
