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


## Original soft bubble pops and a short glass chime for the golden match FX.
static func match(step: int) -> AudioStreamWAV:
	return match_pop(0, pow(2.0, float(mini(step,7)) / 12.0))


static func match_pop(variant: int, pitch: float = 1.0) -> AudioStreamWAV:
	var timbre := 1.0 + float(clampi(variant,0,3)) * .025
	return _make(.36, func(t: float, d: float) -> float:
		var value := 0.0
		for index in 3:
			var local := t - float(index) * .027
			if local < 0:
				continue
			var phase := TAU * (160.0 * local + 4.2 * (1.0-exp(-local*65.0))) * timbre * pitch
			var envelope := (1.0-exp(-local*1100.0)) * exp(-local*55.0)
			value += sin(phase) * envelope * (.38 - index*.065)
		for index in 2:
			var local := t - .075 - float(index)*.045
			if local < 0:
				continue
			var frequency := (1046.5 if index == 0 else 1568.0) * pitch
			var envelope := (1.0-exp(-local*300.0)) * exp(-local*22.0)
			value += (sin(local*TAU*frequency)*.17 + sin(local*TAU*frequency*2.02)*.035) * envelope
		return value * (1.0-smoothstep(d-.04,d,t))
	)


## Original ascending bell stingers for the three combo milestones.
static func combo(count: int) -> AudioStreamWAV:
	var tier := clampi(count-3,0,2)
	var semitones: Array = [[0,4,7],[0,4,7,12],[0,4,7,12,16]][tier]
	return _make(.68+tier*.12,func(t: float, _d: float) -> float:
		var value := 0.0
		for i in semitones.size():
			var local: float = t-i*.075
			if local < 0:
				continue
			var frequency := 523.25*pow(2.0,float(semitones[i])/12.0)
			var envelope := (1.0-exp(-local*180))*exp(-local*9)
			value += (sin(local*TAU*frequency)*.23+sin(local*TAU*frequency*2)*.07)*envelope
		return value
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


## Warm rising sweep for a completed match line.
static func line_clear() -> AudioStreamWAV:
	return _make(.32, func(t: float, d: float) -> float:
		var phase := TAU * (480.0 * t + 1100.0 * t * t)
		return (sin(phase) * .38 + sin(phase * 2) * .09) * sin(PI * t / d) * exp(-t * 7)
	)

## Separate voices for each special: airy cross, rounded tray pop, magic bells.
static func special_activation(kind: int) -> AudioStreamWAV:
	if kind == BoardCell.Special.ORDER:
		return _make(.8, func(t: float, _d: float) -> float:
			var value := 0.0
			for i in 6:
				var local := t - i * .075
				if local >= 0:
					var frequency := 660.0 * pow(2, float(i) / 6)
					value += (sin(local * TAU * frequency) + .22 * sin(local * TAU * frequency * 2)) * exp(-local * 8) * .18
			return value
		)
	if kind == BoardCell.Special.DULANG:
		return _make(.55, func(t: float, _d: float) -> float:
			var phase := TAU * (180 * t + 85 * (1 - exp(-t * 8)) / 8)
			return sin(phase) * exp(-t * 10) * .55 + sin(t * TAU * 1046.5) * exp(-t * 6) * .18
		)
	var rng := _noise(75)
	var smooth := [0.0]
	return _make(.52, func(t: float, d: float) -> float:
		smooth[0] = lerpf(smooth[0], rng.randf_range(-1, 1), .08)
		var env := sin(PI * t / d)
		return smooth[0] * env * .8 + sin(TAU * (450 * t + 700 * t * t)) * env * .20
	)

static func success() -> AudioStreamWAV:
	var melody := [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]
	return _make(1.7, func(t: float, _d: float) -> float:
		var value := 0.0
		for i in melody.size():
			var local := t - i * .16
			if local >= 0:
				var frequency: float = melody[i]
				value += (sin(local * TAU * frequency) + .25 * sin(local * TAU * frequency * 2)) * (1-exp(-local * 90)) * exp(-local * 4) * .19
		return value
	)

static func delivery_launch() -> AudioStreamWAV:
	return _make(.42, func(t: float, d: float) -> float:
		return sin(TAU * (380 * t + 900 * t * t)) * sin(PI * t / d) * .22
	)

static func delivery_hit() -> AudioStreamWAV:
	return _make(.3, func(t: float, _d: float) -> float:
		return (sin(TAU * 1046.5 * t) + .35 * sin(TAU * 1568 * t)) * exp(-t * 14) * .28
	)
