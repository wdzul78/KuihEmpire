# Personal Achievements and Journey Ranking

## Audit and implementation plan

- The former Home Achievements action opened a statistics popup; no achievement definitions, rewards, or leaderboard existed.
- SaveManager used local JSON v2, atomic replacement, backup recovery, and normalization. Profile already held name/avatar; settings edit both.
- ProgressionManager stores per-stage permanent best stars, best score, best moves and first-clear claims. Replays retain maxima. Recipe IDs, chapter unlocks, story flags, gerai upgrades and statistics already exist.
- Actual content is one Family Stall story, stages 1–30, milestone completions 10/20/30. Stage 30 unlocks the School Canteen destination, which is future content. Reading a story deck alone is not Story completion.
- Home, Journey, gameplay, stall, recipe book and settings use SceneManager navigation and shared UI helpers.
- No HTTP/WebSocket/multiplayer/account/backend implementation was found in scripts.
- Smallest implementation: retain these sources of truth, add a data-driven achievement manager and campaign event hub, extend the existing profile/save, add one provider-independent ranking model/comparator/service, and replace the statistics popup with a scrollable Personal/Ranking screen. Reuse existing artwork and button styles.

## Delivered behavior

Home → Achievements now opens Personal and Ranking tabs. Fifteen achievements cover Journey, stars, puzzle performance, recipes, orders, special combinations, streak, score and gerai upgrades. Category filters show progress and category completion counts. Bronze/Silver/Gold/Master tiers are supported in definitions; not every achievement uses a tier. Coins are awarded automatically once, and a brief non-interactive notification announces unlocks. Rewards are small recognition bonuses, not gameplay power.

Targets match shipped content: star tiers 30/60/90 (the campaign maximum), recipe explorer 10 and Master the actual recipe-book count. Larger examples such as 300 stars or 50 recipes would be impossible in this MVP and can be authored when content expands.

The profile retains existing name/avatar and adds a random opaque local player_id and title_id. No email or real name is required. A ranking snapshot derives position and stars directly from stage records; it does not persist a second progression ladder. Journey index is 1 for the current campaign. Story/milestone indices describe the furthest **completed** stage, not the next unlocked destination. School Canteen unlock at stage 30 therefore does not pretend the player completed Story 2.

Ranking priority is journey_index, story_index, highest_stage_completed, total_stars, tie_break_score, all descending. Only permanent stars from completed stages up to the furthest stage count. Relevant score is the saved best of the furthest completed stage, not accumulated lifetime score. Coins, purchases and playtime are absent from the ranking model. The derived profile snapshot also exposes order/recipe/achievement counts for personal UI, but these are explicitly ignored by the comparator. Exact metric ties share competition rank; player_id gives stable presentation order only.

Ranking defaults to Current Story, supports All Journey and Current Milestone, and offers Friends as a disabled future option. The visible window surrounds the player's position and the own card stays below the scroll area. Positive next-position hints use stage/star/score differences. Without backend the page explicitly says it is a **local snapshot**. It does not claim a real global rank. There are no weekly resets.

Development builds provide an opt-in sample toggle with fictional names explicitly marked `(sample)` and a SAMPLE DATA notice. Twenty-seven samples cover multiple stories, mid-list player, stages/stars/score ties and an exact tie. Samples are in-memory only; `set_samples` refuses to enable them without the debug feature. Production defaults to the player's local snapshot alone. No online users are fabricated.

## Events and separation

`GameplayEvents` exposes campaign stage_completed, stage_failed, order_served and specials_used. LevelController emits them at the existing guarded transitions; the board contains no achievement logic. Order count increases when a customer is marked served, not for individual kuih collection. A special combination means one clear resolution activating at least two actual special tiles, including triggered chains; merely creating a special or using a booster does not count. Campaign events exclude tutorials.

