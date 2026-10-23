# Generated stall artwork — 11 October 2026

Codex generated and installed 32 selected portrait background masters: eight locations, each with Old, Revived, Polished and Complete states. These fulfil all 128 menu/gameplay/renovation/journey resource slots through shared references, without duplicate copies. Family Stall Complete and all four School Canteen states use background_v2.png; earlier drafts remain preserved. Other selected images use background_v1.png.

Locations: Family Stall, School Canteen, Morning Market, Town, City, Festival, Ramadan Bazaar and Government Office Canteen. Characters, logo, cat, game board and HUD remain independent foreground layers. Central areas are kept open for mobile UI. Structural upgrades use different authored images, while optional Batik/Pandan artwork falls back to the master until separate variants are supplied.

School Canteen now uses painted masonry columns, fixed fascia, tiled counters with cement tops, stainless prep equipment and long school bench tables. Government Office Canteen is a separate indoor location with individual tables/chairs, office courtyard windows and enclosed glass serving cabinets. Both progress from cosmetic restoration to stainless service counters, then modern lighting and final finishing. City is retained unchanged. Government Office Canteen is appended as a future chapter (211–240); no playable stages are published by this art change.

Reference research: Malaysian school canteen stainless tables from https://www.limsteeleng.com.my/showproducts/productid/6299185/cid/627988/school-canteen-dining-table/ and KKM cafeteria glass display requirements at https://www.moh.gov.my/moh/resources/PDF%20feb%202017/pekeliling_KSU_pelaksanaan_Doc_spec_kontrak_kafe_sihat.pdf . These informed the material/composition choices, rather than copying a particular establishment.

The renovation preview uses top-aligned cover framing to retain the awning. Hotspots map from artwork coordinates into the cropped preview. Other screens use centered cover framing; gameplay retains its background blur. Active-stall selection and purchased state drive all consumers, with a 0.28-second crossfade.

Imports use VRAM compression, no mipmaps and a 2048-pixel size limit. Original PNGs and import settings were backed up before configuring compression. Original source images, layout scripts and resources were separately backed up before changes.

Generated provenance, full prompts, source paths, dimensions and SHA-256 hashes are recorded in GENERATED_ART_MANIFEST.json. The built-in image generation tool was used. ASSET_REQUESTS.md preserves the earlier per-context prompt archive; manual generation is no longer required. Resources can still use separate context images later.

Validation: authored image resolution for all 128 slots; 32 distinct state masters; active selection, milestone gates, three star purchases, persistence/reload/migration, fallback and crossfade tests; rendered mobile Main Menu, gameplay and renovation preview. Government chapter selection is tested with isolated future-stage fixtures; normal migration rejects unpublished stage records. No APK was generated.

This adds environment artwork for future locations, without publishing additional campaign stages. Gameplay beyond the existing Family Stall campaign remains gated.
