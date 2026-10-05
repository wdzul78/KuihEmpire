# Special Order electrical collection

Special Order connects to every affected kuih with a pale blue electrical bolt, a white core and a small golden glint at the target. Each bolt jitters gently while the package glows.

For phone readability, the blue halo is 14% of the cell width, the cyan line 4.5% and the white core 2.4%, with minimum line widths for small boards.

After a 0.32-second connection phase, ordinary target tiles move inward over 0.42 seconds, shrinking and fading as they enter the package. Electrical endpoints follow the same quadratic motion. Special tiles remain in place for their chain activation; each activation wave finishes its collection before the next wave starts.

Only cells in the logical clear payload are moved. Board gravity/refill starts after collection. Existing Order SFX plays when connections appear; pause affects both the effects and tile tweens. One grouped effect stores up to a full board of endpoints within the existing effect cap.

Color collection targets ordinary kuih only. It ignores other specials' hidden creation kuih, so swapping Special Order with an ordinary kuih does not accidentally activate unrelated Dulang/Tapau/Hantar/Order packages. Direct special swaps and blast chains still activate packages normally.

Implementation: `scripts/art/game_vfx.gd` and `scripts/board/match_board.gd`. Native canvas drawing uses existing glow/sparkle textures; no new raster assets.

Validation: `tools/order_electric_test_scene.tscn` checks the connection phase, inward tile movement, shrinking, cleanup and a 64-target group. The existing VFX suite checks pause, footprints and effect/particle limits.
