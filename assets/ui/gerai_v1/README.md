# Set UI Gerai — 30 Oktober 2026

Siap: 19 PNG UI dalam folder ini, ditambah `assets/stalls/accessories_v3/hibiscus_counter.png`. Kesemua 20 fail mempunyai saiz tepat seperti permintaan, format RGBA dan latar telus sebenar. Tiada teks dibakar ke dalam imej. Aset dijana menggunakan built-in imagegen; saiz eksport diselaraskan menggunakan Godot. Salinan asal dijana dan draf yang diganti sudah disimpan melalui `tools/backup_design.ps1` sebelum perubahan.

Rujukan permintaan: `design/ChatGPT_Asset_Requests_2026-10-30_Gerai_UI.md`. Rujukan gaya: panel stage_preview_v3, task_panel accessories_v2 dan ikon shop nav_v4. Prompt penuh, laluan sumber, saiz asal/final, hash dan cadangan margin berada dalam `MANIFEST.json`.

## Serahan kepada Claude

Sambungan kod belum dibuat, mengikut pembahagian kerja dalam fail permintaan. Backup `scripts/ui/gerai_screen.gd` dan fail berkaitan sebelum menukar layout atau rujukan aset. Gunakan Label Godot untuk teks, dengan cadangan saiz header 46, progress 32 dan hint 36. Teks perang gelap di atas krim; putih/krim beroutline gelap di atas hijau.

Gunakan StyleBoxTexture/NinePatchRect. Nilai `recommended_slice_margins_left_right_top_bottom` dalam manifest ialah titik mula dalam piksel tekstur sumber, bukan content margins. Uji pada lebar telefon sebenar dan kekalkan bucu di luar kawasan tengah yang diregang. Baris dengan soket dan kaunter dengan ikon memerlukan margin kiri lebih besar supaya ikon tidak diregang.

Hotspot dan ikon ialah tekstur Keep Aspect; jangan gunakan 9-patch. Ketiga-tiga hotspot kini mempunyai bentuk medallion bulat dan tab penunjuk yang sama. Ready ialah bintang emas, locked ialah kunci perang kusam, done ialah tanda putih di atas hijau. Star counter tidak menyertakan butang tambah pilihan.

`progress_track.png` ialah alur kosong. `progress_fill.png` ialah warna merah jambu penuh sepanjang tekstur, tanpa peratus terbakar. Kawal nilai progres melalui clipping/TextureProgressBar, dan letakkan fill dalam inset alur track. Ikon Tasks dan Design ialah objek telus berasingan, bukan butang berbingkai.

Panel list dan complete mempunyai plaque/ribbon pada bahagian atas. Kekalkan tinggi bahagian itu dan elakkan peregangan mendatar melampau; jika layout memerlukan nisbah yang jauh berbeza, paparkan plaque/ribbon sebagai overlay tetap. Margin cadangan masih memerlukan semakan semasa integrasi sebenar.

Preview keseluruhan: `.shots/Gerai_UI_Asset_Set_2026-10-30.png`. Saiz dan alpha semua PNG sudah diperiksa; preview keseluruhan sudah dirender dan disemak. Tiada APK dibina.
