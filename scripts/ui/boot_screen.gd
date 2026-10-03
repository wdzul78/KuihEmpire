class_name BootScreen
extends Control

## Splash screen. Warms the procedural art caches, then hands over to the stall
## (Master Plan section 48).

const HOLD_TIME := 1.5

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIKit.apply_root_theme(self)
	_build()
	_run()


func _build() -> void:
	var backdrop := GeraiBackdrop.new()
	backdrop.background_id = &"stall_dawn"
	backdrop.show_counter = false
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var stack := UIKit.vbox(10)
	center.add_child(stack)

	stack.add_child(UIKit.brand_logo(Vector2(900, 675)))
	stack.add_child(UIKit.label("Match. Serve. Grow.", 34, Palette.WOOD))


func _run() -> void:
	# Force the art cache so the first level starts instantly.
	KuihLibrary.starter_set()
	await get_tree().process_frame
	AudioManager.play(AudioManager.Sfx.TAP, 0.8, -10.0)
	# Only drive navigation when this really is the running scene.
	if not SceneManager.is_current(self):
		return
	await get_tree().create_timer(HOLD_TIME).timeout
	if not SceneManager.is_current(self):
		return
	# New players read the prologue, then start the tutorial. Returning players
	# who already read it go straight to the stall.
	if not ProgressionManager.story_read(StoryLibrary.PROLOGUE):
		await SceneManager.goto_story_then_tutorial(
			StoryLibrary.PROLOGUE, maxi(1, ProgressionManager.tutorial_index()), false
		)
		return
	GameManager.play_next()
