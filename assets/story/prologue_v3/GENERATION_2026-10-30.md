# Komik pembukaan — set 30 Oktober 2026

Semua 14 panel diminta telah dijana semula menggunakan built-in imagegen dan disimpan sebagai `panel_01.png` hingga `panel_14.png` dalam folder ini. Setiap fail ialah PNG RGB legap bersaiz tepat **1280×1056**, tanpa bingkai, margin telus atau teks dialog di dalam lukisan. Nisbah angka 1.21:1 diikuti; frasa “taller than wide” dalam prompt ditafsir sebagai lebih tinggi berbanding jalur lama, bukan kanvas potret.

Rujukan watak/gaya: `assets/story/prologue_v2/panels_a.png`, `panels_b.png` dan `assets/characters/fullbody_v2/aina.png`. Gaya, wajah dan pakaian Aina, ibu serta Pak Ya dikekalkan berdasarkan rujukan. Tiga panel awal menambah kenangan gerai meriah, jualan semakin sunyi dan petang sebelum menutup gerai.

Semakan kesinambungan membetulkan panel 08, 10, 11 dan 13: ibu tidak lagi muncul membantu ketika beliau sepatutnya berehat. Panel 08 kini berlaku di lantai rumah pada waktu malam; halaman buku menggunakan ilustrasi kuih dan bunga, tanpa tulisan. Panel 10 juga menggunakan halaman bergambar tanpa tulisan. Sumber draf dan prompt pembetulan dicatat dalam manifest.

`MANIFEST_2026-10-30.json` mengandungi prompt penuh, laluan sumber, saiz asal dan akhir serta SHA-256 setiap panel. Hasil asal yang dipilih dibackup melalui `tools/backup_design.ps1` sebelum penyelarasan saiz eksport. Godot membuat uniform cover fit dan crop berpusat untuk mengekalkan proporsi wajah; tiada lukisan diregang secara tidak sekata. Sheet prologue_v2 asal kekal tersedia sebagai fallback.

## Import dan semakan

Import Godot sudah dijalankan. `OpeningStory.PANEL_ART` sedia ada memuatkan semua 14 fail baharu secara automatik; tiada pindaan pada skrip atau scene produksi diperlukan.

- PASS: saiz 1280×1056 dan gambar legap bagi semua 14 PNG.
- PASS: `tools/story_test_scene.tscn` — deck penuh, dua bahasa, kawalan konsisten, sentuh untuk meneruskan, tamat sekali dan replay.
- PASS: semakan artwork mudah alih — semua 14 halaman menggunakan fail prologue_v3, 28 layout Bahasa Melayu/English muat, enam capture telefon dihasilkan pada 540×960.
- Semakan visual: semua panel pada contact sheet, ditambah contoh paparan telefon dalam kedua-dua bahasa. Claude masih boleh membuat semakan editorial akhir seperti diminta.

Preview keseluruhan: `.shots/Opening_Story_Panels_2026-10-30.png`.
Preview telefon: `.shots/Opening_New_ms_01.png`, `Opening_New_ms_08.png`, `Opening_New_ms_14.png` dan pasangan `en`.

Tiada APK dibina.
