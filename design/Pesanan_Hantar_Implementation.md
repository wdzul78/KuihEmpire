# Pesanan Hantar: 2×2 tutorial and unlock

## Audit and scope

Before this change, BoardState scanned horizontal and vertical runs only. Match 4 created the same cross-clearing Tapau; L/T created a 3×3 Dulang; 5+ straight created Special Order. There was no delivery square or Sweet Meter/Super Order. BoardState resolves chains with a deduplicated queue; MatchBoard locks input through animation, gravity and refill. AudioManager has ten shared synthesized SFX voices, and GameVfx caps particles at 240 and effects at 48. ProgressionManager and SaveManager own tutorial progress. TutorialLibrary used active IDs 1,2,3,4,5,7,8.

Small implementation plan followed: extend match groups with square runs; reuse the queue for delivery activation and blocker damage; add one authored creation/activation lesson; save its unlock; add bounded travel effects and central audio hooks. Existing campaign stage numbering and other special rules are preserved.

This delivery implements the user's latest request for 2×2 creation, tutorial and unlock. The entire attached revised-special plan is NOT implemented: Directional Tapau and directional-pair cross are now implemented in the follow-up (see Directional_Tapau_Implementation.md); the rest of the enhanced combo matrix, Sweet Meter and Super Order remain pending.

## Gameplay

Four identical ordinary playable kuih in a 2×2 square create HANTAR (enum appended; old enum values retained). Intersecting matches merge, with priority 5+ straight > L/T > match 4 > square. One package is protected while the other square cells clear. Initial random boards avoid free square matches. Adjacent swaps that form only a square are accepted after unlock. Locked boards retain their old match behavior.

Activation clears the package origin and one useful target, then follows ordinary special-chain rules. Target priorities are configurable via BoardState.delivery_priorities: unfinished customer kuih, covered blocker, kuih feeding an objective, useful playable tile, valid fallback. Origins, protected new specials and tiles already queued for the resolution are excluded. A blocker takes one layer of damage, preserving its underlying food; direct and adjacent damage are deduplicated. Each special activates once through the existing queue.

## Tutorial and save

Lesson 9, Square Delivery, follows lesson 8. A clean 4×4 authored board and hand gesture teach the 2×2 swap. Creation pauses cascades so the package remains available, then the coach guides the actual package after gravity. A successful activation leads to a recap. Acknowledging it completes the lesson and unlocks delivery for campaign gameplay. Earlier tutorial IDs and layouts remain intact. Boosters are unavailable in this scripted lesson.

Save field: special_unlocks.hantar, default false and normalized as a boolean. Unlock is awarded by winning lesson 9. A save with the older tutorial_done flag but no delivery unlock is routed directly to lesson 9 through Play. Unlock persists across reload. Completing the entire tutorial also marks delivery unlocked. Replaying introductory lessons retains the acquired unlock, while old authored boards keep their original rules.

## Feedback and asset

Generated using built-in imagegen; original PNG alpha preserved. Asset: assets/specials/delivery_v1/pesanan_hantar.png. BoardArt and KuihIcon share it; the traveling package uses the same graphic. No airplane imagery. SFX IDs HANTAR_CREATE (package snap), HANTAR_LAUNCH (soft zip), HANTAR_HIT (ding) use AudioManager and respect mute. A creation label pops and fades, at most once per player resolution; at most eight simultaneous travel paths are shown. Gameplay waits for travel to finish before clearing/refilling. Existing score rules receive all valid clears and activations.

## Files

Logic and progression: scripts/board/board_cell.gd, board_state.gd, match_board.gd; scripts/core/progression_manager.gd, save_manager.gd, game_manager.gd; scripts/gameplay/level_controller.gd, tutorial_coach.gd; scripts/data/tutorial_step_data.gd; scripts/levels/tutorial_library.gd.

Artwork/audio: scripts/art/board_art.gd, kuih_icon.gd, game_vfx.gd; scripts/board/tile_view.gd; scripts/audio/sfx_synth.gd; scripts/core/audio_manager.gd; new delivery PNG and import metadata.

Validation: new tools/delivery_test.gd and delivery_test_scene.tscn; updated tools/test_runner.gd (square lesson simulation), persistence_test.gd (tutorial count); screenshot_tool.gd --delivery-only.

## Validation

Delivery tests pass: locked square, square-only swap, one package protected, targeted order/fallback/blocker damage, covered empty position, chained special uniqueness, empty fallback, clean random fills, guided create/activate/recap, no premature unlock, old-save entry, persisted unlock, campaign enablement, and muted audio. Rules harness passes all tutorial lessons including T9 achievable 4/4 across seeds. Existing regression, score, menu, dialogue layout and persistence checks pass. Reviewed 360×640 screenshots of creation and travel. Existing test fixtures sometimes report ObjectDB exit warnings. Full campaign balance simulation and Android hardware frame rates were not verified for the unlocked feature.

Balance defaults to tune: one remote target per activation, origin-only local clear, 0.45s travel, existing match-four and special-activation score values. Audio is synthesized. The new sprite is production artwork; no placeholder package remains. Enhanced Hantar combos are pending with the rest of the attached plan.

## Exact imagegen prompt

Use case: stylized-concept. Create a single transparent-background mobile match-3 game sprite: PESANAN HANTAR delivery special for KUIH EMPIRE. The input reference is the existing package illustration style, NOT the shape to duplicate. Match its warm crisp dark brown outline, polished soft cartoon shading and bright green banana leaf accents. New design: a compact low rectangular cream kraft-paper takeaway food box, closed lid wrapped by a neat single green banana-leaf band, small gold round seal on lid, prominent cream label on front bearing a simple bold green right-pointing delivery arrow. Small three-quarter overhead view appropriate for puzzle tiles. Squat wide silhouette, completely distinct from the reference's tall gift box with bow. No bow, no crown, no airplane, no wings, no person, no eyes, no writing, no background, no external glow. The box fills a square canvas, crisp clear readability at small tile size, generous enough clear margin, true transparent alpha.

