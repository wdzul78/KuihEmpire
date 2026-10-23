# Recipe Book and gameplay catalog: audit and implementation plan

Status: historical audit and architecture proposal, 12 October 2026. The ten-recipe sample has now been implemented; see `recipe_system_implementation.md` for behavior, validation and remaining content work. This was the audit-first deliverable requested in sections 35–38 of the supplied brief. No final artwork or APK was generated; existing project changes were preserved.

## Findings from the current working tree

| Area | Evidence | Finding and implication |
| --- | --- | --- |
| Campaign | `scripts/levels/level_library.gd`, `LevelLibrary.count()` | Exactly 30 curated playable stages. Score tables, chapter finale and starter boards assume this MVP. Do not change the count to 2000 without authored stage content. |
| Journey | `scripts/levels/journey_library.gd` | One Family Stall Story, milestones at 10/20/30. These currently unlock Ketayap/Keria/Penyaram plus cosmetics. Preserve cosmetic and stall effects when moving recipe discovery to its own schedule. |
| Future locations | `scripts/data/location_definition.gd` | Eight location definitions cover 30-stage ranges through 240; only Family Stall is released. Location and Story currently share an ID. A larger region must become a separate parent instead of one new region per Story. |
| Progress | `scripts/core/progression_manager.gd` | Sequential unlocks use stage ratings. `record_win()` also claims Journey milestones. Existing `unlock_recipe()` is idempotent but has no coin reward or cultural catalog validation. |
| Save | `scripts/core/save_manager.gd` | Version 5 JSON, normalization, atomic temporary-file replacement, previous-good backup and pause/close flushing. Unknown fields are discarded by normalization: new fields must be explicitly supported. No cloud restore exists. |
| Migration hazard | `SaveManager._normalize()` | Legacy recipe IDs `seri_muka`/`lapis_pandan` become `ang_ku_kueh`; `vadai` becomes `keria`. These board substitutions must not run on new cultural discoveries: these foods must retain separate identities. Historical identity already lost in an old normalized save cannot be reconstructed confidently. |
| Coins | `scripts/core/economy_manager.gd`; controller `_win()` | Coin balance and stage rewards already exist. Recipe discovery should grant through this manager while sharing a persisted claim snapshot. |
| Stars | `EconomyManager.stars()` | Available renovation stars = permanent stage-rating total minus `stars_spent`. There is no grant-star API. Add a separately persisted recipe reward credit; do not change stage ratings to award collection stars. |
| Achievements | `scripts/core/achievement_manager.gd`, `scripts/data/achievement_definition.gd` | Definitions, saved progress, claim flags, coin rewards and toasts exist. Recipe metrics currently count discovered `KuihLibrary` items only. Preserve legacy achievements; add a separate cultural recipe metric and a 200-entry achievement. |
| Recipe UI | `scripts/ui/recipe_book_screen.gd`, `scenes/ui/recipe_book.tscn` | Existing illustrated open-book screen, four cards per spread, paging, mastery stars and descriptions. It combines 17 normal definitions with five power-ups. No cultural detail modal, collection filters or collection reward controls. |
| Early discovery | `scripts/ui/kuih_introduction.gd`; `scripts/data/powerup_recipes.gd` | Tile introductions unlock recipes immediately; opening the book synchronizes seen tiles. These must remain gameplay knowledge unlocks, separate from cultural stage discovery. Otherwise the first six cultural recipes unlock during onboarding. |
| Board catalog | `scripts/data/kuih_data.gd`, `scripts/data/kuih_library.gd` | Resource definitions use stable IDs, colors, shapes, chapters and `recipe_id`. Six starter pieces; 17 registered definitions. Preserve IDs and art paths. |
| Asset loading | `KuihLibrary._build()`; `scripts/art/board_art.gd` | Normal art falls back through cartoon_v3 → cartoon_v2 → original and sometimes uses atlas crops. Specials and blockers use existing assets. Dedicated cultural artwork should use optional paths and runtime placeholders until supplied. |
| Localization | `scripts/ui/menu_text.gd`; `JourneyArt.localized()` | Existing Malay/English selection and inline translation pairs. Recipe screen strings and catalog blurbs are largely English. New content needs stable keys with Malay/English tables and visible research placeholders. |
| Board objects | `scripts/board/board_cell.gd`, `scripts/data/blocker_spec.gd` | Stable special enums, overlay durability, target counters, six blocker kinds. Keep enum numbers stable. Catalog roles describe existing capabilities, not automatic behavior. |
| Mechanics | `scripts/board/board_state.gd` | Adjacent matches remove overlay HP; packaging/tray counters consume collected kuih; waterfall gravity exists. Existing steamer exposes a covered piece when cleared. It is not a Pau generator. No Pau bottom-exit objective was found in these definitions. |
| Tests | `tools/recipe_discovery_test.gd` | Existing test verifies seen-tile/power-up discovery and book paging. It does not cover cultural milestones, paid discovery or persistence. Runtime tests were not run for this documentation-only change. |

