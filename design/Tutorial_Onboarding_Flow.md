# Tutorial, kuih introductions and welcome rewards

## Player flow

New kuih cards appear before that type's first playable board. Each card reuses the existing kuih graphic, shows its name and a short description in English or Malay, and requires acknowledgement. Acknowledged IDs persist in `kuih_seen`; replaying a lesson does not repeat them. Introductions do not unlock recipes: the Recipe Book still follows normal progression.

Ten active lessons: vertical swipe → horizontal swipe → first customer → horizontal Tapau → vertical Tapau → two directional packs combined into a cross → 2×2 Hantar → L/T Dulang → customer queue → full board with inventory power-ups locked. Stable lesson IDs remain `[1,2,3,4,10,11,9,5,7,8]` for save compatibility; display numbering is 1–10. Match five is explained at campaign Stage 12.

Final result → animated gift chest → 500 coins and 3,600 seconds free play → starter stall restoration for 300 coins, or Later → accessory explanation → Journey with Stage 1 selected. Gift claim, restoration and completed introduction flags persist independently. Returning through Play resumes the unfinished welcome flow. Historical completed saves are not forced through it again.

Starter restoration adds clean ornamental trim and counter cloth to the same base background, removes the worn tint and cracks, and remains purchasable in Shop if skipped. It does not bypass the structural upgrades gated by Stage 10, 20 and 30. Decor remains bought/equipped separately through Shop → Decor.

Campaign sizes: Stage 1–2: 3×3; 3–4: 4×4; 5–6: 5×5; 7–8: 6×6; 9–10: 7×7; Stage 11 onward: 8×8. Early order quantities and score thresholds are adjusted for these sizes. Existing progress and stage records are preserved.

## Runtime files

- `scripts/ui/kuih_introduction.gd`: first-use cards and Malay/English descriptions.
- `scripts/ui/onboarding_finish.gd`, `scenes/ui/onboarding_finish.tscn`: gift, restoration and accessory screens.
- `scripts/core/onboarding_progress.gd`: reward quantities, restoration cost, persisted state.
- `scripts/ui/welcome_chest.gd`: transparent sprite atlas and opening animation.
- `scripts/levels/tutorial_library.gd`: stable lesson order, authored boards and gates.
- `scripts/levels/level_library.gd`: starter board sizes, orders and score thresholds.
- `scripts/data/tutorial_text.gd`: translated coaching text.

## Verification

- `tools/tutorial_flow_test_scene.tscn`: actual vertical/cross lessons, replay protection, locked tutorial power-ups and blocked direct requests, gift/reload protection, restoration, kuih acknowledgement and welcome-to-Journey navigation.
- `tools/onboarding_visual_test_scene.tscn`: rendered gift closed/open, restoration old/new, accessories, first kuih card and campaign Stage 1. Checks actual scene introduction blocks gameplay until acknowledged.
- `tools/balance_scene.tscn -- --starter-only`: 16 seeds × 10 campaign stages; all 160 won in the greedy simulation. Every active teaching lesson was achievable for all four test seeds.
- Regression suite passed. Simulation is a logic check; phone touch and difficulty still benefit from manual playtesting.

## Generated chest asset

Built-in imagegen tool, transparent output. Final project asset: `assets/ui/onboarding_v1/reward_chest_sheet.png`. The original generated file is retained. Two horizontal atlas cells provide closed and open states; runtime animation blends the states with a gentle pulse. No gameplay text is baked into the image.

Exact generation prompt:

> Create a production game sprite sheet for a cozy Malaysian kuih match-3 mobile game. Transparent background. Wide canvas with exactly TWO evenly sized square sprite cells horizontally, no divider, no text. LEFT cell: closed reward treasure chest. RIGHT cell: same chest fully open, lid hinged upward, warm golden glow from inside with a few floating gold coins and pink heart reward symbols, all fully contained in right cell. Identical chest size, front three-quarter view, aligned base in both cells. Chest made of rich honey brown wood, chunky polished gold trim and rounded gold corners, small pink heart emblem on front clasp. Beautiful hand-painted cartoon mobile casual game art, thick clean dark brown outlines, soft shading, lively golden highlights, warm friendly palette, high clarity at small size, polished like existing tropical wooden game buttons. Generous transparent padding around each sprite, no crop, no background, no UI or lettering.

