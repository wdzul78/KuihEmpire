# Journey, heart and tap dialogue MVP

Campaign Play, Next Stage, Restart and Retry open Journey before entry. Select an unlocked stage, then Start. Tutorial lessons remain a mandatory direct onboarding sequence. Journey has three ten-stage chapter pages, scrollable winding paths, completion stars, locks and seen story memories. Stage labels, resource amounts and buttons remain native text for ms/en localization.

Art was generated with built-in imagegen from `Kuih Empire Tropical Map.png`. Separate background, green/gold/grey medallions and heart pill are saved under `assets/ui/journey_v1`. Exact prompts: `design/MVP_Journey_UI_v1.json`. Aina reuses the existing separate character layer.

`HeartManager` config: max 5, failure -1, refill every 1800 seconds, +1 for 500 coins, full for 1800. Entry and wins cost nothing. Tutorial consumes nothing. Refill and Free Play use saved Unix timestamps and recover after offline time. Full hearts pause the refill clock. Three consecutive wins grant 900 seconds Free Play; stage 10/20/30 milestones grant 1800 once each. `start_free_play`, `add_heart` and `full_refill` are reward hooks for future daily/events systems. Failure resets the streak, even during Free Play. Move continuation belongs to the same attempt and never charges another heart.

Heart modal allows waiting, coins, closing and returning to Stall. Meta screens are always accessible. Local saved counters record hearts and coins spent. A rewarded-ad provider must be explicitly registered as a Callable and return boolean true only after verified completion. Without it, ad buttons stay hidden; the heart daily cap is 3, resetting on UTC calendar dates. No ad SDK or simulated ad reward is enabled.

The user supplied `Four-Frame Cartoon Tap Animation.png` is preserved and copied to `assets/ui/gestures/finger_tap.png`. `TapIndicator` reads four 543×724 atlas frames, loops a tap with a short rest, and follows the dialog. Story and tutorial INTRO dialogue raise their bubble above `DialogueSpotlight`; the rest of the screen dims. Action lessons hide both tap prompt and dialog dimming and restore the bubble's drawing order.

Validation commands: `res://tools/heart_test_scene.tscn`, `res://tools/regression_scene.tscn`, `res://tools/menu_test_scene.tscn`, `res://tools/persistence_scene.tscn`. Tests use disposable save paths. Render fixtures: `.shots/30_journey_stage_4.png`, `31_journey_free_play.png`, `32_hearts_empty.png`, `33_tap_dialogue_highlight.png`. Android touch and device lifecycle checks remain for a physical device.
