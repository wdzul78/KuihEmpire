class_name StoryLibrary
extends RefCounted

## Page decks for the storyline screens.
##
## The Prologue plays once, before the very first stage. Chapter intros play
## before the first level of each chapter once that chapter is unlocked
## (Master Plan sections 7 and 22).

const PROLOGUE := &"prologue"
const KUCHING := &"kuching"

static var _decks: Dictionary = {}


static func pages_for(group_id: StringName) -> Array[StoryPage]:
	if _decks.is_empty():
		_build()
	var list: Array = _decks.get(group_id, [])
	var out: Array[StoryPage] = []
	for page in list:
		out.append(page)
	return out


static func has_pages(group_id: StringName) -> bool:
	if _decks.is_empty():
		_build()
	return _decks.has(group_id)


static func groups() -> Array:
	if _decks.is_empty():
		_build()
	return _decks.keys()


static func _build() -> void:
	_decks = {}

	# --- Prologue: shown once, before Stage 1 of the tutorial flow.
	_decks[PROLOGUE] = [
		StoryPage.make(
			"Gerai Keluarga, Kuching",
			StoryBeat.Speaker.AINA,
			[
				"Three generations have sold kuih from this same wooden counter.",
				"Morning is quiet. The air still smells like pandan and steam.",
				"My name is Aina. Today the stall is mine.",
			],
			[&"onde_onde", &"kuih_lapis"],
			&"stall_dawn"
		),
		StoryPage.make(
			"The Book With Empty Pages",
			StoryBeat.Speaker.AINA,
			[
				"Under the counter I found my grandmother's recipe book.",
				"Most of the pages are blank.",
				"Every kuih I serve writes a new line.",
			],
			[&"seri_muka", &"kuih_ketayap"],
			&"kuching_market"
		),
		StoryPage.make(
			"Festival Kuih Kita",
			StoryBeat.Speaker.AINA,
			[
				"At the end of the season there is a festival. Kuih Kita.",
				"To get a table there I need Festival Stamps.",
				"One tray at a time, then.",
			],
			[&"ang_ku_kueh", &"vadai"],
			&"festival"
		),
	]

	# --- Chapter intros. Only the ones we have content for are authored;
	# chapters without a deck simply start on their first level.
	_decks[KUCHING] = [
		StoryPage.make(
			"Chapter One  ·  Kuching",
			StoryBeat.Speaker.AINA,
			[
				"The morning market is the best school a kuih seller can have.",
				"Everyone knows everyone. Every order matters.",
				"Ready when you are.",
			],
			[&"onde_onde", &"vadai"],
			&"kuching_market"
		),
	]

	_decks[&"festival_finale"] = [
		StoryPage.make(
			"Festival Kuih Kita",
			StoryBeat.Speaker.AINA,
			[
				"The whole road is lined with stalls and everyone smells like coconut.",
				"This is where the season ends, and where the next one begins.",
			],
			[&"seri_muka", &"kuih_lapis", &"vadai"],
			&"festival"
		),
	]


static func label_for(group_id: StringName) -> String:
	match group_id:
		PROLOGUE:
			return "Prologue"
		KUCHING:
			return "Chapter 1  ·  Kuching"
		&"festival_finale":
			return "Festival Kuih Kita"
	return String(group_id).capitalize()