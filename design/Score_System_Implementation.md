# Score system implementation

## Audit and plan

Scene: `scenes/game/level_screen.tscn`; route: `scenes/world/journey_map.tscn`. LevelController owns customer orders, move budget, completion/failure, hearts and result transitions. MatchBoard presents BoardState resolution. HUD owns the OrderPanel and top counters. ResultOverlay owns result presentation. ProgressionManager owns level/star progression; EconomyManager owns coins; SaveManager owns normalized atomic JSON persistence.

Previously, successful-stage stars depended on the fraction of moves remaining, the base coin reward was fixed per stage and customer-scaled, and level records contained stars/best_moves_left. The gameplay star pill actually displayed order-item collection. The just-added feedback score was temporary board-owned points.

Implemented the smallest separation: ScoreRules data + per-session StageScoreController + one StageResultCalculator; retain existing completion, economy, progression and UI owners. Board emits clear-resolution payloads instead of calculating score. Keep order counters in OrderPanel; replace the gameplay star pill with ScoreProgress; extend existing result and save records.

## Changed files

- `scripts/data/level_definition.gd`: score thresholds, scoring resource, reward parameters, score-based star helper. Old moves-based authoring fields remain load-compatible but are unused.
- `scripts/levels/level_library.gd`: explicit 30-stage threshold table, base reward compatibility.
- `scripts/levels/tutorial_library.gd`: explicit tutorial thresholds; no remaining-move or first-clear bonus; ratings use score.
- `scripts/board/match_board.gd`: clear_resolved signal for matches, chains and booster collections; presentation feedback only; removes board-owned scoring.
- `scripts/gameplay/level_controller.gd`: session scoring, order-collection bonus, calculator, mandatory objective gate, winning reward transaction, score/result presentation and failed result reporting.
- `scripts/gameplay/customer_order.gd`: updated model documentation; order rules unchanged.
- `scripts/core/progression_manager.gd`: best score, first-clear tracking, monotonic stars.
- `scripts/core/save_manager.gd`: additive version-2 record normalization.
- `scripts/core/game_manager.gd`: pending final score, reset with pending result.
- `scripts/ui/hud.gd`: replaces gameplay stars/order count with ScoreProgress.
- `scripts/ui/match_feedback.gd`: Combo displays actual scoring multiplier.
- `scripts/ui/result_overlay.gd`: Score, New Best, move bonus, coin breakdown, zero-reward failure; larger result card, uniform touch buttons.
- `scripts/ui/order_panel.gd`: completed-item check mark.
- `scripts/ui/stage_preview.gd`: authored score targets.
- `tools/regression_test.gd`, `tools/vfx_test.gd`, `tools/journey_test.gd`: updated expectations for the new score model and mandatory objective gate.
- `tools/test_runner.gd`: score-aware simulations, actual special activation, coaching gates, scene-based launch with autoloads.
- `tools/screenshot_tool.gd`: phone-size score/combo/result/failure captures.
- `README.md`, `MVP_STATUS.md`: updated balance harness launch command.
- `design/Combo_Score_Graphics.md`: updated graphic integration documentation.

## New files

- `scripts/data/score_rules.gd`
- `scripts/data/stage_result.gd`
- `scripts/gameplay/stage_score_controller.gd`
- `scripts/gameplay/stage_result_calculator.gd`
- `scripts/ui/score_progress.gd`
- `tools/score_test.gd`, `tools/score_test_scene.tscn`
- `tools/balance_scene.tscn`
- This implementation report.

Graphic assets generated using built-in image_gen: `assets/ui/titles_v1/combo.png` and `assets/ui/titles_v1/score.png`. Original alpha retained; prompts are in `design/Combo_Score_Graphics.md`.

## Level data and scoring

Each LevelDefinition exports ScoreRules, score_two_star, score_three_star, base_coin_reward (legacy coins fallback), score_per_coin, star_coin_bonus and first_clear_bonus. All 30 campaign stages have explicitly authored score targets. Example stage 1: 800/1400; stage 10: 3000/4400; stage 30: 3000/4300. Tutorials have their own targets and zero move bonus.

Starting ScoreRules values, configurable per resource:

