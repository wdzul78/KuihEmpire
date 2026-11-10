# Gula Melaka Syrup Texture

Generated on 2026-11-09 with Codex built-in imagegen. Saved as `assets/blockers/syrup_v1/syrup_texture.png` (1254×1254, opaque). The original is kept in Codex `generated_images`. The previous procedural version is backed up in `.asset_backups/2026-11-09_17-58-44-742_syrup-texture-redesign`.

`GulaMelakaSyrup.draw_puddle` still builds the puddle from rounded cell blobs and bridges, so neighbouring cells merge. The layers are drawn as polygons:
1. Soft shadow.
2. Dark outline (`7a3a10`).
3. Warm rim (`b8621f`).
4. Textured surface.

UVs are computed in puddle space. Overlapping pieces line up without seams. The texture never covers fewer than 2.6 cells.

Prompt:

> A square 1024x1024, fully opaque, top-down close-up texture of glossy Malaysian gula melaka (palm sugar) syrup filling the entire frame, for a cute casual mobile match-3 game. Warm rich amber-caramel to golden honey tones, with gentle darker swirls, a few small round air bubbles, and soft glossy white light reflections. Clean stylized cartoon/painted look matching bright candy-style game art, smooth and liquid, not photographic, not noisy. No container, no plate, no spoon, no border, no edge, no vignette, no text, no objects - only syrup surface everywhere edge to edge. Even lighting so it can be cut into any shape.
