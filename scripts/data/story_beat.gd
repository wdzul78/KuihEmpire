class_name StoryBeat
extends Resource

## A short dialogue beat. Story lands every 3-5 levels and must never slow the
## player down (Master Plan section 21), so a beat is just a few short lines.

enum Speaker { AINA, IBU, FRIEND, RIVAL, CUSTOMER, NARRATOR }

@export var id: StringName = &""
@export var speaker: Speaker = Speaker.AINA
## Optional speaker for each line, for customer/Aina conversations.
@export var line_speakers: Array[int] = []
@export_multiline var lines: PackedStringArray = PackedStringArray()
## Optional chalkboard style quote used on the shop sign.
@export var sign_text: String = ""


static func make(
	p_id: StringName,
	p_speaker: Speaker,
	p_lines: Array[String]
) -> StoryBeat:
	var beat := StoryBeat.new()
	beat.id = p_id
	beat.speaker = p_speaker
	for line in p_lines:
		beat.lines.append(line)
	return beat