- Collected tiles: 10 each.
- Matched run: 3 = 30, 4 = 80, 5+ = 150. Match bonuses supplement the tile base; protected special-creation origins count as matched tiles. Overlapping runs share the base tile count.
- Special activation: +100 per activated tile, including chains.
- Two or more activated specials in one resolution: +250 combo bonus.
- Cascade: multiplier min(3.0, 1 + cascade_index * 0.25), giving x1, x1.25, x1.5, etc. Only the clear/activation part is multiplied.
- Actual required-order item collected: +5. Surplus items cannot earn this bonus repeatedly.
- Successful-stage remaining moves: +100 each; zero for tutorials. Awarded once when the session finishes.
- Booster collections use the same tile base and actual order bonus.

Scoring is independent of win/loss. Invalid swaps award no points. Rebuild/restart resets session score and transient feedback.

## Stars, coins and progression

Every order must be complete before success; existing explicitly required blocker objectives and tutorial coaching completion are also preserved. A high score cannot bypass them. Failure: 0 stars, no completion coins, no remaining-move bonus, no new best record. Winning: 1 star minimum, 2/3 when final score reaches that stage's authored thresholds. ScoreProgress shows targets, not earned stage stars. The route and home retain saved permanent stars.

One reward calculator owns:

`base reward + floor(final_score / score_per_coin) + fixed star bonus + first-clear bonus`

Default conversion: 200 score per coin. Fixed star bonuses for 1/2/3 stars: 0/10/18. First clear: 20 (tutorials 0). Base reward retains authored coin amounts and existing customer reward scaling. Example custom base 40, score 6200, 3 stars and first clear = 40 + 31 + 18 + 20 = 109 coins. Actual balance parameters live in level resources.

First-clear claim is recorded with the win; later wins may improve best_score/stars but never downgrade them. First-clear reward cannot repeat. Coins remain spendable, permanent stars remain cumulative progression. Hearts only decrease once per failed attempt; winning at any rating does not consume a heart. Continuing an already-failed attempt does not consume another heart.

## Save migration

Save version 1 -> 2 is additive. Keeps coins, hearts, existing level stars, best_moves_left, unlocks, recipes and story progress. Adds best_score (0 if absent), completed, first_clear_claimed. Existing cleared stages are considered already claimed, preventing retroactive duplicate first-clear rewards. Stars are never recalculated or reduced during migration. Existing backup recovery and atomic writes remain unchanged. Best score is saved for successful completions only; the failure screen still displays attempt score.

## UI

Gameplay replaces the star/collection pill with readable Score and a target progress bar marked 2-star/3-star. Actual target values are also shown in the pre-stage preview. OrderPanel retains per-kuih counts with a completion check. Combo/Score graphics pop up with live points and actual cascade multiplier. Final results show score, optional New Best, move bonus and controlled coin breakdown; first-clear row is absent on replay. Failure shows score and zero earned reward.

## Verification

Required cases A-J implemented in `tools/score_test.gd`: high-score failure, 1/2/3-star success, monotonic rating, new best, once-only first clear, replay, remaining-move bonus and once-only heart loss. Additional checks cover save round-trip/migration, 3/4/5-match values, cascades, HUD and result values, coin formulas and replay reward integrity.

Score, regression, persistence, heart, Journey and VFX suites passed. Existing persistence recovery/write warnings are deliberate fixtures. Some UI fixtures report small ObjectDB cleanup warnings at exit; no script errors. Rules-only balance harness passed board/special/blocker invariants and every coached lesson (4 seeds each). Two-seed campaign simulation passed; final-score samples saved in `.shots/balance_score_samples.txt` (recorded before the final threshold revision, so its printed star averages reflect the earlier thresholds). The final thresholds were verified against those scores in score tests. Phone screenshots rendered at 360x640: `.shots/01_score_hud.png`, `02_score_combo.png`, `03_score_result.png`, `04_score_failed.png`.

## Remaining tuning

Implementation is complete. Thresholds and economy values are initial authored balance; longer player/device playtests should tune them. A two-seed-per-stage greedy-bot sample completed 59/60 stages (98%); stage 18 was 1/2. Later thresholds were softened using recorded final scores, with representative 2/3-star ratings verified in score tests. This verifies integration, not statistically reliable difficulty. No cloud leaderboard or analytics was requested or added.
