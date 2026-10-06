extends SceneTree

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://audio/sfx/v3")
	for variant in 4:
		var sound := SfxSynth.match_pop(variant)
		assert(sound.save_to_wav("res://audio/sfx/v3/match_%d.wav" % (variant+1)) == OK)
	print("Generated 4 original soft pop/chime match WAVs")
	quit()
