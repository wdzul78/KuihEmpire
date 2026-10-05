# Booster surfaces without labels

`booster_surfaces.png` is a transparent four-color sprite sheet generated with the built-in imagegen tool. `GameplaySkin` uses one cropped atlas region per button. Icons, inventory badges and locks remain separate UI nodes. Previous graphics remain in gameplay_v2.

Edit target: `assets/ui/gameplay_v2/booster_blue.png`.

Final prompt:

> Use case: precise-object-edit. Create ONE game UI sprite sheet, 1024x1024, transparent background. Edit target reference is the existing blue booster button. Remove entirely the cream caption plaque at bottom, restore a continuous rounded square gold outer frame and glossy colored inset with smoothly rounded bottom corners. Keep gold rim thickness, illustrated polished casual puzzle game style, highlights, straight-on framing. Sprite sheet contains FOUR identical geometry button surfaces in exact 2x2 equally spaced 512x512 cells, each centered within its cell with transparent margins 32 pixels. Top-left cyan/blue (reference color), top-right golden yellow, bottom-left lime green, bottom-right purple. Every button same size and silhouette. Blank surfaces only, no icons, no labels, no letters, no numbers, no cream caption plaque, no small attached rectangles. Real transparent alpha outside buttons. This is one unified four-color button sprite sheet for a game.

The returned sheet is 1254×1254; runtime regions use its actual dimensions. Verified in the rendered gameplay screen after importing into Godot.
