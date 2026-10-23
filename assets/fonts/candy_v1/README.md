# Kuih Empire bitmap font

`candy_sheet.png` is the unchanged user-supplied Kuih Empire Candy Font Sheet.
`style_reference.png` is the unchanged Cute Casual Game Font Atlas reference;
its painted background prevents direct transparent bitmap use.

`candy.tres` contains proportional glyph UVs, advances, baseline metrics and a
Unicode fallback. Rebuild with Godot `--headless --path . --script
tools/build_candy_font.gd`. No image generation or replacement of source pixels
is required. Atlas glyphs cover Latin uppercase/lowercase, numbers and common
punctuation; other characters use Godot's bundled font.

UIKit uses this font for dynamic labels, buttons, titles and HUD values. The
project default also covers controls without a UIKit override. Label materials
preserve original candy colors while keeping fade opacity. Existing stylized
logo artwork remains separate. The supplied bold/regular/light reference does
not contain three independently usable transparent font faces.
