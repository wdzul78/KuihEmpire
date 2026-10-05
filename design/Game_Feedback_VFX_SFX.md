# Gameplay feedback

Implemented in GameVfx, MatchBoard, BoardState resolution metadata, AudioManager, SfxSynth and ResultOverlay.

- Normal horizontal/vertical matches: short warm light sweep with sparkle particles and a rising chime layered under cascade pings.
- Tapau / legacy column special: full cross sweep, green ring and sparkles, airy sweep SFX.
- Dulang: exact affected 3x3 footprint highlighted in gold, expanding impact ring, warm pop SFX.
- Special Order: pink connections from the origin to collected kuih, gold highlights and ascending bells.
- Creation: golden sparkles with the existing rising special sound.
- Tray and gift boosters: shared footprint/collection effects and corresponding SFX.
- Stage/tutorial success: bounded pink, gold and green confetti and a new warm six-note fanfare. Failure clears any previous celebration.

SFX are original procedural PCM generated at boot, with existing mute settings respected. No remote audio dependency. One input-transparent canvas per board/celebration, capped at 240 particles and 48 transient effects. Board effects inherit pause, reset on rebuild, and stop processing once empty. Visual feedback consumes actual match and activation payloads including chained specials; scoring and clear rules are unchanged.

Verification: `tools/vfx_test_scene.tscn` checks real row/column metadata, chained activation, special footprint, pause/resume, cleanup, particle cap, non-silent unclipped PCM, mute and success/failure. Rendered phone previews in `.shots/vfx_*.png`. Existing regression suite also run.
