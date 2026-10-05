class_name BeatLibrary
extends RefCounted

## Short in-level dialogue beats keyed by id (Master Plan sections 7, 8 and 21).
##
## Deliberately tiny: two to four lines each, so story motivates without ever
## slowing the puzzle down. Beats land every three to five levels.
##
## Distinct from [StoryLibrary], which holds the full-screen storyline pages that
## play before a chapter. This one speaks over the stall.

static var _cache: Dictionary = {}


static func get_beat(id: StringName) -> StoryBeat:
	if id == &"":
		return null
	if _cache.has(id):
		return _cache[id]
	var beat := _build(id)
	if beat != null:
		_cache[id] = beat
	return beat


static func all_ids() -> Array:
	return [
		&"beat_01_open", &"beat_04_tapau", &"beat_07_leaf", &"beat_10_rush",
		&"beat_15_book", &"beat_20_weekend", &"beat_20_done", &"beat_28_rival",
		&"beat_30_finale", &"beat_30_done", &"beat_21_steamer", &"beat_12_special_order",
	]


static func _lines(id: StringName, speaker: StoryBeat.Speaker, text: Array, sign: String = "") -> StoryBeat:
	var beat := StoryBeat.new()
	beat.id = id
	beat.speaker = speaker
	for line in text:
		beat.lines.append(String(line))
	beat.sign_text = sign
	return beat


static func _build(id: StringName) -> StoryBeat:
	match id:

		&"beat_01_open":
			var beat := _lines(id, StoryBeat.Speaker.AINA, [
				"Morning, Aina! One kuih for the ride home, please.",
				"Morning! Let's make your kuih fresh. Match three of the same kind to fill the order.",
			])
			beat.line_speakers = [StoryBeat.Speaker.CUSTOMER, StoryBeat.Speaker.AINA]
			return beat

		&"beat_04_tapau":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"Four in a row... and a Tapau Pack appeared!",
				"Send it across the whole row and everything flies.",
			])

		&"beat_07_leaf":
			return _lines(id, StoryBeat.Speaker.IBU, [
				"Daun pisang, Aina. Cover the kuih so they stay fresh.",
				"Match right beside the leaf and the wind will lift it off.",
			])

		&"beat_10_rush":
			return _lines(id, StoryBeat.Speaker.IBU, [
				"Morning rush! Every table wants something sweet.",
				"Take a breath. One tray at a time.",
			])

		&"beat_12_special_order":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"Match five in a straight line to make a Special Order.",
				"Swap it with a kuih to collect every kuih of that kind on the board!",
			])

		&"beat_15_book":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"There's an old recipe book under the counter.",
				"Most of the pages are still empty.",
				"Every kuih I serve writes a new line.",
			])

		&"beat_20_weekend":
			return _lines(id, StoryBeat.Speaker.FRIEND, [
				"Aina! The weekend market crowd is already queueing.",
				"I put the poster up on my phone. You are going viral, sort of.",
			])

		&"beat_20_done":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"We cleared the whole morning.",
				"Nenek Halimah said the onde-onde was the softest she has had.",
			])

		&"beat_21_steamer":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"These kuih are still covered by steamer lids. Match beside a basket to open it.",
				"Once the lid lifts, you can move and match the kuih inside. Later, stronger lids need two hits.",
			])

		&"beat_28_rival":
			return _lines(id, StoryBeat.Speaker.RIVAL, [
				"So this is the famous stall. Hmm. Not bad, I suppose.",
				"I am opening a kuih counter next month. May the best one win.",
			], "Best Kuih in Town?")

		&"beat_30_finale":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"Our neighbours have ordered kuih for the whole community!",
				"Let's serve them together and bring our family stall to life.",
			], "Big Community Order")

		&"beat_30_done":
			return _lines(id, StoryBeat.Speaker.IBU, [
				"You did it. The stall is full and the queue is still here.",
				"Our next destination is the school canteen. A new story awaits!",
			], "From Tradition to Empire")

	return null
