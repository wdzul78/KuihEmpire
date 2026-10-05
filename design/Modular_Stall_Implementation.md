# Modular Stall Upgrades and Accessories

## Audit and final policy

The old Gerai screen drew a coin-upgraded stall only in a menu. GeraiBackdrop returned after drawing one hardcoded wallpaper, so gameplay did not show structural progress. Journey has 30 playable stages, milestone claims at 10/20/30, permanent stars, and recipe/story rewards. Coins are spendable; stars are progression, never consumed. Save v3 stored gerai level/cosmetics but had no equipped decor or purchased per-location structure. No backend or additional playable story locations existed.

The user's clarification controls the final design: **one base shop/stall wallpaper, upgraded gradually by purchases, plus separate purchased/equipped accessories**. Milestone completion opens structural purchases. Coins apply them; milestone completion alone does not purchase them. Stage/story progression continues regardless of purchases, avoiding an economy deadlock. The original full-wallpaper upgrade concepts are retained as references only and excluded from Godot scanning using .gdignore. Runtime changes use a shared component atlas.

## Delivered architecture and loading flow

LocationDefinition configures story/stage range, preset, individual upgrade requirements, background mode/paths, structural layers and safe decor slots. LocationManager derives milestone availability from actual stage records and reads purchased structure from the save. It centralises gates, purchases, ownership, equipment and signals. No new independent Journey progress number is persisted.

Gameplay flow: resolve location from the existing LevelDefinition stage ID; create GeraiBackdrop for that location; read purchased structural level; load its one base texture; draw active components; apply saved decor at safe edge/counter slots; start the unchanged puzzle board. My Stalls and story backgrounds use the same renderer/manager. Journey displays bought structure separately from cleared stages; StagePreview identifies the location/current bought stall state.

The shipped Family Stall base is reused at state 0. State 1 adds a sign, state 2 adds shelving and a cabinet, state 3 adds canopy trim and lighting. All use **assets/ui/stall_v1/components.png**, a shared transparent atlas. Coordinates are native AtlasTexture regions, preserving the generated alpha. Slot accessories reuse components or lightweight native flowers. No bitmap is generated for each combination. Structural components have per-location rectangles/minimum levels; they can be varied for new locations.

Location definitions support layered base+components or full_texture state artwork when useful. Missing authored state artwork falls back to the nearest available base/state; locations without authored base art use a lightweight procedural concept background and development warning. Only the active base texture is held by each renderer, and the reusable component atlas is shared/cached. Backgrounds are static, ignore input, and keep structures/decor at screen edges away from puzzle cells.

## Shop and purchases

Shop/My Gerai is now **My Stalls** with Stall, Decor, Aina and Supplies tabs. Active tab is highlighted; detail content scrolls on a phone.

| Structural purchase | Required completion | Initial price |
|---|---|---:|
| Revived Stall / sign | Stage 10 | 400 coins |
| Polished Stall / shelves and cabinet | Stage 20 | 750 coins |
| Completed Stall / trim and lighting | Stage 30 | 1,100 coins |

Requirements are authored per LocationDefinition. Current star requirement is zero; the mandatory milestone already represents real stage progress. Stars are not spent. Sequential upgrade purchases stop at level 3. Coins alone cannot bypass milestones. Story stages remain unlocked through the original stage progression.

Decor: Hibiscus Pot 120, Rattan Lantern 160, Pink Batik Runner 100 coins. Preview is temporary and never alters save data. Buy grants ownership; Equip/Unequip changes a safe slot in the selected released location. Owned items are never charged twice. All three can be visible in gameplay. Decor does not alter structural level, stars, stage unlocks or rank.

Supplies permits coin purchases of existing Spatula, Tray, Shuffle and Tapau inventory (90/150/100/180). Aina provides access to the existing avatar picker in Settings; bespoke purchasable outfit sprites are future content.

A structural purchase emits a short approximately 2.7-second **STALL UPGRADED!** ceremony with before/after compositions and sparkle/SFX. It changes the actual background immediately and survives navigation/reload.

## Locations and Bazaar Ramadan

Seven locations are registered: Family Stall 1â€“30, School Canteen 31â€“60, Morning Market 61â€“90, Town 91â€“120, City 121â€“150, Kuih Festival 151â€“180, Ramadan Bazaar 181â€“210. Only the first has playable stages. Other locations are clearly Coming soon; selecting a preview grants no stages, ownership, purchases or progression.

