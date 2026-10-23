> Current artwork: 32 masters across eight locations fulfil 128 context slots. School Canteen uses institutional v2 art; Government Office Canteen is an additional future location. See GENERATED_ART_REPORT.md for the current status.

# Stall system implementation report

## Result

The active stall is persistent and independent of the stage being played. Its purchased visual state drives Main Menu, gameplay, Journey and Story backgrounds. My Stalls previews any location and can activate only unlocked stalls. Stage 30 unlocks School Canteen as a selectable environment; gameplay beyond Family Stall remains unpublished.

## Files changed

- scripts/core/location_manager.gd: active selection, unlocked-stall guard, derived snapshot, per-tier variants, star upgrade transaction, immediate persistence and notifications. Existing accessibility checks for playable content remain separate.
- scripts/core/save_manager.gd: additive active_stall_id/stall_variants defaults and validated migration. Original stage ratings, paid structural tiers, stars_spent, coins and decor remain.
- scripts/data/location_definition.gd: renovation prices read from StallState resources.
- scripts/art/gerai_backdrop.gd: context-specific asset resolution, active selection listening, uniform cover crop, lazy loading, 0.28-second texture crossfade, authored-image structural-overlay suppression, existing-art/procedural fallbacks.
- scripts/ui/home_screen.gd: dynamic active-stall background under the existing character, cat, logo and HUD composition.
- scripts/gameplay/level_controller.gd: active-stall gameplay background independent of campaign stage location.
- scripts/ui/gerai_screen.gd: large renovation scene, available-star header, milestone progress, selectable stalls, active button, pulsing hotspots, compact bottom upgrade panel, equal-progression Classic/Batik/Pandan variants, decor preview/equip, coin supplies, 0.70-second star-flight/sparkle/shine renovation sequence. Input is guarded during purchase animation; save commits atomically before presentation so interruptions cannot lose progress.
- scripts/ui/journey_map.gd: active-stall journey background, original route/stage nodes retained.
- scripts/story/story_screen.gd: same active stall and palette behind existing narrative pages.
- scripts/ui/journey_milestone_popup.gd: current-stall preview and direct renovation action.
- scripts/levels/journey_library.gd: milestone text distinguishes unlocked renovation from purchased renovation; Stage 30 explains School Canteen environment versus future stages.

## Scenes/resources added

No production .tscn scene replacements were needed; existing Home, Level, Gerai, Journey and Story scenes use their updated script implementations.

New reusable Resource classes: scripts/data/stall_definition.gd, scripts/data/stall_state.gd.

Seven resources/stalls/<location>.tres definitions, each containing four states: old, revived, polished, complete. Location IDs: family_stall, school_canteen, morning_market, town, city, festival, bazaar_ramadan. Each state has menu/gameplay/renovation/journey path slots; 28 state resources total.

Test resources: tools/stall_progression_test_scene.tscn, tools/stall_visual_test_scene.tscn, corresponding .gd scripts and a tiny GradientTexture2D fixture for crossfade testing. This fixture is under tools/, excluded from exports, and never referenced by shipped stall definitions.

Import helper: tools/configure_stall_imports.ps1, which backs up existing .import files before adjusting Android-oriented compression settings.

## Save changes

active_stall_id defaults to family_stall; locked/unknown IDs normalize back to default. stall_variants stores selected cosmetic style per location and structural tier. Current local stage, earned milestone, visual state and variant are derived by LocationManager.stall_snapshot(), so the save does not duplicate stale state fields. Available renovation stars remain earned historical stars minus stars_spent. Prices retained: upgrades 5/8/12 stars; decor 2/3/2 stars; moves 900 coins. No conversion introduced.

## Artwork now installed

Codex generated 28 portrait masters covering all seven locations and four states. All 112 context slots now resolve to authored images. Main Menu, gameplay, renovation and Journey share the state master; each resource retains independent path fields for later replacements. Family Complete uses background_v2.png; other selected images use background_v1.png.

Optional Batik/Pandan variant artwork is not authored and falls back to the selected master. See GENERATED_ART_REPORT.md and GENERATED_ART_MANIFEST.json for current artwork, prompts and provenance. ASSET_REQUESTS.md is the earlier prompt archive, not a pending manual task.

## Validation

PASS: tools/stall_progression_test_scene.tscn
- fresh player/default active selection and Old state
- reject locked or invalid stall IDs
- milestone and insufficient-star guards
- Revived/Polished/Complete upgrades and exact deductions
- stage ratings/progression retained; no coin charge for upgrades (achievement coin awards isolated in test)
- Stage 30 -> School Canteen selection; return to Family Stall
- active selection and tier styles survive save/reload/normalization
- legacy upgrade/star ledger/coins/owned decor migration retained
- all four backdrop contexts follow active changes
- missing images use existing/procedural fallbacks
- authored asset resolution and previous texture release after 0.28-second crossfade
- Main Menu, actual LevelController gameplay, My Stalls and Journey integration
- renovation panel and 0.70-second animation input/state lifecycle

PASS: tools/currency_roles_test_scene.tscn (currency separation, duplicate-owned purchase, insufficient stars, persistence, coin moves and UI captions).

PASS: visual rendering at standard 540x960 and taller requested viewport; screenshots inspected for readable panel, variants, hotspots and cover crop. Desktop window limits constrain the taller captured window; component tests also exercise 1080x2400 sizing. This is not a physical-device safe-area/performance test.

PASS: import helper's no-assets path; export settings continue excluding .asset_backups/*, tools/*, design/* and .shots/*.

## Remaining work

- Generate/import final artwork separately in ChatGPT; adjust normalized hotspot positions in .tres files if final objects move.
- Optional distinct variant art and Journey previews.
- Test texture compression appearance, safe areas, GPU memory and frame time on a low-end Android device after final images are supplied. No APK was built. Documentation estimates ~7.91 MiB per uncompressed 1080x1920 texture, ~15.82 MiB for two during crossfade, excluding the rest of the game.
- Author School Canteen and later gameplay/story content before publishing those stages. Their environment definitions are prepared, not fabricated stage content.

Backups: .asset_backups/2026-10-11_13-13-45-720_active-stall-renovation and subsequent refinement backups. Existing assets were preserved; export exclusions unchanged.
