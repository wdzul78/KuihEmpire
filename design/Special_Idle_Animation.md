# Special idle animation
Generated with built-in imagegen on 2026-10-04. Original transparent RGBA sprite sheet is preserved at assets/specials/animation_v1/special_sparkle_sheet.png (1254x1254, four equal quadrants). No generated pixels were edited.

## Behavior
- Horizontal/vertical Tapau: 4.5% breathing pulse, straight arrows, intermittent gold glints.
- Dulang: gentler 3% pulse and gold glints.
- Special Order: 5.5% pulse, more frequent star glints (2.2s cycle).
- Hantar: 4.5% pulse and slight +/-0.025 radian sway, glints every 3s.
- The four sparkle frames play at 0.17s per frame, with a quiet interval and staggered starting phases. Empty centers keep icons readable.
- Ordinary kuih do not animate. Setting a tile back to NONE stops the loop, resets icon scale/rotation and hides the overlay.
- Icon child owns idle animation; parent TileView retains swap/clear movement. Scene ownership and pause are inherited. Arrow orientation does not change.

Implementation: scripts/art/special_sparkle.gd and scripts/board/tile_view.gd. One shared sheet is drawn by native texture-region rendering, with no per-frame bitmap copies or particle emitters.

## Validation
Actual 360x640 gameplay screenshot mode --special-animation-only checks all five special types have active loops/overlays, ordinary tiles stay inactive, and changing to NONE resets the artwork. Reviewed .shots/01_special_idle_sparkles.png. Existing --directional-only screenshot assertions confirm transformation-before-cross and transient package cleanup after the added idle animation. Directional rules and delivery tests pass.

## Exact generation prompt
Use case: stylized-concept. Asset type: transparent VFX sprite sheet for a cozy polished cartoon mobile match-3 game KUIH EMPIRE. Generate exactly FOUR animation frames in a perfectly uniform 2 by 2 grid, each quadrant same square size. Reading order top-left, top-right, bottom-left, bottom-right. Each frame has the EXACT SAME CENTER and bounds, contents contained within each quadrant with 15 percent margin. Subject: a sparse circular halo of tiny warm golden diamond sparkle stars and cream glints, surrounding a completely EMPTY transparent center (central 65 percent diameter empty). Frame1: 3 tiny emerging dim glints; Frame2: 5 medium bright glints; Frame3: 5 larger bright golden stars with soft cream highlights; Frame4: 3 fading small glints. Smooth sparkle pulse loop. Crisp dark amber delicate outlines, hand painted polished game VFX. No package, no food, no characters, no letters, no numbers, no frame borders, no grid lines, no backgrounds, no checkerboard, no ground shadows. Actual transparent alpha background across entire sheet, including empty centers and spacing. Perfectly square canvas. Only these four standalone halo frames. Keep very sparse so the underlying directional arrow icon stays readable.


## Current revision: slow smooth wiggle
Replaces the sparkle/pulse presentation at user request. All board specials now keep scale at 1.0 and wiggle using a sine wave over a 4.8s cycle. Directional Tapau maximum angle is 1.2 degrees; other specials 2 degrees. Random starting phases avoid synchronized motion. The loop maintains continuous angular velocity at its boundary. Generated sparkle sheet is retained as an unused asset; TileView no longer instantiates its overlay. Returning to ordinary resets rotation/scale and kills the tween. Screenshot mode --special-animation-only verifies active special loops, fixed scale, small angular bounds and ordinary reset.
