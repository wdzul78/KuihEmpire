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
		&"beat_30_finale", &"beat_30_done",
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
			return _lines(id, StoryBeat.Speaker.AINA, [
				"This stall has been in the family for three generations.",
				"Morning, the wooden counter still smells like pandan.",
				"Let's make the best kuih in Kuching.",
			])

		&"beat_04_tapau":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"Four in a row... and the kuih wrapped themselves in a tapau pack!",
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

		&"beat_28_rival":
			return _lines(id, StoryBeat.Speaker.RIVAL, [
				"So this is the famous stall. Hmm. Not bad, I suppose.",
				"I am opening a kuih counter next month. May the best one win.",
			], "Best Kuih in Town?")

		&"beat_30_finale":
			return _lines(id, StoryBeat.Speaker.AINA, [
				"Market rush day. Every kuih we know, all in one go.",
				"Order the trays. This is our weekend.",
			], "Weekend Market Rush")

		&"beat_30_done":
			return _lines(id, StoryBeat.Speaker.IBU, [
				"You did it. The stall is full and the queue is still here.",
				"Next stop, kuih I have not even tasted yet.",
			], "From Tradition to Empire")

	return null