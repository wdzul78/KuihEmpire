# Ten-recipe implementation

Implemented 12 October 2026. No final artwork was generated and no APK was built.

## Player behavior

The Recipe Book has cultural Recipes, Collections and the existing Gameplay Guide. The Guide retains all 17 existing board definitions, five power-up entries, legacy discoveries and mastery displays. Cultural discoveries do not add pieces to the board or change the six-piece starter pool.

Ten sample cultural recipes are published, with 200 planned. Stages 10, 20 and 30 discover Onde-onde, Kuih Cincin and Bahulu. The other seven recipes reserve stages 40–100 and remain locked in normal play until those stages are authored. The campaign still contains 30 stages.

Missing artwork uses a question mark on locked cards and an “Artwork coming later” placeholder on discovered cards, details and popups. Unverified cultural fields show “Awaiting review” in English or “Dalam kajian” in Malay. No origin, community or ingredient claims were invented.

Successful campaign completion saves the cultural discovery and configured coin reward, then presents the discovery popup after victory animations. View Recipe opens scrollable cultural details; Continue acknowledges the popup. Pending presentations survive restart and resume on Home without paying again. Tutorial and endless sessions do not grant cultural discoveries. Existing tile-introduction and Journey recipe unlocks remain Gameplay Guide knowledge.

The sample Sarawak Heritage collection contains Tebaloi, Penganan and Kek Lapis Sarawak. Its claim button is enabled only after all three are discovered. Recipe milestones are configured at 5/10/20/25/50/75/100/150/200 discoveries. Only the first two are reachable with the sample catalog. Claims are one-time and persisted. Recipe-earned renovation stars add a separate credit to the star wallet; stage ratings remain unchanged.

## Files and authoring

- `data/recipes/catalog.json`: ten records, bilingual fields, optional artwork paths, schedule, sample collection and reward/milestone definitions. This is the single sample authoring manifest; JSON feeds typed Godot Resources.
- `scripts/data/recipe_definition.gd`, `recipe_collection_definition.gd`, `recipe_catalog.gd`: resource models, optional art loading, registry and validator.
- `scripts/data/gameplay_object_catalog.gd`: multiple-role adapters around existing board, blocker and special definitions. Future generator/drop/spreading tags do not activate mechanics.
- `scripts/core/recipe_book_manager.gd`: discovery eligibility, reward transactions, collection/milestone claims and independent save migration.
- `scripts/ui/recipe_book_screen.gd`, `recipe_presentation.gd`, `recipe_text.gd`: book views, filtering, details, queued discovery and Malay/English UI text.

The Android export preset includes `data/recipes/*.json` so the runtime manifest is packaged later. Existing backup exclusions remain intact. No export was run.

All reward values are provisional authoring data. Later milestones currently use coins/stars/boosters supported by the existing economy. Cosmetic, badge and costume payouts require real inventory definitions before activation; they are not falsely awarded now. The 200-recipe Master achievement records completion but has zero separate coin payout, because the 200 milestone owns the reward.

Each recipe supports rarity and an optional gameplay reference. Future trusted event code may call `discover_recipe(id, "event")` after checking its own eligibility. No event system was added. Normal campaign discoveries require a saved stage win and an explicit `LevelDefinition.recipe_unlock_id` assignment.

Collection membership should remain frozen once released; use a new collection ID for an expanded tier. The filter cycles All recipes and all configured collection definitions; the collection progress/reward list also reads every configured collection.

## Save compatibility

Save version 6 preserves the existing schema and adds cultural discovery IDs/count/records, discovery reward claims, milestone claims, collection claims, recipe star credits and pending presentations. Count is repaired from unique stored IDs; the UI counts published known IDs. Unknown cultural IDs are retained for forward compatibility.

Legacy matching food discoveries and actually completed milestone stages migrate once without discovery coins or popups. Cultural identities are captured before the old Vadai → Keria / Seri Muka → Ang Ku board substitutions. Already-erased historical identities cannot be reconstructed reliably. Old board substitutions remain unchanged for Gameplay Guide compatibility.

Rewards and claim flags are written in one atomic save snapshot before successful UI signals. Write failures restore the prior in-memory snapshot and return an error. Re-entrant reward listeners cannot grant twice. Replaying a stage or restarting does not grant another discovery reward. Local save persistence is supported; cloud/uninstall restore is not implemented in this project.

## Backups

Original files were backed up before edits, with preserved project-relative paths and SHA-256 manifests:

- `.asset_backups/2026-10-12_17-56-54-724_cultural-recipe-book/`
- `.asset_backups/2026-10-12_17-57-36-664_recipe-popup-home-integration/`
- `.asset_backups/2026-10-12_18-07-24-418_recipe-readability-refinement/`
- `.asset_backups/2026-10-12_18-08-37-604_recipe-popup-layer-and-export/`
- `.asset_backups/2026-10-12_18-12-40-250_recipe-data-driven-filter/`

No runtime references point to these directories. Existing working-tree edits were retained; no commit or reset was performed.

## Validation

Use Godot 4.7.2 (the installed project runtime):

```powershell
# Use a dedicated writable APPDATA directory for isolated development checks.
$env:APPDATA = Join-Path (Get-Location) '.analysis/recipe-runtime'
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tools/cultural_recipe_test_scene.tscn
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tools/validate_recipe_catalog_scene.tscn
```

Use the validator scene rather than `--script`; project autoloads are required. The UI preview is `tools/recipe_ui_preview_scene.tscn`, run with the normal OpenGL renderer; it writes review screenshots to `.shots/`. All new tools redirect their saves, and verification used isolated APPDATA folders inside `.analysis/` to avoid real player data.

Verified:

- Cultural recipe tests: discovery eligibility, replay, coin grant, migration identities, malformed count/claims, unknown IDs, restart/acknowledgement, save-failure rollback, listener re-entry, collection/milestone eligibility and duplicate claims, star credits/spending, booster payouts and persistence, book paging/details/popup controls.
- Existing recipe discovery, persistence and currency-role tests: passed.
- Existing board invariants, special tiles, blockers and tutorial layout/achievability checks: passed.
- Rendered book/filters/collections/Guide/details/discovery in English and Malay, plus the real stage-10 win path. Corrected popup ordering above the result screen and enlarged recipe-card tap targets during review.
- Reviewed standard and taller phone layouts and exercised the filter and View Recipe buttons. Headless editor import/compilation passed with isolated APPDATA and LOCALAPPDATA directories.
- Catalog validator: ten published recipes, no errors; 27 expected warnings (ten missing art, ten cultural reviews, seven future-stage reservations).

The ten complete manual artwork prompts remain in `docs/recipe_image_requests_batch_01.md`. Back up affected existing assets and UI references again before later artwork replacements or design edits.
