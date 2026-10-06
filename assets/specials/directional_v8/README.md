# Layered Tapau directional sprites

Based on the user's eg-01/eg-02/eg-03 board references. Existing source PNGs are copied unchanged:

- `tapau_horizontal_base.png`: user-selected kraft box.
- `tapau_vertical_base.png`: user-supplied stainless carrier with brown handle.
- `direction_triangle.png`: previously generated green/gold marker, rotated at draw time for all four directions.

BoardArt draws the base and two independent direction markers. Tapau idle loop starts when the special is created: arrows fade in over 0.18 seconds, move outward, and fade out by 1.15 seconds. Only the package remains until the 4.2-second cycle repeats. Directional packages stay still; other specials retain their slow wiggle.

Activation stops the idle loop, rapidly flashes the local arrows, and hands them to two outward VFX lanes. Broad glowing, jittering electric lines start at the special's cell center (green row / blue column), while triangle markers travel to the board edges over roughly 0.20 seconds. Electric slot borders and translucent fills flash along the affected row/column. Tiles remain visible until travel finishes; effects fade and clean up over 0.42 seconds. Existing directional footprints and cross combo rules are unchanged.

Validated with rendered 8x8 previews, timed idle/reappearance tests, directional rules and existing VFX pause/cleanup/cap tests.

PNG pixels are preserved. Opaque source regions exclude transparent padding; the old directional_v3 graphics and affected scripts were copied to a timestamped local backup before replacement.
