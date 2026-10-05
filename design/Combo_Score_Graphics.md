# Combo and score graphics

Generated with built-in image_gen. Transparent PNGs preserved; originals retained in Codex generated_images. Native AtlasTextures crop padding and preserve lettering aspect.

Saved assets: `assets/ui/titles_v1/combo.png` and `assets/ui/titles_v1/score.png`.

## COMBO!

Original: `exec-ab807a13-ce7b-49d5-82ae-2d287192138d.png`

Prompt: Use case: stylized-concept. Asset type: transparent mobile puzzle game feedback lettering for Kuih Empire. Text verbatim: "COMBO!" One horizontal word, no numbers. Bold bouncy rounded cartoon letters with warm ivory highlights, golden yellow to orange bevel, thick chocolate brown outline and subtle caramel drop shadow. Small tasteful green pandan leaf accents only at the outer ends, 2 tiny gold sparkles. Friendly polished hand-painted 2D game art, highly readable on a smartphone. Entire graphic visible with small safe margins, wide horizontal composition. Actual transparent alpha background. No panel, no button backing, no scenery, no characters, no extra words, no watermark.

## SCORE

Original: `exec-17a3c175-0095-4091-96e2-a8f95c284f5e.png`

Prompt: Use case: stylized-concept. Asset type: transparent mobile puzzle game feedback lettering for Kuih Empire. Text verbatim: "SCORE" One horizontal word, no numbers. Bold rounded cartoon letters, cream ivory faces with subtle golden bevel, thick deep green and chocolate brown outline, small glossy highlights. Small tasteful green pandan leaf accents only at the outer ends. Friendly polished hand-painted 2D game art matching a tropical kuih puzzle game, highly readable on a smartphone. Entire graphic visible with small safe margins, wide horizontal composition. Actual transparent alpha background. No panel, no button backing, no scenery, no characters, no extra words, no watermark.

Integration: MatchFeedback shows animated Score +points for cleared kuih and COMBO! on cascades. Numeric values are supplied by StageScoreController using configurable ScoreRules; the displayed multiplier is the actual cascade multiplier (x1.25, x1.5, etc.). Gameplay HUD and final results consume the same stage score. See Score_System_Implementation.md for ratings, rewards and persistence. Popup is input-transparent, paused with gameplay and reset on rebuild.
