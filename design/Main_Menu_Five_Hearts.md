# Main-menu five-heart health strip

Implemented 2026-10-04. FiveHeartDisplay is used by HomeScreen only, replacing its old numeric heart bar. Gameplay and Journey keep their existing HeartDisplay; gameplay HUD and editable layout anchors are restored.

Five named TextureRects (HealthHeart1 through HealthHeart5) show full red hearts from the left and empty muted cream-gray hearts for missing health. Actual HeartManager state drives the row and refill updates. No new economy/save rules. Clicking the menu strip opens the existing refill dialog. Below-row countdown appears while refilling. Free Play shows five full hearts with the remaining time below.

Generated using built-in imagegen. Original RGBA pixels and alpha preserved; AtlasTexture trims transparent padding without changing image data.
- assets/ui/hearts_v2/heart_full.png
- assets/ui/hearts_v2/heart_empty.png

Code: scripts/ui/five_heart_display.gd; main menu placement in scripts/ui/home_screen.gd.

Validation: heart tests PASS (0–5 full/empty texture mapping, countdown, click opens refill, existing health economy/navigation). Menu tests and gameplay dialogue/layout tests PASS. Reviewed 360x640 main-menu screenshots for full, 3/5 and empty states (--hearts-only). Menu/dialogue fixtures report existing ObjectDB exit warnings. Heart navigation fixture now uses complete_tutorial(), reflecting the newer delivery-unlock tutorial prerequisite.

## Exact full-heart prompt
Use case: stylized-concept. Asset: single FULL health heart icon for mobile puzzle game KUIH EMPIRE. Reference image defines glossy red heart and warm gold rim style. Generate one compact symmetrical red/pink heart, warm thin golden rim and crisp dark brown outer outline, rounded lobes, polished cartoon glossy top-left highlight. Clean simple silhouette readable at 22 pixels, centered, fills 80 percent canvas, no number, no lettering, no plus sign, no ornaments, no glow outside shape, no background, no shadow beyond outline. This is the full state in a five-heart health row. Actual transparent alpha background.

## Exact empty-heart prompt
Use case: stylized-concept. Asset: single EMPTY depleted health heart icon for mobile puzzle game KUIH EMPIRE. Reference image defines heart silhouette, glossy cartoon styling and warm gold rim. Generate matching compact symmetrical heart, rounded lobes and identical proportions: EMPTY STATE with desaturated muted cream-gray recessed inner heart (no red/pink fill), thin warm golden heart-shaped rim and crisp dark brown outer outline. Looks like an empty heart socket, clearly depleted when placed next to full bright red hearts. Subtle inset bevel and restrained highlight, clean silhouette readable at 22 pixels, centered, fills 80 percent canvas. No number, no lettering, no plus sign, no ornaments, no glow outside shape, no background, no external shadow. Actual transparent alpha background.

