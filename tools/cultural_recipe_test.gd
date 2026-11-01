extends Node

const TEST_PATH := "user://cultural_recipe_test.json"
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	SaveManager.save_path = TEST_PATH
	SaveManager.reset()
	run.call_deferred()

func run() -> void:
	var original_board_ids: Array[StringName] = []
	for kuih in KuihLibrary.all():
		original_board_ids.append(kuih.id)
	check(RecipeCatalog.all().size() == 10 and LevelLibrary.count() == 30, "sample/campaign count")
	var validation := RecipeCatalog.validate()
	check(validation.errors.is_empty(), "catalog validation: %s" % str(validation.errors))
	check(validation.warnings.size() >= 10, "missing artwork must be reported")
	check(GameplayObjectCatalog.all().size() == KuihLibrary.count() + PowerupRecipes.ENTRIES.size() + BlockerSpec.Kind.size(), "gameplay adapters")
	for stage in [10, 20, 30]:
		check(LevelLibrary.get_level(stage).recipe_unlock_id == RecipeCatalog.for_stage(stage), "stage discovery assignment")
	check(LevelLibrary.get_level(11).recipe_unlock_id == &"", "non-milestone assignment")
	var balance := EconomyManager.coins()
	check(not RecipeBookManager.discover_recipe(&"onde_onde", "stage", 10).ok, "uncleared stage eligibility")
	check(not RecipeBookManager.discover_recipe(&"onde_onde", "tutorial", 10).ok, "tutorial eligibility")
	check(not RecipeBookManager.discover_recipe(&"unknown", "event").ok, "unknown ID")
	check(EconomyManager.coins() == balance, "invalid discovery changed coins")
	ProgressionManager.record_win(10, 2, 5, 1000)
	# Existing stage achievements may pay independently of recipe discovery.
	balance = EconomyManager.coins()
	check(RecipeBookManager.discover_recipe(&"onde_onde", "stage", 10).get("newly_discovered", false), "stage discovery")
	check(EconomyManager.coins() == balance + 100, "discovery coin reward")
	check(not RecipeBookManager.discover_recipe(&"onde_onde", "stage", 10).get("newly_discovered", false), "replay duplicate")
	check(EconomyManager.coins() == balance + 100, "duplicate coin reward")
	SaveManager.load_game()
	check(RecipeBookManager.is_recipe_discovered(&"onde_onde"), "restart lost discovery")
	check("onde_onde" in SaveManager.data.pending_recipe_presentations, "restart lost popup queue")
	check(RecipeBookManager.acknowledge(&"onde_onde"), "popup acknowledgement")
	SaveManager.load_game()
	check(SaveManager.data.pending_recipe_presentations.is_empty(), "acknowledged popup replay")
	var migration := SaveManager._normalize({"recipes": ["onde_onde", "vadai", "powerup_3"], "kuih_seen": ["ang_ku_kueh"], "levels": {"20": {"stars": 1}}})
	check("vadai" in migration.discovered_recipe_ids and "ang_ku_kueh" in migration.discovered_recipe_ids, "cultural identity migration")
	check("keria" in migration.recipes, "legacy board migration preserved")
	check("kuih_cincin" in migration.discovered_recipe_ids and not "bahulu" in migration.discovered_recipe_ids, "only completed milestone imported")
	check(not "powerup_3" in migration.discovered_recipe_ids, "powerup counted as cultural recipe")
	check(migration.coins == 250 and migration.pending_recipe_presentations.is_empty(), "migration paid or presented discovery")
	check(SaveManager._normalize(migration).discovered_recipe_ids == migration.discovered_recipe_ids, "migration idempotence")
	var partial := SaveManager._normalize({"recipe_book_schema": 1, "discovered_recipe_ids": ["vadai", "vadai", "future_recipe", 99], "recipe_discovery_count": 999, "claimed_recipe_discovery_rewards": [], "recipe_star_credits": -9})
	check(partial.recipe_discovery_count == 2 and partial.recipe_star_credits == 0, "malformed state repair")
	check("vadai" in partial.claimed_recipe_discovery_rewards and "future_recipe" in partial.discovered_recipe_ids, "partial claims/forward IDs")
	var snapshot := SaveManager.data.duplicate(true)
	var good_path := SaveManager.save_path
	SaveManager.save_path = "user://missing_recipe_directory/subdirectory/save.json"
	check(not RecipeBookManager.discover_recipe(&"bahulu", "event").ok, "write failure reported success")
	check(SaveManager.data == snapshot, "write failure did not roll back")
	SaveManager.save_path = good_path
	var reentry := {"blocked": false}
	var listener := func() -> void: reentry.blocked = not RecipeBookManager.discover_recipe(&"bahulu", "event").ok
	RecipeBookManager.changed.connect(listener, CONNECT_ONE_SHOT)
	check(RecipeBookManager.discover_recipe(&"kuih_cincin", "event").ok and reentry.blocked, "listener re-entry protection")
	for recipe in RecipeCatalog.all():
		RecipeBookManager.discover_recipe(recipe.id, "event")
	check(RecipeBookManager.get_discovered_count() == 10, "ten sample discoveries")
	check(not RecipeBookManager.claim_milestone_reward("recipes_20").ok, "ineligible milestone")
	var spatulas := EconomyManager.booster_count(EconomyManager.Booster.SPATULA)
	var shuffles := EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE)
	# Exercise the existing future booster reward through a test-only threshold.
	RecipeCatalog.milestones.append({"id": "test_booster", "threshold": 10, "reward_id": "recipes_20"})
	check(RecipeBookManager.claim_milestone_reward("test_booster").ok, "booster pack claim")
	check(EconomyManager.booster_count(EconomyManager.Booster.SPATULA) == spatulas + 1 and EconomyManager.booster_count(EconomyManager.Booster.SHUFFLE) == shuffles + 1, "booster pack contents")
	check(not RecipeBookManager.claim_milestone_reward("test_booster").ok, "duplicate booster pack")
	RecipeCatalog.milestones.pop_back()
	var stage_stars := ProgressionManager.total_stars()
	check(RecipeBookManager.claim_milestone_reward("recipes_5").ok, "5 recipe coin milestone")
	check(RecipeBookManager.claim_milestone_reward("recipes_10").ok, "10 recipe star milestone")
	check(not RecipeBookManager.claim_milestone_reward("recipes_10").ok, "duplicate milestone")
	check(RecipeBookManager.get_collection_progress(&"sarawak_heritage").complete, "sample collection progress")
	check(RecipeBookManager.claim_collection_reward(&"sarawak_heritage").ok, "collection claim")
	check(not RecipeBookManager.claim_collection_reward(&"sarawak_heritage").ok, "duplicate collection claim")
	check(EconomyManager.stars() == stage_stars + 2 and EconomyManager.spend_stars(1), "renovation star credit")
	check(ProgressionManager.total_stars() == stage_stars, "recipe reward altered ratings")
	SaveManager.save_game()
	SaveManager.load_game()
	check(not RecipeBookManager.claim_collection_reward(&"sarawak_heritage").ok, "restart duplicate collection")
	check(EconomyManager.stars() == stage_stars + 1, "star spending round trip")
	check(EconomyManager.booster_count(EconomyManager.Booster.SPATULA) == spatulas + 1, "booster pack round trip")
	for kuih in KuihLibrary.all():
		check(kuih.id in original_board_ids, "board catalog changed")
	check(RecipeCatalog.find(&"vadai").text("name", "ms") == "Vadai", "localized name")
	check(RecipeCatalog.find(&"vadai").text("state", "ms") == "KAJIAN_DIPERLUKAN", "research localization")
	var book := RecipeBookScreen.new()
	add_child(book)
	await get_tree().process_frame
	check(book._mode == "guide" and book._grid.get_child_count() == 6, "default gameplay guide spread")
	book._select_mode("recipes")
	check(book._mode == "guide" and book._grid.get_child_count() == 6, "unfinished cultural tab stays hidden for MVP")
	check(not book._filter_button.visible, "cultural filter stays hidden with unfinished tab")
	book._filter = &"sarawak_heritage"
	check(book._filtered_recipes().size() == 3, "cultural collection data filter")
	book._filter = &""
	check(book._filtered_recipes().size() == 10, "all cultural recipe data")
	book._select_mode("collections")
	check(book._collection_scroll.get_child_count() == 1, "collection/milestone list")
	book._select_mode("guide")
	check(book._grid.get_child_count() == 6, "gameplay guide cards")
	book._page = 99
	book.refresh()
	check(book._grid.get_child_count() > 0, "legacy guide page clamp")
	RecipePresentation.show_detail(book, RecipeCatalog.find(&"onde_onde"))
	await get_tree().process_frame
	SaveManager.data.pending_recipe_presentations = []
	check(not RecipePresentation.present_pending(book), "empty popup queue")
	SaveManager.data.pending_recipe_presentations = ["onde_onde"]
	check(RecipePresentation.present_pending(book), "discovery popup")
	check(RecipePresentation.present_pending(book), "popup re-entry")
	var popup := book.get_node("RecipeDiscoveryOverlay") as RecipePresentation
	for child in popup.find_children("*", "Button", true, false):
		if child is Button and child.text == RecipeText.text("view"):
			child.pressed.emit()
	check(popup._details.visible and not popup._discovery_spacer.visible, "View Recipe button interaction")
	popup._close()
	check(SaveManager.data.pending_recipe_presentations.is_empty(), "popup continuation acknowledgement")
	book.queue_free()
	SaveManager.save_game()
	print("Cultural recipes: %s (%d failures; %d development warnings)" % ["PASS" if failures.is_empty() else "FAIL", failures.size(), validation.warnings.size()])
	for failure in failures:
		print("FAIL: " + failure)
	get_tree().quit(0 if failures.is_empty() else 1)
