# Kuih Empire MVP status and bug priorities

Audit pada 3 Oktober 2026 berdasarkan kod projek dan harness Godot. Projek sudah mempunyai playable vertical slice dengan 30 campaign stage dan 8 tutorial. Sasaran seterusnya ialah stabilkan flow dan buat Android playtest sebelum menambah monetisasi atau kandungan baharu.

## Kemajuan sebenar

| Bahagian | Status berdasarkan kod |
| --- | --- |
| Match 3, swap, cascade, special, blocker | Sudah dilaksanakan dengan logic terasing dalam BoardState |
| Customer order, queue, surplus | Sudah dilaksanakan; race semasa animasi serve diperbaiki |
| Prologue dan tutorial T1 hingga T8 | Sudah dilaksanakan; tutorial asing daripada campaign |
| Campaign | 30 stage dalam LevelLibrary, termasuk finale |
| Home, Journey Map, Recipe Book, Gerai, Settings | Sudah dilaksanakan melalui UI yang dibina dalam skrip |
| Save, coin, star, recipe, mastery | Lokal JSON; tiada cloud save |
| Grafik dan audio | Grafik procedural dan bunyi sintesis; belum art/audio final |
| Ads dan IAP | Stub; belum integrasi provider atau pembelian sebenar |
| Android release | Belum disahkan; tiada export preset dalam folder projek |
| Analytics | Counter lokal sahaja; belum telemetry backend |

README dan master plan ialah rujukan utama yang ditemui. Tiada AGENTS.md atau task tracker berasingan ditemui dalam folder projek. Semua fail sumber muncul sebagai untracked dalam Git ketika audit; sejarah commit tidak dapat digunakan untuk mengesahkan kerja OpenCode terdahulu.

Skop kod sudah melebihi minimum master plan dalam beberapa bahagian: 12 kuih dan 6 jenis obstacle berbanding sasaran MVP 6 kuih dan 3 blocker. Cadangan ialah bekukan penambahan ciri sementara dan fokus pada flow 30 stage yang sudah ada. Kriteria kefahaman pemain, game feel dan retention masih memerlukan playtest manusia.

## Bug yang sudah diperbaiki

| Keutamaan | Masalah | Pembaikan |
| --- | --- | --- |
| P0 | Panel result kekal hidden selepas menang atau kalah, menyekat sambungan flow | show_win dan show_fail mengaktifkan visible |
| P1 | Replay story bergantung pada callback Home atau Journey yang telah dibuang semasa pertukaran scene | Destinasi pulang dimiliki oleh SceneManager |
| P1 | Booster dan restart boleh bertindih dengan animasi board | Guard busy dan enabled; booster mengunci board hingga resolution selesai |
| P1 | Refill booster meninggalkan match atau board tanpa legal move | Cascade dan dead board shuffle dijalankan sebelum settled |
| P1 | Dulang mengira kuih tengah dua kali; target tidak sah boleh menghabiskan inventory | Totals bermula kosong; target disahkan sebelum penggunaan |
| P1 | Cascade semasa animasi serve boleh memulakan serve bertindih dan menulis semula active_index | Giliran order dikemas kini secara synchronous; satu queue animasi serve |
| P1 | Coach special tidak menerima event kerana logic belum dibina ketika connection dibuat | Controller mendengar signal view yang dihantar dari resolution sebenar |
| P1 | Swap tidak sah meninggalkan dua tile pada koordinat visual yang salah | Animasi pergi sedikit dan kembali ke posisi asal |
| P2 | Tile baru selepas refill kekal pada scale 0.8; hint membesarkan tile | Refill animasi kembali ke scale 1; hint menggunakan ring pulse |
| P2 | Home menawarkan stage 31 selepas tamat 30 stage | current_level dihadkan kepada campaign terakhir untuk replay |
| P2 | Typo cell.kuish dalam blocker fallback dan collect_all | Nama property diperbetulkan kepada kuih |
| P2 | Statistik move tidak ditanda untuk autosave; mobile background belum flush | mark_dirty untuk move; flush pada application paused |
| P2 | New Best ditunjukkan pada setiap campaign win; butang Watch Ad muncul hanya kerana ada booster | Bandingkan previous stars; ad hanya muncul jika setting ad diaktifkan |

## Urutan kerja MVP seterusnya

