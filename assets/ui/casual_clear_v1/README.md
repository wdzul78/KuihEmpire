# Clear casual UI kit

Six original transparent, text-free UI assets inspired by the user's warm casual
game reference, adapted to Kuih Empire with pandan leaves and carved wood.
Generated with the built-in imagegen tool. Source pixels are preserved.

Use `CasualUIArt.texture("banner"|"panel"|"green"|"pink"|"orange"|"offer")`
for Godot AtlasTexture resources, or `CasualUIArt.button(caption,color)` for live
text buttons. The artwork is supplied as a reusable kit; existing panel artwork
has not been globally replaced. `tools/casual_ui_preview_scene.tscn` shows usage.

Live UI text uses Fredoka, weight 600 for controls/counters and 700 for titles.
The bundled font is from https://github.com/google/fonts/tree/main/ofl/fredoka
and includes its OFL.txt license. Text is not baked into the generated graphics.
Dark brown text is used on cream; cream text with dark outline on bright buttons.
