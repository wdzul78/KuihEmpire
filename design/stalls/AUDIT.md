> Current artwork: 32 masters across eight locations fulfil 128 context slots. School Canteen uses institutional v2 art; Government Office Canteen is an additional future location. See GENERATED_ART_REPORT.md for the current status.

> Update 11 October 2026: 28 generated masters are installed and fulfil all 112 context slots. See GENERATED_ART_REPORT.md for the current state. Earlier asset requests below are retained as reference.

# Stall progression audit and architecture

## Audit before implementation

1. Main Menu: scenes/menu/home.tscn delegates to HomeScreen. Fixed assets/menu/v1/background.png; characters, cat, logo and HUD are separate layers.
2. My Stalls: scenes/stall/gerai_screen.tscn delegates to GeraiScreen; small preview, tabs and technical structure/story labels.
3. Shop: shares GeraiScreen; supplies use coins, decor uses stars after the preceding currency change. No separate Shop scene.
4. Backgrounds: GeraiBackdrop draws cover-scaled texture and procedural location/structure/decor layers. Gameplay overrides every location with market_stall_portrait.png. Main Menu and Journey bypass this component.
5. Saves: SaveManager normalizes schema, atomic JSON replacement and last-good backup; existing structural_upgrades, location_decor, owned_decor, levels, chapters and story_seen must remain. Save version 5 supports additive fields.
6. Journey/Story: JourneyLibrary defines Family Stall story and stage 10/20/30 beats; JourneyMap has 30 published nodes; StoryScreen uses StoryLibrary narrative pages.
7. Currency: coins pay for boosters and +5 moves (900); available stars = earned stage ratings minus stars_spent. Historical ratings remain intact. Decor and renovation use stars as requested in the prior turn; no conversion.
8. Milestones: stage 10/20/30 wins unlock purchased structural tiers 1/2/3. ProgressionManager claims milestone recipe/story/free-play rewards independently.
9. Assets: preloads/load/ResourceLoader; LocationDefinition has a legacy layered background list. Missing artwork has existing procedural fallback.
10. Reuse: GeraiBackdrop, JourneyArt normalized placement, UIKit, GameButton, CoinDisplay, HeartDisplay, StallComponentArt, sparkle_burst and safe mobile layout.

## Proposed and implemented architecture

StallDefinition Resource -> four StallState Resources. One .tres per location. States describe ids, display names, milestones, star costs, context image paths, task labels, hotspot positions and equally effective cosmetic variants. LocationManager owns active selection, upgrade transactions and variant choices. It remains the existing autoload; no duplicate progression service.

GeraiBackdrop resolves the selected location/state/context dynamically. Main Menu, gameplay, Journey and Story follow the active stall. My Stalls previews a chosen location without changing active selection. Context images can be replaced by modifying .tres data, without gameplay code changes.

State hierarchy: Journey -> 30-stage Story/location -> three 10-stage milestones -> Stage. Milestones unlock tasks; spending stars completes renovation. Stage 30 unlocks the next selectable stall. Published gameplay remains Family Stall stages 1–30; selecting School Canteen does not pretend its stages exist.

## Migration and placeholders

Add active_stall_id (family_stall default) and stall_variants (per location/per purchased tier). Derive current stage, earned milestone, visual state and variant in stall_snapshot(), avoiding duplicated stale save fields. Normalize IDs/variants and reject locked active locations. Preserve old structural upgrades, star ledger, coin balance, owned decor and stage history.

Use existing Family Stall textures as temporary bases with structural overlays; other locations use existing procedural scene palettes. No new raster images were generated. Authored context backgrounds suppress legacy structural overlays to avoid double-drawing renovated objects; separate purchased accessories remain overlays.

## Files and scene scope

Modify LocationManager, SaveManager, LocationDefinition, GeraiBackdrop, HomeScreen, LevelController, GeraiScreen, JourneyMap, StoryScreen, JourneyMilestonePopup and JourneyLibrary. Add StallDefinition/StallState, resources/stalls/*.tres, asset slots, documentation, import helper and regression scenes. Existing scene .tscn files keep their script-based entry points and need no replacement.

## Asset convention

assets/stalls/<location>/<old|revived|polished|complete>/<menu|gameplay|renovation|journey>_bg.png

Optional variants/<batik|pandan>/<context>_bg.png override a state's baseline. PNG/WebP are supported by changing the resource path. Journey may reuse renovation art by pointing its property to the same image.
