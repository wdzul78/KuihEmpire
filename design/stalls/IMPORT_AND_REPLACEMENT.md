> Current artwork: 32 masters across eight locations fulfil 128 context slots. School Canteen uses institutional v2 art; Government Office Canteen is an additional future location. See GENERATED_ART_REPORT.md for the current status.

> Update 11 October 2026: 28 generated masters are installed and fulfil all 112 context slots. See GENERATED_ART_REPORT.md for the current state. Earlier asset requests below are retained as reference.

# Background import and replacement

1. Generate final art separately in ChatGPT using ASSET_REQUESTS.md. No generated or placeholder raster assets are required by the code.
2. Put images in their declared assets/stalls/... slots. Prefer 1080x1920 RGB masters; use WebP if desired, and edit the corresponding resources/stalls/<id>.tres property. Avoid importing 4K masters to low-end phones.
3. Open Godot once to import. Run the optional helper: ./tools/configure_stall_imports.ps1. This modifies only existing .import settings for assets/stalls textures and backs them up first. Reimport in Godot afterward.
4. Texture defaults: VRAM compression (ETC2 enabled in project for Android), mipmaps off for full-screen 2D backgrounds, linear sampling. Inspect compression quality on target Android. Use lossless/VRAM-uncompressed when artefacts are unacceptable; this increases memory. PNG/WebP disk compression alone does not reduce decoded GPU memory.
5. GeraiBackdrop uses uniform max(width ratio,height ratio) cover scaling and centred crop. Backgrounds fill 9:16 and taller screens without stretching; foreground/UI remain independent. Put essential objects safely inside central horizontal crop margins. Renovation hotspots use normalized locations in each StallState; adjust those data coordinates if final composition moves objects.
6. Loading is lazy: only the current context's texture is loaded. The component retains at most one previous texture for a 0.28-second crossfade and releases it afterward. Resources store paths, not preloaded Texture2D instances. Rough baseline 1080x1920 RGBA8 = 7.91 MiB per uncompressed texture; two during transition = 15.82 MiB, before other UI/character textures and driver overhead. ETC2 is typically smaller. These estimates are not a device profile.
7. Optional batik/pandan artwork goes under state/variants/<variant>/<context>_bg.png. If absent, the base image is reused; temporary procedural backgrounds use a different accent stripe for variants. All choices have identical progression and price. Fully authored images require variant images to show distinct styles.
8. No .asset_backups paths enter runtime/export. Existing export exclusion remains unchanged. No APK was built.
