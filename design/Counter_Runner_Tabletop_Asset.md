# Counter Runner: Tabletop Only

Generated on 2026-11-09 with Codex CLI built-in imagegen (`codex exec ... -i reference_runners.png`), using the v1 sheet as the style reference. Saved as `assets/stalls/counter_runner_v2/runners.png` (1536×1024, transparent). The v1 sheet is kept. Scripts are backed up in `.asset_backups/2026-11-09_18-11-34-806_syrup-straight-edges-and-tabletop-runner`.

The sheet has three rows, in `DecorDefinition.STYLES` order:

| Row | Style | Pattern | Region |
|---|---|---|---|
| 1 | original | pink hibiscus batik | `Rect2(32,80,1474,256)` |
| 2 | warm | orange hibiscus batik | `Rect2(30,382,1478,262)` |
| 3 | fresh | green songket | `Rect2(26,698,1486,276)` |

The regions are in `RenovationArt.RUNNER_REGIONS`.

The existing placements are unchanged, because they still describe the old draped cloth. `GeraiBackdrop._draw_decor_texture` draws the new runner only in the top 30% of that placement (`RUNNER_TOP_FRACTION`), which is the counter top. The runner now ends at the table's front edge, and the stall front stays visible.

Prompt:

> Landscape 1536x1024 with a fully TRANSPARENT background (real alpha, no checkerboard, no backdrop, no shadow outside the cloth). Three separate batik table runners stacked vertically, top to bottom, with clear empty transparent gaps between them: 1. pink hibiscus batik with gold borders (like the reference's left cloth), 2. orange hibiscus batik with gold borders (like the reference's middle cloth), 3. green songket with gold diamond motifs and stripes (like the reference's right cloth). Each runner lies FLAT ON A TABLETOP only, seen from the same slightly elevated front view as the reference: a wide, shallow flat rectangle of fabric in gentle perspective (back edge very slightly narrower than the front edge), each about 3.3 times wider than tall, nearly the full image width. The front edge has only a tiny folded lip (a few pixels of hem) - the cloth does NOT hang down or drape in front, no curtain, no skirt, no tassels. No table, no food, no objects, no text. Same painted, rich, warm game-art style and patterns as the reference.

The syrup puddle was changed at the same time. `GulaMelakaSyrup` blobs now have about 17% corner rounding, and the bridges are full thickness, so the puddle edges follow the tile grid.