Ramadan Bazaar has its own generated dusk base: **assets/backgrounds/locations_v1/bazaar_ramadan_0.png**. It uses the same reusable upgrade components and decor slots. Its state names are Bazaar Setup, Preparing for Iftar, A Lively Bazaar and Sweetness Together. Other future location bases and all future level/story content still require authoring; current procedural previews are explicitly concepts.

## Save and legacy migration

Save v5 adds structural_upgrades (location ID -> purchased 0â€“3), owned_decor IDs and location_decor (location -> slot -> owned item ID). State percentages are derived, not separately saved. Existing coins, best stars/scores, recipes, chapters, hearts, avatar, achievements, legacy gerai level and cosmetics are preserved. Normalization rejects unknown decor, unsupported slots and equipment without ownership; levels clamp to 0â€“3.

Pre-v5 saves retain structural visuals already earned at completed milestones, without charging them again. New v5 games start at structure 0 and buy upgrades after milestones. Existing un-gated legacy gerai levels remain stored; they cannot bypass the new milestone purchase gate. Atomic writes/backup recovery remain the existing SaveManager behavior.

LocationManager emits stall_upgrade_unlocked, stall_upgraded, decor_equipped, decor_unequipped and location_state_changed. Reset/reload reconciles views without replaying a purchase ceremony. First Renovation is added to Personal Achievements; its one-time coin reward uses the existing achievement claim system.

## Gameplay score and profile change

Gameplay coins are hidden and Score uses the combined middle/right header width, with larger typography. The menu/Shop retain coins. Player profile replaces the old visible progress track with **Score N**, derived as the sum of saved best scores on completed campaign stages. Lower-score replays and tutorials do not inflate this total; an improved best adds only the difference. No duplicate score counter is stored and Journey Ranking still uses progression/stars/relevant-stage score.

## Development preview

Debug builds expose a current/state 0â€“3 selector in My Stalls for any location. It can preview components/decor without writing saves or playing 30 stages. Release builds omit it. Previewing unreleased locations never enables purchases. Native layer coordinates and the shared atlas support further art refinement without rewriting progression.

## Files changed / added

New: scripts/data/location_definition.gd, decor_definition.gd; scripts/core/location_manager.gd; scripts/ui/stall_component_art.gd, stall_upgrade_celebration.gd; tools/stall_test.gd and stall_test_scene.tscn; shared atlas and Ramadan base.

Updated: project.godot; SaveManager, ProgressionManager, AchievementManager/definitions; GeraiBackdrop, LevelController, GeraiScreen, StagePreview, Journey milestone messages; HUD, ScoreProgress, HomeScreen; journey/menu/score tests and screenshot tool; shop/Journey design plans.

## Verification and remaining content

PASS: stall cases Aâ€“H, milestone and coin gates, exact coin charge excluding achievement rewards, shared live wallpaper updates, preview without mutations, buy once/equip/unequip, stable structural level under decor changes, repeated purchase protection, save/reload/reset, legacy normalization, locked future Bazaar, sum of best scores and no score inflation. Existing score, menu, Journey, achievements/ranking, persistence/recovery, hearts and gameplay regression tests pass. Some existing UI fixtures emit 2â€“5 ObjectDB exit warnings; no script errors remain.

Phone visual review at 360x640: .shots/01_stall_base.png, 02_stall_upgraded.png, 03_stall_decor_preview.png, 04_stall_bazaar_preview.png, 05_home.png; .shots/01_score_hud.png verifies the widened HUD. Scrollable shop details and consistent button artwork are preserved.

Remaining future content: playable stages/stories 31â€“210; dedicated base art for five future locations; purchasable Aina outfit art; optional extra decor slots/items. The initial old stall currently reuses the established game's base image; a more weathered base can be swapped independently later.

## Image generation delivery

Mode: built-in image_gen (no CLI). Generated alpha is preserved. Active saved assets:
- assets/ui/stall_v1/components.png: six reusable modular objects, sliced in Godot.
- assets/backgrounds/locations_v1/bazaar_ramadan_0.png: one Ramadan base.

Early full-wallpaper concepts are preserved under design/Stall_Concept_References/family_stall_1.png, family_stall_2.png, family_stall_3.png, with .gdignore; they are not runtime state assets. Their use was superseded by the user's modular purchase clarification.

Exact prompts, in generation order:

### Prompt 1