1. **P1 Save resilience:** validasi nested JSON, temporary-file replacement dan backup sudah dilaksanakan pada 4 Oktober. Ujian malformed data, recovery, reset dan write failure lulus. Baki: uji tutup paksa dan suspend/resume Android serta gangguan storage sebenar.
2. **P1 Android build dan playtest:** sediakan export signing/preset yang sesuai, uji sentuhan sebenar, nisbah skrin, safe area, audio dan prestasi pada peranti sasaran. Desktop OpenGL tidak membuktikan Android stabil.
3. **P1 Pause dan lifecycle:** board tween dan timer serve kini berhenti semasa pause. Resume, duplicate menu, blocked restart serta pertukaran scene daripada level paused sudah diuji. Background notification juga membuka pause pada level aktif. Baki: device lifecycle dan polisi audio semasa background.
4. **P2 Tutorial dan level balance:** main sebagai pemain baharu, semak gesture/hint selepas board berubah dan bilangan move selepas budget tutorial habis. Ukur kesukaran tanpa bantuan bot.
5. **P2 UI dan progression polish:** semak reset Settings, pembukaan chapter, recipe unlock, label finale dan gerai maksimum. Pastikan label dan status konsisten dengan state sebenar.
6. **P2 Art dan audio:** gantikan placeholder selepas flow stabil; kekalkan silhouette kuih yang jelas pada telefon.
7. **P3 Ads, IAP dan telemetry:** buat selepas MVP boleh dimainkan dan save stabil. Butang rewarded ad masih stub jika setting diaktifkan; jangan aktifkan dalam release sebelum provider siap.

## Semakan

Engine yang tersedia ketika audit: Godot 4.7.2 stable, renderer GL Compatibility. Import editor berjaya. Rules harness merangkumi invariants, special, blocker, tutorial layout dan 240 simulasi campaign. Keputusan akhir PASS; greedy bot menang 95% keseluruhan, stage paling rendah 75%. Ini ukuran bot dan bukan jaminan kesukaran untuk pemain manusia.

Regression harness menggunakan fail save ujian berasingan dan menguji navigation story sebenar selepas skrin pemanggil dibuang, result visibility, invalid swap, hint scale, kiraan Dulang, busy booster, invalid target, cascade selepas booster, queue serve dan finale. Keputusan PASS dengan 0 masalah.

```powershell
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/test_runner.gd
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tools/regression_scene.tscn
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-driver opengl3 res://tools/smoke_scene.tscn
```

Smoke test OpenGL akhir PASS dengan 0 masalah. Harness menguji semua skrin, prologue, 8 tutorial, swap, booster serta result pada stage 1, 7 dan 30. Tiada output error pada run OpenGL akhir. Screenshot harness menghasilkan 16 PNG dalam .shots; tutorial pertama dan stage 30 turut diperiksa secara visual. Ini belum menggantikan playtest Android dan pemeriksaan visual semua keadaan result/overlay.

Log semakan disimpan sebagai fail lokal yang diabaikan Git: .rules-final-test.log, .regression-test.log, .smoke-gl-test.log dan .smoke-gl-errors-test.log. Harness smoke juga diperbaiki supaya menunggu animasi serve dan mengasingkan ujian booster daripada objective level yang pendek; ia kini menyemak result visibility serta event special tutorial.

## Sambungan development pada 4 Oktober 2026

- Logo sementara yang diberi pengguna dipasang pada Boot dan Home melalui assets/ui/logo_temp.png. Fail disalin tanpa mengubah imej; checksum sama dengan sumber. Alpha sebenar disahkan dan preview kedua-dua skrin diperiksa pada 540 x 960.
- Story completion kini merekod story_read dalam SceneManager. Callback lama Boot telah dibuang kerana Boot dilepaskan ketika bertukar ke story.
- Save menapis container dan nested value untuk coins, booster, settings, stage record, mastery, gerai, stats, tutorial dan senarai unlock. JSON separa mendapat default; nombor negatif dibatasi dan rekod stage luar campaign dibuang.
- Temporary file ditulis dan di-flush sebelum rename menggantikan save. Backup menyimpan snapshot sebelumnya yang boleh dibaca. Reset menggantikan backup juga supaya recovery tidak mengembalikan progress yang telah direset. Ini belum menjamin durability terhadap semua kegagalan hardware/filesystem.
- Pause kini menggunakan SceneTree pause dengan overlay yang masih boleh menerima input. Timer serve menggunakan process_always=false; resume menyambung animasi yang sama. Keluar daripada level paused mengembalikan tree kepada keadaan tidak paused.
- KuihIcon kini menggunakan KuihData.texture jika tersedia dan mengekalkan aspect ratio. KuihLibrary mengesan PNG assets/kuih berdasarkan ID semasa game bermula; tanpa PNG ia melukis placeholder lama. Integrasi special Lapis/Keria/Bom dan perubahan 3 tutorial asas + 5 pelajaran campaign masih belum dibuat.
- Persistence harness baharu PASS. Regression harness tambahan menguji pause sewaktu swap/serve, duplicate pause, app background dan story read. Ujian memakai save berasingan daripada save pemain.
- Screenshot harness menghasilkan 17 skrin termasuk Boot. Smoke OpenGL merangkumi semua 8 tutorial dan stage 1, 7, 30 dan lulus. Terdapat warning shutdown untuk dua instance audio (AudioStreamWAV/AudioStreamPlaybackWAV) pada sesetengah harness; belum diselesaikan, tanpa script error dalam run akhir.

Rujukan API untuk implementation pause dan file replacement: [Godot pause](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) dan [DirAccess rename](https://docs.godotengine.org/en/stable/classes/class_diraccess.html#class-diraccess-method-rename).
