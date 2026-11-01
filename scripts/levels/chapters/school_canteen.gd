class_name SchoolCanteenChapter
extends StageChapter

## Stages 31-60 at the School Canteen. No stage is authored yet, so the chapter
## is empty and the game still ends at stage 30. Raise `LAST_STAGE` as stages
## are added; `LevelLibrary.count()` and the location's `playable` flag follow.

const FIRST_STAGE := 31
const LAST_STAGE := 30

const TITLES_MS := {}


static func build(_level_id: int) -> LevelDefinition:
	return null
