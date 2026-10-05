class_name TutorialStepData
extends Resource

## One coaching beat inside a tutorial stage.
##
## Intro steps wait for a dialogue tap. Scripted special steps preserve their
## layout for the highlighted swap; other lessons allow normal exploration.

enum Gate {
	## Tap to continue. Used for the setup line before the actual lesson.
	INTRO,
	## Wait for any successful swap.
	SWAP_ANY,
	## Wait for a swap along a column (up or down).
	SWAP_VERTICAL,
	## Wait for a swap along a row (left or right).
	SWAP_HORIZONTAL,
	## Wait for a match-4 that creates a Tapau Pack.
	CREATED_TAPAU,
	## Wait for an L or T shape that creates a Dulang.
	CREATED_DULANG,
	## Wait until [member gate_value] obstacles have been opened.
	BLOCKER_OPENED,
	## Wait until [member gate_value] matching kuih have been collected.
	COLLECTED,
	## Wait for the customer to be served.
	SERVED,
	## Swap the created special with a neighbour and watch the completed effect.
	ACTIVATED_SPECIAL,
	CREATED_HANTAR,
	CREATED_VERTICAL,
	ACTIVATED_CROSS,
}

@export var title: String = ""
@export_multiline var body: String = ""
@export var gate: Gate = Gate.INTRO
@export var gate_value: int = 0
## Cells to point at while the step is active. Empty means "find it yourself,
## the coach will offer a hint if the player stalls".
@export var highlight: Array[Vector2i] = []
## The move the coach nudges towards once the player has been idle a while.
@export var nudge_gesture: String = ""


static func make(
	p_title: String,
	p_body: String,
	p_gate: Gate = Gate.INTRO,
	p_gate_value: int = 0,
	p_nudge: String = ""
) -> TutorialStepData:
	var step := TutorialStepData.new()
	step.title = p_title
	step.body = p_body
	step.gate = p_gate
	step.gate_value = p_gate_value
	step.nudge_gesture = p_nudge
	return step


static func make_here(
	p_title: String,
	p_body: String,
	p_gate: Gate,
	p_cells: Array[Vector2i],
	p_nudge: String = ""
) -> TutorialStepData:
	var step := make(p_title, p_body, p_gate, 0, p_nudge)
	for cell in p_cells:
		step.highlight.append(cell)
	return step
