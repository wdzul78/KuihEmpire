# Opening story: five pages

The opening deck uses the supplied `design/story-01.png` through `story-05.png`, copied unchanged to `assets/story/prologue_v1`. Godot AtlasTexture regions extract the illustrations without stretching their proportions or displaying the baked navigation controls.

All five pages share one responsive cream panel, heading, illustration area, native wrapped body text, five page markers, page counter, and pink Continue button. The button uses the explicit painted bounds `(34, 183, 2105, 340)` of the existing results asset to exclude transparent padding. Its size and position stay constant through the final “Let’s Begin” page.

A looping four-frame finger-tap indicator points at the right end of the Continue button on every page. It uses the supplied gesture asset and ignores input, so tapping the hand or elsewhere still advances normally. TapIndicator supports an optional target anchor; tutorial dialogue retains its original placement below the bubble.

Malay and English headings, narrative text, quotes, buttons and hints are native UI. The original decorative shop signs remain part of the supplied artwork. Quotes on pages four and five have native cream overlays with a pointer towards Aina.

The existing prologue ID and navigation are preserved: first-time opening leads into the mandatory tutorial; finishing marks the story read. Journey memories can replay the same five-page deck. Skip remains available only when the caller permits it. A tap anywhere outside a navigation button advances exactly one page; Previous explicitly returns to the prior page. Finishing is idempotent.

Validation: `tools/story_test_scene.tscn` checks five illustrations, both languages, identical primary button dimensions, heading/body/quote fit, tap-anywhere navigation, single finish, saved read state and replay. Run with `-- --capture` using a rendering backend to save all ten localized pages to `.shots/`. Test snapshots are verified at 540×960 and 360×640.
