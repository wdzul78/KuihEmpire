class_name StoryPage
extends Resource

## One page of the story that plays before the first level of a chapter.
##
## The plan asks for a proper storyline page rather than dialogue dropped on top
## of the board, so a chapter intro is a small deck of these rather than a
## popup (Master Plan sections 7, 21 and 48).

@export var heading: String = ""
@export_multiline var lines: PackedStringArray = PackedStringArray()
## Who is talking, used for the portrait on the page.
@export var speaker: StoryBeat.Speaker = StoryBeat.Speaker.NARRATOR
## Kuih shown on the page as props.
@export var props: Array[StringName] = []
## Backdrop preset id, so the prologue can be dawn and a festival finale can glow.
@export var mood: StringName = &"stall_dawn"
## Optional chalkboard quote.
@export var sign_text: String = ""


static func make(
	p_heading: String,
	p_speaker: StoryBeat.Speaker,
	p_lines: Array[String],
	p_props: Array = [],
	p_mood: StringName = &"stall_dawn"
) -> StoryPage:
	var page := StoryPage.new()
	page.heading = p_heading
	page.speaker = p_speaker
	for line in p_lines:
		page.lines.append(String(line))
	for id in p_props:
		page.props.append(id)
	page.mood = p_mood
	return page