Use case: stylized-concept. Asset type: portrait 9:16 mobile puzzle game background for Kuih Empire, future Ramadan Bazaar location. Generate a new environment using the supplied existing game image ONLY as reference for polished hand-painted cartoon style, bold brown outlines, warm colours and perspective. Scene: Malaysian Ramadan bazaar in Kuching just before sunset, viewed from behind Aina's simple wooden kuih stall toward distant bazaar tents. In foreground wooden side posts at far left and far right, green-and-cream striped canopy occupying top 12%, a simple wooden counter occupying bottom 12%, a few banana-leaf kuih trays and woven baskets only at far edges. Warm lanterns and softly distant people in the bazaar, peach dusk sky. Crucial gameplay framing: the middle 75% width and the central area from 18% to 84% height must be open quiet soft distant scenery without large objects, counters, signage or characters; a puzzle board and customer UI will cover this area. Show humble starting stall, no luxurious cabinet yet. No Aina, no foreground people, no readable text, no logos, no UI, no border. Entire image opaque, portrait composition.

### Prompt 2

Use case: precise-object-edit. Create structural upgrade STATE 1 (Revived Stall) for Kuih Empire from this game backdrop. Preserve EXACT portrait viewpoint, central open sky/path area, perspective and clean cartoon painting style. Repair and refresh the wooden side posts and bottom counter, add neat wood trim and a small warm wooden stall name board reading 'KUIH' at the upper left edge under canopy, replace shabby baskets at edges with tidy display trays and banana-leaf kuih. This is a modest first renovation after stage 10. Keep the middle 75% width open and quiet from 18% to 84% of image height for puzzle and order UI. Decorations only at edges and top 10%/bottom 12%. Do not add people, UI, text panels or objects across the center. Opaque portrait image.

### Prompt 3

Use case: precise-object-edit. Create structural upgrade STATE 2 (Polished Stall) for Kuih Empire from this game backdrop. Preserve EXACT portrait viewpoint, central open sky/path area, perspective and clean cartoon painting style. Visibly improve the pink/cream canopy with golden edging, add a tidy narrow wooden shelving unit on far LEFT with colourful kuih trays, a small glass display cabinet on far RIGHT, richer repaired bottom wooden counter with a pink batik runner, warm lanterns at far edges and plants. Add a small 'KUIH' wooden sign under the canopy at upper left. More polished than a basic stall after stage 20. Keep middle 75% width open and quiet from 18% to 84% height for puzzle/order UI. Structural detail only far edges and top 10%/bottom 12%. No foreground people, UI or large objects across center. Opaque portrait image.

### Prompt 4

Use case: precise-object-edit. Create structural upgrade STATE 3 (Completed Family Stall) for Kuih Empire from this game backdrop. Preserve EXACT portrait viewpoint, central open sky/path area, perspective and clean cartoon painting style. Fully upgraded welcoming family kuih stall: strong polished wooden posts with carved decorative trim, beautifully finished pink/cream canopy with flower accents at far corners, an upper left compact branded name board reading 'KUIH EMPIRE', a tall beautifully organized wooden kuih display on far left, refined glass cabinet and takeaway pickup shelf on far right, larger polished bottom counter with elegant pink batik runner, warm hanging lamps at edges. Noticeably completed premium stall after stage 30, same original location. Keep middle 75% width open and quiet from 18% to 84% height for puzzle/order UI; detail restricted to far edges/top 10%/bottom 12%. No people, no UI and no large signage across the center. Opaque portrait image.

### Prompt 5

Use case: background-extraction / stylized-concept. Asset type: reusable modular stall upgrade sprite atlas for Kuih Empire mobile game. Use supplied family-stall art as STYLE reference. Create ONE landscape 3-column by 2-row sprite sheet on genuine TRANSPARENT background. Six equal rectangular grid cells, no visible grid or captions. Each separate object fits entirely inside its cell with generous empty padding, NO objects touching cell boundaries. Reading order: top left a wide blank wooden hanging stall sign with gold edge and two short rope loops (NO lettering); top middle a tall narrow wooden shelving unit holding colourful Malaysian kuih trays; top right a tall narrow wood-and-glass kuih display cabinet; bottom left a wide ornate carved wooden horizontal canopy trim with small hibiscus flowers at ends; bottom middle a single warm glowing rattan hanging lantern; bottom right a folded pink batik counter runner viewed slightly from above, wide rectangular cloth. All six objects straight FRONT VIEW matching the game stall perspective, clean thick brown outlines and polished cozy hand-painted cartoon rendering, golden wood, cream, pink and leaf green. Objects isolated with clean transparent silhouettes. No scene, sky, floor, background, UI, people, large shadows, lettering, logos or additional objects. Exactly six reusable modular sprites. This sheet will be sliced into six cells natively by Godot and reused across many shops; do not paint a whole stall.
