class_name GameplayObjectCatalog
extends RefCounted

## Descriptive adapters only. Existing board behavior and stable enums own logic.
enum Role { NORMAL_TILE, COLLECTION_TARGET, DROP_TARGET, BLOCKER, MULTI_HIT_BLOCKER, GENERATOR, SPREADING_BLOCKER, HIDDEN_OBJECT, SPECIAL, PREMIUM_SPECIAL, COMBO_SPECIAL, STAGE_OBJECT, RECIPE_ONLY }

static func all() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for kuih in KuihLibrary.all():
		entries.append({"id": "tile:" + String(kuih.id), "source_id": kuih.id, "roles": [Role.NORMAL_TILE, Role.COLLECTION_TARGET], "recipe_reference_id": kuih.recipe_id, "behavior_id": "existing_match_tile"})
	for entry in PowerupRecipes.ENTRIES:
		var kind := int(entry[0])
		entries.append({"id": "special:%d" % kind, "source_id": kind, "roles": [Role.SPECIAL, Role.PREMIUM_SPECIAL] if kind == BoardCell.Special.ORDER else [Role.SPECIAL], "recipe_reference_id": &"kek_lapis_sarawak" if kind == BoardCell.Special.ORDER else &"", "behavior_id": "existing_special"})
	for kind in BlockerSpec.Kind.values():
		entries.append({"id": "blocker:%d" % kind, "source_id": kind, "roles": [Role.BLOCKER, Role.MULTI_HIT_BLOCKER], "recipe_reference_id": &"", "behavior_id": "existing_overlay_or_target"})
	# GENERATOR/DROP_TARGET are reserved capabilities, not enabled steamer behavior.
	return entries
