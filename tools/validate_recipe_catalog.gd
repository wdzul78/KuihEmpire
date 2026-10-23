extends Node

func _ready() -> void:
	SaveManager.save_path = "user://recipe_catalog_validation.json"
	SaveManager.data = SaveManager._default_data()
	run.call_deferred()

func run() -> void:
	var report := RecipeCatalog.validate()
	for message in report.warnings:
		print("WARNING: " + message)
	for message in report.errors:
		printerr("ERROR: " + message)
	print("Recipe catalog: %d published / %d planned, %d errors, %d warnings" % [report.published, report.target, report.errors.size(), report.warnings.size()])
	get_tree().quit(0 if report.errors.is_empty() else 1)
