# Golden Dulang Sweet Burst

Dulang specials and the Tray power-up share a local 3×3 burst. Gameplay footprints are unchanged.

- Creation: a small 1.2× pop settles over 0.28 seconds.
- Artwork: a polished metallic gold dulang with engraved rim, retaining the three original kuih and pandan leaves. Source: `assets/specials/gold_v1/dulang.png`.
- Idle: the existing slow wiggle stays, with three twinkling glints following the elliptical gold rim.
- Charge: 0.18 seconds; shrink to 0.9×, expand to 1.14×, gather gold sparkles and highlight the nearby 3×3 cells.
- Burst: cream flash, expanding five-petal gold wave, gold particles, and a 0.12-second board shake. Travelling gold glints spread from the centre to each affected slot; each slot receives a warm rounded highlight and four twinkling stars. Corner/edge activations only light in-bounds affected slots. The wave fades over 0.58 seconds and slot lights over 0.72 seconds, with a small distance delay.
- Clear timing: a 0.32-second hold after the burst lets light reach the outer slots before the kuih disappear, including the Tray power-up.
- Special chains: any existing special hit by another special activates once with its own footprint. Activation depth drives successive visual waves, so a dulang can hit a Tapau, which hits another special further away, continuing until no new specials are reached. Overlapping hits do not execute the same tile twice. All tiles stay visible until the chain finishes.
- Audio: the original Cozy SFX v2 `tray_burst` cue plays at the burst, with the existing short haptic for special activation.

Effects use native canvas drawing and existing sparkle/glow textures. They inherit pause and use the existing particle/effect limits. Rebuilding the board cancels the shake and restores its position.

Implementation: `scripts/art/game_vfx.gd`, `scripts/board/match_board.gd`, `scripts/board/tile_view.gd`.

Validation: `tools/vfx_test_scene.tscn` checks special footprints, charge/burst order, pause, cleanup and caps; `tools/dulang_burst_test_scene.tscn` checks the rendered effect, stable idle scale, Tray power-up and interrupted shake recovery.