EconomyManager emits booster_used only when an inventory item is consumed. LevelController tracks usage for the attempt, including selected start specials and extra moves. Stage restart resets attempt state. A failed attempt resets the achievement streak once; continuing it can begin a new streak on eventual win. Abandoned attempts do not count as losses. Tutorial practice neither advances nor breaks this campaign streak. Achievements also listen to existing star/recipe/chapter signals and a new gerai_upgraded signal.

Stage completion replay can advance orders/streak/event achievements, but never duplicates a claimed achievement reward, unique-stage perfection count, or permanent stars. Existing milestone rewards remain owned by ProgressionManager and HeartManager.

## Persistence and migration

Save version 3 extends profile and adds `achievements` records `{progress, unlocked, unlocked_at, reward_claimed}`. Stats add orders_served, specials_used, special_combos, unassisted_wins, achievement_win_streak and best_win_streak. All are normalized and clamped; unknown achievement IDs are not consumed. Coins and claim flags share the same atomic JSON snapshot. Save/reset/recovery behavior remains unchanged.

Old stage/star/score/recipe/gerai records backfill achievements that can be proven. Old saves receive eligible rewards once on reconciliation. Historical order counts, special combinations, booster-free wins and streaks cannot be reconstructed, so start at zero; existing played/won/moves statistics are preserved. Achievements never pretend to know missing history. Current stars and progression remain the existing sources of truth.

## Provider contract and future backend

`LeaderboardService`: get_rankings(filter), get_player_rank(filter), submit_progress(snapshot), refresh_rankings(), refreshed signal. `RankingManager` accepts replacement providers and forwards refresh notifications, so a live screen does not remain subscribed to the old provider. `LocalLeaderboardService` owns local/sample data and uses the single unit-testable RankingComparator. UI reads provider results and does no sorting.

Future RemoteLeaderboardService should implement this contract with asynchronous refresh/caching and loading/error states. Prepare persisted stable player ID plus nickname, avatar, title, journey/story/milestone, highest completed stage, permanent stars, relevant best score, timestamp, game_version and progression_version. No accounts, authentication, HTTP leaderboard, database, anti-cheat server or matchmaking are implemented here.

The server must be authoritative for the same comparator order and validate progress snapshots using stage completion records, stars, scores, sequential unlocks and game/level/progression versions. Clients should submit evidence of progress rather than a claimed rank. Seasonal challenge/festival rankings should be separate systems and must not reset the persistent main Journey.

## Files

- scripts/data/achievement_definition.gd: authored definitions and tier/reward fields.
- scripts/core/achievement_manager.gd: metrics, event listeners, unlocks, single rewards and notification.
- scripts/core/gameplay_events.gd: campaign event hub.
- scripts/data/player_ranking_snapshot.gd and ranking_comparator.gd: derived profile snapshot and ranking rules.
- scripts/core/leaderboard_service.gd, local_leaderboard_service.gd, ranking_manager.gd: provider contract, local/sample implementation and swappable manager.
- scripts/ui/achievements_screen.gd; scenes/ui/achievements_screen.tscn: mobile Personal/Ranking UI.
- Integration: project.godot, SaveManager, ProgressionManager, EconomyManager, LevelController, SceneManager and HomeScreen.
- tools/achievement_ranking_test.gd + scene; updated menu/score tests and screenshot tool.

## Verification

Headless tests pass: ranking cases A–E, exact shared ranks, Journey priority, rewards once across refresh/reload, v2 migration, stable ID, historical backfill, order/combo events, failed streak reset, no-booster win, three-star unique count, milestone/story unlock, profile snapshot, filters, provider replacement, tabs, scrolling and local UI. Existing score A–J, hearts, Journey, persistence/recovery, menu, VFX and gameplay regression suites also pass. Existing UI fixtures report 2–5 ObjectDB exit leaks in some suites; no script errors remain.

Visual review at 360×640 covers Personal, sample ranking and local-only ranking. Own row/card and scrollable achievements remain readable; shared buttons match the game. Screenshots: `.shots/01_achievements_personal.png`, `.shots/02_ranking_samples.png`, `.shots/03_ranking_local.png`.

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . tools/achievement_ranking_test_scene.tscn`.