### Content reconciliation

Registered normals: onde_onde, kuih_koci, ang_ku_kueh, kuih_ketayap, kuih_lapis, keria, penyaram, kuih_cina, acar, dodol, kuih_kukus, kuih_goreng, kuih_bom, seri_muka, agar_agar_ros, karipap, tart.

Current power-up book entries: horizontal, vertical, Badak Berendam, Kek Lapis Sarawak Premium and Hantar. Existing art also supplies these mechanics. Preserve all five and their stable enum IDs. Planned foods such as Vadai, Pau, Puteri Mandi, Pulut Panggang and Pisang Goreng are not all independent normal definitions. Do not infer a working mechanic merely from an asset or planned name.

Some existing descriptions/placeholder shapes need cultural review (for example Penyaram's current baked banana-cup description). Record this as RESEARCH_REQUIRED; do not copy those descriptions into the cultural catalog as verified facts or replace working tile artwork during architecture work.

## Proposed architecture

### Data and registries

Use Godot Resources, matching existing `KuihData` and `LevelDefinition` conventions. New definitions live in `scripts/data/`; authored resources in `data/recipes/`, `data/recipe_collections/` and `data/recipe_rewards/`. A manifest explicitly lists published resources in order; do not depend on directory iteration or lexical filename ordering.

`RecipeDefinition` has id, collection_number, name_key, alternative_name_keys, region/state/community/category keys, description_key, ingredients_key, fact_key, image_path, discovery_stage, collection_tags, rarity, optional gameplay_reference_id, gameplay_candidate, research_status and reward_id. Metadata is immutable; discovered state belongs to the save. All uncertain cultural fields are RESEARCH_REQUIRED. Alternative names supplied in the brief are candidates for review, not new verified claims.

`RecipeCatalog` loads and indexes the manifest by ID, collection number and discovery stage. It exposes published_count and target_count (200) separately. Initially only ten entries exist. UI says “N / 10 available · 200 planned”, avoiding 190 fake collectible records. At full publication use “N / 200”.

`RecipeCollectionDefinition` has id, display_name_key, explicit recipe_ids, completion_reward_id, optional artwork_path/badge_id, release_status and content_version. Multiple collection membership is allowed. Freeze released membership for claim eligibility; later expansions use a new collection tier/version so previously paid claims are not revoked.

`RecipeRewardDefinition` has stable id, coins, renovation_stars, booster_counts, cosmetic_ids, badge_ids and optional achievement_id. Milestone resources point to a threshold and reward ID. Balancing belongs in authored data. The proposed 100-coin discovery baseline is provisional. No star is granted for ordinary discoveries.

`GameplayObjectDefinition` is an adapter catalog around existing kuih, blocker and special IDs. It has namespaced id, source_kind/source_id, roles, optional recipe IDs, art reference, behavior_id and parameters. Examples: `tile:onde_onde`, `special:order`, `blocker:steamer`. A steamer is equipment, not a cultural food recipe. Recipe membership is a reference/tag, not a mutually exclusive gameplay role.

Roles: NORMAL_TILE, COLLECTION_TARGET, DROP_TARGET, BLOCKER, MULTI_HIT_BLOCKER, GENERATOR, SPREADING_BLOCKER, HIDDEN_OBJECT, SPECIAL, PREMIUM_SPECIAL, COMBO_SPECIAL, STAGE_OBJECT, RECIPE_ONLY. A definition may have several. RECIPE_ONLY excludes promotion to the board until reviewed; capability tags do not activate unimplemented mechanics. Preserve special/blocker enum serialization. Do not rewrite the board into a general behavior engine now.

### Manager and integration

Add `RecipeBookManager` after SaveManager/EconomyManager in autoload order. APIs:

```gdscript
is_recipe_discovered(id) -> bool
discover_recipe(id, source, completed_stage = 0) -> Dictionary
get_discovered_count() -> int
get_total_recipe_count() -> int # published entries
get_collection_progress(collection_id) -> Dictionary
claim_milestone_reward(milestone_id) -> Dictionary
claim_collection_reward(collection_id) -> Dictionary
reconcile_legacy_discoveries() -> void
```

Unknown IDs return failure without changing balances. Stage-source discovery checks the saved completed stage and explicit recipe assignment. Trusted future event code may use another source; no event infrastructure is needed now. Results carry newly_discovered, rewards, recipe_id and error information; UI never grants rewards itself.

Add optional `recipe_unlock_id` to `LevelDefinition` for cultural content. Retain `recipe_unlock` as a legacy field for existing resources/callers. Existing `kuih_unlock` still controls gameplay presentation. The manifest's schedule is used by the authoring tool to populate stage assignments; runtime reads assignments, not `stage % 10`.

Call the manager from the campaign win path once stage progress and stage coins are recorded, before presentation. Exclude tutorial/endless sessions explicitly. Refactor Journey recipe side effects to legacy knowledge only; preserve stall/cosmetic gates. Levels 10/20/30 receive sample recipes 001/002/003. Samples 004–010 reserve stages 40–100, but remain locked until those stages exist or a development-only test invokes the manager. Do not create 70 fake playable levels to demonstrate the book.

Keep the new coins and claim flags in the same save snapshot. Persist successfully before emitting reward/discovery presentation signals; on write failure restore the pre-transaction snapshot, suppress success and expose retry. Re-entrant listeners cannot award twice. Reward confirmation after a crash derives from pending presentation IDs rather than granting again.

`EconomyManager.stars()` becomes `stage_rating_total + recipe_star_credits - stars_spent`, clamped to zero. Only recipe reward transactions increment recipe_star_credits. Preserve stage-star achievement metrics and existing purchases. Cosmetic rewards must reference existing `DecorDefinition`/inventory IDs; validate unreleased rewards instead of pretending an unknown decoration is usable.

Add milestone definitions at 5/10/20/25/50/75/100/150/200 with explicit reward references. Activate only validated rewards. Starter test configuration can exercise coins, one star and an existing booster. Future badge/costume/decor rewards stay marked pending until the corresponding inventory exists. Only one system owns each grant; the Master achievement and 200 milestone must not both pay the same reward.

### Save schema and migration

Proposed version 6 additions:

```json
{
  "recipe_book_schema": 1,
  "discovered_recipe_ids": [],
  "recipe_discovery_count": 0,
  "recipe_discovery_records": {},
  "claimed_recipe_discovery_rewards": [],
  "claimed_recipe_milestone_rewards": [],
  "claimed_collection_rewards": [],
  "recipe_star_credits": 0,
  "pending_recipe_presentations": []
}
```

Keep `recipes`, `mastery` and `kuih_seen` as gameplay-knowledge state so existing content remains visible. Deduplicate IDs, validate types and recompute count from discovered IDs. Preserve unknown cultural IDs for forward compatibility while excluding unknown IDs from published collection eligibility. A discovered ID without a discovery claim flag is repaired as claimed during normalization, never treated as a fresh reward opportunity.

Migration runs once. Map only known matching food identities from legacy `recipes`/`kuih_seen`; never powerup IDs. Imported discoveries retain ownership, receive no discovery coins and show no new-discovery popup. Reconcile actually completed historical milestone stages, without assuming every stage below the highest clear was completed. Mark imported discoveries' coin claims as settled. Newly available collection/milestone rewards may be claimed once through the normal eligibility check. Keep this policy explicit in migration tests.

Do not route cultural IDs through the old board substitution map. Preserve raw legacy evidence before substitution when loading older files. If an earlier save already erased Vadai/Seri Muka identity, retain the known discovery and flag the ambiguity rather than guessing which food was originally discovered.

Local persistence cannot survive uninstall unless the OS restores game data; this project currently has no cloud save. Keep the schema exportable for a later cloud restore. No reinstall guarantee is made now.

### UI architecture

Reuse `scenes/ui/recipe_book.tscn` and the existing book backdrop. Back up the existing screen/script and any touched layout/art references with `tools/backup_design.ps1` before UI edits. No asset movement or new final artwork is required.

Introduce three views within the book: cultural Recipes, Collections, and preserved Gameplay Guide. Cultural cards show a question mark while locked (do not reveal food art through a grey overlay), and artwork/name/number when discovered. Paginate or virtualize; never construct 200 full detail views at once. Regional/community filters come from published collection definitions, not guessed ownership fields.

`RecipeDetailPanel` is a reusable scrollable modal: art, number, name, alternatives, reviewed region/state, description, ingredients, fact and discovery status. Research placeholders remain explicit in development; avoid invented cooking instructions. Use the existing Malay/English setting, stable recipe keys and a fallback for untranslated research content.

`RecipeDiscoveryPopup` reuses the exact recipe texture and a dimmer; title, region (only if reviewed), grant summary, View Recipe and Continue are UI controls. Queue it after victory animation and the Journey celebration, preventing modal overlap with achievement toasts. View Recipe opens detail while retaining continuation state. Acknowledging removes a persisted presentation ID; replay cannot grant or requeue the discovery. If a crash occurs before acknowledgement, resume the pending presentation once without granting again.

Collection progress shows discovered/required, completeness and a disabled/enabled claim button. Claimed state persists. Recipe milestone claims use the same reward presenter.

## Validation and rollout

Development validator checks duplicate IDs/numbers, valid 1–200 numbering, duplicate/invalid discovery stages, stage assignments and expected 10-stage intervals within authored content, unknown gameplay references, unknown collection members, untranslated/missing keys, missing reward IDs, negative rewards, invalid inventory grants and unsupported behavior IDs. Missing art and unreviewed cultural metadata are development warnings; release requires resolution. Report stages 40–100 as future reservations, and 110–2000 as unplanned capacity, not fabricated assignments. Full target validation requires all 200 intervals populated.

Implementation sequence:

1. A–C: Resource schemas, registries, manager and ten representative records; no final art.
2. J/F: Save normalization/migration and transaction-safe coin rewards; recipe-star credit support.
3. G–I: Sample Sarawak Heritage collection (Tebaloi/Penganan/Kek Lapis Sarawak), milestone eligibility and validated rewards.
4. D/E: Back up and extend book UI, preserve Gameplay Guide, add detail and queued discovery popup.
5. K/L: Optional texture loading, image manifest and validation utility; integrate supplied images only after design backup.
6. M: Publish researched catalog batches and authored stage data incrementally. Region → Story → milestone → stage definitions replace the single-story assumptions only as content is released. Story 67 ends at stage 2000 with a partial 20-stage range.

Required tests before calling runtime implementation complete: fresh/legacy/malformed saves; same discovery twice; replay; completed vs failed/tutorial/endless stage; migrated ownership without coin payout; every authored ten-stage assignment; exception assignment; reward/save failure and listener re-entry; restart after grant; one-time milestone/collection claims; count repair; unknown IDs; star spending without altering ratings; localizations; locked-card privacy; detail scroll fit at phone aspect ratios; popup/animation ordering; missing art fallback. Redirect saves for all tests. Do not build an APK unless explicitly requested.

## Artwork handoff

See `recipe_image_requests_batch_01.md` for ten complete requests. Recipe art is independent of board promotion and is reused by detail/discovery views. Do not generate final images in Codex. For unusual/unverified forms, generation requires an approved visual reference. Review alpha, silhouette, style, food identity and thumbnails individually; regenerate only rejected entries. Existing board art remains in its current directories.
