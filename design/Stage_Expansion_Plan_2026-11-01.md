# Plan penambahan peringkat — Kuih Empire

Tarikh: 1 November 2026. Asas: semakan kod semasa pada `master` dan simulasi kesukaran separa.

## 1. Ringkasan

- **Keluaran pertama:** 30 peringkat baharu, 31–60, di Kantin Sekolah. Sasaran versi 0.2.0.
- **Kerja kod:** struktur data peringkat dan Peta Perjalanan perlu dibuka dahulu kerana angka 30 dan tiga dunia ditulis tetap.
- **Halangan utama:** seni baharu untuk peta dan pelanggan melalui ChatGPT, serta lukisan dan fakta resipi yang belum siap.
- **Selepas itu:** 30 peringkat bagi setiap lokasi, sehingga stage 240 mengikut `LocationDefinition`.

## 2. Keadaan semasa

| Bahagian | Status | Rujukan |
| --- | --- | --- |
| Peringkat | 30, ditulis satu per satu dalam `match` | `scripts/levels/level_library.gd:170` |
| Lokasi | 8 lokasi, 30 stage setiap satu, hanya Gerai Keluarga `playable` | `scripts/data/location_definition.gd:42` |
| Seni gerai | 8 lokasi sudah ada `.tres`, latar dan kos bintang 5/8/12 | `resources/stalls/` |
| Tile kuih | 6 digunakan. `kuih_bom`, `seri_muka`, `agar_agar_ros`, `karipap`, `tart` sudah ada seni `cartoon_v3` tetapi belum dipakai | `assets/kuih/cartoon_v3/` |
| Halangan | 6 jenis, semuanya sudah pernah digunakan | `scripts/data/blocker_spec.gd` |
| Pelanggan | 11. Tiada guru atau murid. `festival` belum digunakan dalam mana-mana peringkat | `scripts/data/customer_library.gd` |
| Resipi | 10 dalam katalog, untuk stage 10–100. Semua lukisan belum wujud dan semua fakta masih `RESEARCH_REQUIRED` | `data/recipes/catalog.json` |
| Saiz keluaran | AAB terkini 147 MB | `kuih-empire-0.1.6.aab` |

### Baseline kesukaran

| Stage | Larian | Bot teliti menang | Bot kasual menang | Nota |
| --- | --- | --- | --- | --- |
| 1–9 | 20 | 100% | 100% | Sangat mudah |
| 10, 11, 12, 14, 17, 24 | 20 | 100% | 95% | |
| 13, 15, 16, 19, 21, 25 | 20 | 100% | 100% | |
| 18 | 20 | 95% | 90% | |
| 20 | 20 | 95% | 70% | Paling sukar dalam 1–25 |
| 22, 23 | 20 | 95% | 95% | |
| 26 | 20 | 90% | 80% | |
| 27 | 20 | 85% | 60% | Baki langkah purata 5.4 / 4.3 |
| 28 | 6 | 100% | 100% | Sampel kecil |
| 29 | 6 | 100% | 100% | Sampel kecil |
| 30 | 6 | 83% | 50% | Sampel kecil |

Diukur 1 November 2026. Bot tidak menggunakan booster dan bukan pengganti pemain sebenar. Larian 40 kali bagi 28–30 masih wajar dibuat semasa penalaan Fasa 5.

## 3. Keputusan reka bentuk

Keputusan ini digunakan dalam plan. Tukar di sini jika anda mahu arah lain.

1. **Ikut urutan lokasi dalam kod, bukan laluan negeri dalam Master Plan.** Master Plan mencadangkan Sarawak, Sabah dan seterusnya sehingga stage 190. Kod, seni gerai dan teks permainan pula sudah menjanjikan Kantin Sekolah selepas stage 30.
2. **30 peringkat setiap keluaran, dengan milestone setiap 10.** Ini sepadan dengan keperluan gerai pada stage 40/50/60.
3. **Tiada mekanik enjin baharu dalam 31–60.** Enam halangan sedia ada belum digabungkan sepenuhnya, jadi kepelbagaian datang daripada gabungan dan tile baharu.
4. **Empat tile baharu, bukan lima.** `seri_muka` ditangguh kerana `scripts/core/save_manager.gd:363` menukar `seri_muka` kepada `ang_ku_kueh` dalam save.
5. **Latar gameplay mengikut lokasi peringkat.** Kini `scripts/gameplay/level_controller.gd:90` mengikut gerai aktif, jadi stage 31 akan kelihatan seperti Gerai Keluarga. Skrin Home kekal mengikut pilihan pemain.
6. **Kekal 6 jenis kuih pada setiap papan,** seperti disarankan Master Plan (5–6 jenis), dengan tile bergilir.
7. **Tiada peringkat yang sengaja disukarkan untuk jualan,** seperti ditetapkan dalam Master Plan.

## 4. Fasa kerja

Anggaran ialah sesi kerja, bukan janji masa. Kerja seni bergantung pada ChatGPT dan boleh berjalan selari sejak Fasa 1.

### Fasa 0 — Asas (1 sesi)

- [x] Commit kerja UI semasa supaya plan ini bermula daripada titik bersih.
- [x] Lengkapkan baseline stage 12–27 dengan `--stages=` berperingkat.
- [x] Baiki `exit_flow_test`, `menu_test`, `tutorial_flow_test` dan `onboarding_visual_test` yang sudah gagal, supaya kegagalan baharu mudah dikesan.
- [x] Sediakan fixture save "tamat stage 30" untuk ujian migrasi (`tools/fixtures/save_after_stage_30.json`, `tools/save_after_stage_30_test.gd`).
- [x] Baiki ralat pada skrin Gerai apabila bertukar dari kantin ke Gerai Keluarga, yang ditemui semasa pengesahan.

**Selesai apabila:** baseline lengkap dan semua harness utama lulus.

### Fasa 1 — Struktur data (2 sesi)

Pecahkan `level_library.gd` supaya menambah kandungan tidak menyentuh enjin:

```text
scripts/levels/level_library.gd            API awam dan senarai bab
scripts/levels/chapters/stage_chapter.gd   helper penulisan peringkat
scripts/levels/chapters/family_stall.gd    stage 1–30, dipindah tanpa perubahan
scripts/levels/chapters/school_canteen.gd  stage 31–60, kosong sehingga Fasa 4
```

| Perubahan | Lokasi |
| --- | --- |
| `count()` dikira daripada bab yang didaftarkan | `level_library.gd:55` |
| `SCORE_TARGETS` dipindah ke data setiap peringkat, tiada lagi `clampi(..., 29)` | `level_library.gd:103` |
| `MS_TITLES` dipindah bersama bab | `level_library.gd:27` |
| `background_id` dan peringkat akhir dibaca daripada data bab | `level_library.gd:106`, `level_controller.gd:581` |
| Ganjaran syiling `55 + id*4` dihadkan untuk id > 30 supaya ekonomi tidak melambung | `level_library.gd:137` |
| `JourneyLibrary.MILESTONES` ditambah 40/50/60, `name_for` tidak lagi `mini(30, ...)` | `journey_library.gd:6`, `:16` |
| Teks milestone 30 tidak lagi berkata "akan datang" | `journey_library.gd:9` |
| `playable` dikira daripada kewujudan stage, jadi `school_canteen` dibuka sendiri dalam Fasa 4 | `location_definition.gd:31` |
| Latar gameplay mengikut `LocationDefinition.for_stage` untuk kempen. Tutorial dan Free Play kekal mengikut gerai aktif | `level_controller.gd:90` |
| Ganjaran Free Play milestone membaca `JourneyLibrary.MILESTONES` | `heart_manager.gd:141` |

**Selesai apabila:** stage 1–30 menghasilkan data yang sama seperti sebelum dipecah. Ujian: `tools/level_snapshot_test.gd`, berbanding `tools/fixtures/levels_1_30_snapshot.json` yang diambil daripada kod sebelum dipecah.

### Fasa 2 — Peta Perjalanan berskala (2–3 sesi)

`scripts/ui/journey_map.gd` ialah kerja UI terbesar. Sandarkan dahulu dengan `tools/backup_design.ps1`.

| Masalah sekarang | Penyelesaian |
| --- | --- |
| `WORLD_NAMES`, `for chapter in 3`, `2-chapter` ditulis tetap | Senarai bahagian dalam `JourneyLibrary`: julat stage, dunia, nama |
| Semua dunia dimuat serentak, kira-kira 3.5 MB PNG setiap satu | Muat dunia yang kelihatan dan jirannya sahaja |
| Tiga tab "1–10, 11–20, 21–30" | Pemilih lokasi ◀ ▶ dengan tiga tab bahagian dalam lokasi itu |
| `_nodes[31]` untuk "Akan datang" dalam kamus yang sama | Node papan tanda berasingan, dipindah ke hujung kandungan |
| Semua butang dibina semula setiap kali pilih stage | Hanya kemas kini butang yang berubah, bina butang bagi bahagian yang kelihatan |
| `connectors.png` dua bingkai | Tambah bingkai baharu, termasuk peralihan Gerai → Kantin |
| Butang Kenangan memetakan stage kepada `ROUTE` 0/1/2 | Dipetakan melalui senarai bahagian |
| "Morning Market" dipakai untuk stage 11–20, tetapi lokasi `morning_market` bermula stage 61 | Tukar label bahagian 11–20 kepada "Pasar Kampung" |

**Selesai apabila:** peta tatal lancar pada peranti Android dari 1 ke 60, dan tiada lompatan ketika melintasi lokasi.

Status 1 November 2026: kod siap, dan `tools/journey_scale_test.gd` menguji peta dengan 60 stage olok-olok. Tiga dunia Kantin (`assets/ui/journey_world_v3/`) sudah dipasang dengan titik jalan yang diukur daripada imej. Bingkai penyambung masih dipinjam daripada Gerai Keluarga sehingga seni tiba. Bahagian 31–60 belum dipaparkan kepada pemain kerana stage belum wujud. Ujian tatal pada Android belum dibuat.

### Fasa 3 — Kantin Sekolah sebagai lokasi hidup (1–2 sesi)

- [x] Sahkan latar gameplay Kantin dalam susun atur 8×8 pada 540×960 dan 360×800.
- [x] Selepas stage 30: popup milestone mengajak pemain ke Kantin dan pilihan untuk menjadikannya gerai aktif. Hanya muncul apabila stage 31 wujud.
- [x] Sahkan upgrade pada 40/50/60 dengan `renovation_tasks_test` dan `institutional_canteen_visual_test`.
- [x] Tambah 4 pelanggan dalam `CustomerLibrary` dan semak `CustomerData.line` dalam dua bahasa. Dialog pelanggan sebelum ini tidak diterjemah langsung; kini dibaiki. Lukisan pelanggan masih menunggu ChatGPT.
- [x] Tambah 9 beat cerita dalam `scripts/story/beat_library.gd` (senarai dalam bahagian 5), diikat pada stage dalam Fasa 4.
- [x] Tambah pencapaian `story_2`, `stars_120`, `stars_180`, dengan teks Melayu.
- [x] Sahkan pengenalan kuih baharu untuk tile baharu, termasuk nota Melayu yang sebelum ini tiada.
- [x] Sahkan ganjaran Free Play milestone 40/50/60 dalam `HeartManager`.

Ujian: `tools/school_canteen_test.gd`. Nota: beat `story_after` pada stage milestone tidak dimainkan semasa permainan. Popup milestone mengambil tempatnya, dan beat itu hanya menjadi penanda Kenangan.

### Fasa 4 — Kandungan 31–60 (2–3 sesi)

Bina peringkat mengikut bahagian 5, dalam kumpulan 10, dengan simulasi selepas setiap kumpulan.

### Fasa 5 — Keseimbangan (2 sesi)

Sasaran, diukur dengan sekurang-kurangnya 40 larian bagi setiap stage:

| Jenis | Teliti menang | Kasual menang | Baki langkah (menang) | Kuih/langkah |
| --- | --- | --- | --- | --- |
| Rehat | 100% | ≥ 90% | ≥ 8 | ≤ 1.0 |
| Biasa | ≥ 95% | ≥ 75% | ≥ 5 | 1.1–1.4 |
| Cabaran | ≥ 85% | ≥ 55% | ≥ 3 | 1.5–1.7 |
| Milestone / akhir | ≥ 75% | ≥ 40% | ≥ 2 | 1.6–1.9 |

- Sasaran 2 dan 3 bintang dikira daripada persentil p40/p60 yang dicetak `stage_balance_sim`, kemudian dibundarkan.
- Stage 31 mesti terasa lega selepas stage 30.
- `stage_balance_sim.gd` perlu dipecah kepada beberapa proses kerana larian penuh terlalu lambat, dan juga dikemas kini had `last := 30` kepada `LevelLibrary.count()`.
- Ujian main oleh manusia wajib untuk 40, 50, 57–60. Bot tidak mengukur rasa kecewa.

### Fasa 6 — Pengesahan dan keluaran (1–2 sesi)

Kemas kini ujian yang menganggap 30 peringkat:

| Ujian | Baris |
| --- | --- |
| `journey_test`, `journey_redesign_preview`, `journey_world_preview` | `count == 30`, `_nodes.size() == 31` |
| `heart_test` | `:121` |
| `regression_test` | `:429`, kini memeriksa stage terakhir ialah 30 |
| `persistence_test` | `:39`, `:51`, gunakan `count() + 1` sebagai stage tidak sah |
| `cultural_recipe_test` | `:19` |
| `achievement_ranking_test` | `:75` |

Ujian baharu:

- [ ] Save tamat stage 30 membuka stage 31 tanpa kehilangan bintang, syiling atau hiasan.
- [ ] Save sederhana (stage 12) tidak terjejas.
- [ ] Setiap stage boleh dibina: tile sah, pelanggan wujud, sel halangan dalam papan, tiada sel bertindih, ada tajuk Melayu.
- [ ] Smoke test untuk 31, 40, 50, 60.
- [ ] Ujian Android sebenar: peta, memori, audio, masa muat.
- [ ] Semak saiz AAB. Had modul asas Google Play perlu disahkan semula sebelum muat naik.

Binaan APK atau AAB hanya apabila diminta.

## 5. Reka bentuk kandungan 31–60

**Tile bergilir (6 setiap papan):**

| Stage | Set | Tile baharu |
| --- | --- | --- |
| 31–37 | onde-onde, koci, ang ku, ketayap, lapis, karipap | Karipap (31) |
| 38–45 | onde-onde, koci, ang ku, lapis, karipap, tart | Tart (38) |
| 46–52 | koci, ang ku, lapis, karipap, tart, kuih bom | Kuih Bom (46) |
| 53–60 | ang ku, lapis, karipap, tart, kuih bom, agar-agar ros | Agar-agar Ros (53) |

**Pelanggan baharu:** Cikgu Salmah, Adik Danish, Adik Priya, Pak Mat (jaga sekolah). Pelanggan lama kembali sebagai ibu bapa dan tetamu.

**Petunjuk:** D daun, T tudung, K pengukus, S sirap, B kotak, D2 dulang kosong. "Kuih/L" ialah jumlah kuih yang diminta dan langkah permulaan, untuk ditala dalam Fasa 5.

| # | Tajuk (BM / EN) | Jenis | Fokus | Halangan | Kuih/L |
| --- | --- | --- | --- | --- | --- |
| 31 | Hari Pertama / First Day | Ajar | Karipap, tiba di Kantin | — | 18/22 |
| 32 | Loceng Rehat / Recess Bell | Latih | 2 pelanggan | D×2 | 20/20 |
| 33 | Beratur Ya! / Line Up! | Latih | Giliran 3 | — | 24/22 |
| 34 | Bekal Cikgu / Teacher's Tray | Gabung | Tudung | T×2 | 24/20 |
| 35 | Rehat Tenang / Quiet Break | Rehat | — | — | 20/24 |
| 36 | Stim Kantin / Canteen Steam | Gabung | Pengukus + daun | K×3, D×1 | 28/22 |
| 37 | Tudung Berlapis / Double Covers | Cabaran | Tudung penjuru | T×4 | 30/23 |
| 38 | Tart Cikgu / Teacher's Tart | Ajar | Tart | — | 22/22 |
| 39 | Kotak Bekal / Lunch Boxes | Gabung | Kotak, wajib bersih | B×1 | 30/23 |
| **40** | **Hari Jualan / Sale Day** | **Milestone** | 3 pelanggan, upgrade 1 | D×2, T×2 | 40/25 |
| 41 | Selepas Jualan / After the Sale | Rehat | — | — | 22/26 |
| 42 | Sirap Tumpah / Syrup Spill | Latih | Sirap | S×4 | 28/22 |
| 43 | Dua Giliran / Two Shifts | Gabung | Giliran + dulang | D2×2 | 32/24 |
| 44 | Kawan Sekelas / Classmates | Latih | 3 murid | D×2 | 34/25 |
| 45 | Waktu Senang / Easy Hour | Rehat | — | — | 24/27 |
| 46 | Bom Manis / Sweet Bom | Ajar | Kuih Bom | — | 24/23 |
| 47 | Stim Pagi / Morning Steam | Cabaran | Pengukus 2 lapis | K×4 | 32/24 |
| 48 | Tempahan Kelab / Club Order | Gabung | Kotak + dulang, wajib bersih | B×1, D2×2 | 36/26 |
| 49 | Sirap & Daun / Syrup and Leaves | Cabaran | Gabungan | S×3, D×3 | 36/25 |
| **50** | **Hari Sukan / Sports Day** | **Milestone** | Pesanan besar, upgrade 2 | T×3, K×2 | 48/28 |
| 51 | Rehat Padang / Field Break | Rehat | — | — | 26/28 |
| 52 | Kantin Sesak / Packed Canteen | Latih | Giliran 3 | D×2 | 38/26 |
| 53 | Agar-agar Ros / Rose Jelly | Ajar | Agar-agar | — | 26/24 |
| 54 | Dulang Bersusun / Stacked Trays | Gabung | Dulang, wajib bersih | D2×3 | 38/26 |
| 55 | Mesyuarat PIBG / PTA Meeting | Cabaran | Encik Lim + Cikgu, kotak | B×1, T×2 | 42/28 |
| 56 | Hujan Petang / Rainy Afternoon | Rehat | — | — | 28/30 |
| 57 | Semua Sekali / Everything at Once | Cabaran | 3 jenis halangan | D×2, T×2, K×2 | 42/27 |
| 58 | Latihan Akhir / Final Rehearsal | Cabaran | Sirap + kotak | S×3, B×1 | 44/27 |
| 59 | Malam Persediaan / Prep Night | Cabaran | Pesanan panjang | T×2, K×2 | 46/27 |
| **60** | **Hari Anugerah / Awards Day** | **Akhir** | Semua pelanggan, gerai lengkap | T×4, D×2, K×2, B×1 | 58/31 |

**Ganjaran resipi** mengikut katalog: 40 tebaloi, 50 putu piring, 60 ang ku kueh.

**Beat cerita:**

| Stage | Beat | Isi |
| --- | --- | --- |
| 31 sebelum | `beat_31_canteen` | Aina tiba, kantin lama perlu dihidupkan |
| 38 sebelum | `beat_38_tart` | Cikgu Salmah meminta tart untuk guru |
| 40 selepas | `beat_40_done` | Hari jualan berjaya, murid kembali |
| 45 sebelum | `beat_45_recipe` | Murid bertanya tentang asal kuih |
| 50 sebelum, selepas | `beat_50_sports`, `beat_50_done` | Hari sukan |
| 55 sebelum | `beat_55_pibg` | PIBG meminta tempahan besar |
| 60 sebelum, selepas | `beat_60_awards`, `beat_60_done` | Hari anugerah, jemputan ke Pasar Pagi |

## 6. Permintaan seni dan audio

Semua imej dihantar melalui ChatGPT. Prompt ada dalam `design/ChatGPT_Asset_Requests_2026-11_School_Canteen.md`, mengikut gaya `assets/ui/journey_world_v2/`.

| Aset | Bil. | Keutamaan | Nota |
| --- | --- | --- | --- |
| Dunia peta: pintu sekolah, kantin, padang | 3 | Wajib | Titik `centers.json` disediakan selepas seni tiba |
| Penyambung peta | 3 | Wajib | Termasuk Gerai → Kantin |
| Pelanggan penuh | 4 | Wajib | Selaras dengan `fullbody_v2`, sopan untuk semua umur |
| Lukisan resipi 10 + `family_stall_old` | 11 | Wajib | Sudah diminta dalam fail 30 Oktober, masih menunggu |
| Lukisan milestone Kantin | 1 | Wajib | Untuk popup milestone |
| Komik pengenalan Kantin | 3 | Pilihan | Beat teks mencukupi untuk keluaran pertama |
| Muzik Kantin | 1–2 | Pilihan | Senarai main sedia ada mencukupi |

**Fakta resipi perlu disemak manusia.** Semua teks budaya dalam katalog masih `RESEARCH_REQUIRED`. Saya boleh mendraf, tetapi ia perlu disemak sebelum ditandakan `REVIEWED`. `scripts/ui/recipe_presentation.gd:100` memang mengendalikan teks ini, jadi sahkan paparannya untuk tebaloi, putu piring dan ang ku kueh.

## 7. Risiko

| Risiko | Kesan | Langkah |
| --- | --- | --- |
| Seni lewat | Peta tidak boleh disiapkan | Bina Fasa 1–5 dengan dunia sementara. Jangan keluarkan tanpa seni sebenar |
| Saiz keluaran | 147 MB sekarang. Dunia peta dan pelanggan menambah anggaran 15–25 MB bagi setiap lokasi (berdasarkan saiz PNG sedia ada) | Audit aset versi lama dalam eksport. Pertimbang Play Asset Delivery sebelum lokasi ketiga |
| Save lama | Pemain tamat stage 30 tersangkut atau hilang kemajuan | Ujian fixture dalam Fasa 0 dan 6 |
| Pemulihan versi | `save_manager.gd:275` membuang rekod stage di luar `count()`, jadi versi lama akan memadam kemajuan 31+ | Tiada keluaran turun versi. Kekalkan backup save |
| Kesukaran bot lain daripada manusia | Stage terlalu sukar | Ujian main pada milestone, kemudian telemetri apabila ada |
| Kekaburan visual tile baharu | Karipap, tart dan kuih bom sama warna keemasan | Semak skrin papan penuh awal dalam Fasa 4. Tukar set tile jika sukar dibezakan |
| `seri_muka` | Migrasi menukar ID ini kepada ang ku | Elakkan sehingga migrasi berversi disediakan |

## 8. Selepas 60

| Keluaran | Stage | Lokasi | Tema baharu |
| --- | --- | --- | --- |
| 0.3 | 61–90 | Pasar Pagi | Seri Muka selepas migrasi berversi, resipi vadai |
| 0.4 | 91–120 | Pekan | Reka bentuk papan berbentuk (perlu sokongan sel tidak aktif dalam enjin, kini tiada) |
| 0.5 | 121–150 | Bandar | Tempahan pejabat, pembungkusan |
| 0.6 | 151–180 | Festival Kuih | Mekanik cuaca atau orang ramai |
| 0.7 | 181–210 | Bazar Ramadan | Boleh diselaraskan dengan musim Ramadan |
| 0.8 | 211–240 | Kantin Pejabat Kerajaan | Penutup laluan |

- `RecipeCatalog.validate` mewajibkan satu resipi setiap 10 stage, dan katalog hanya sampai stage 100. Resipi baharu perlu disediakan sebelum 0.4, kerana stage 110 akan gagal pengesahan.
- `RecipeCatalog.TARGET_COUNT` ialah 200 tetapi peringkat dirancang menghasilkan 24 resipi. Tukar kepada lebih daripada satu resipi bagi setiap milestone, atau turunkan sasaran.
- Editor peringkat (Master Plan bahagian 58) berbaloi selepas 0.3, bukan sebelum.

## 9. Definisi selesai untuk 0.2.0

- [ ] Pemain boleh main 1–60 berturut-turut pada Android tanpa ralat.
- [ ] Save lama terus berfungsi.
- [ ] Peta, Gerai, Rekod, Pencapaian dan Kenangan betul untuk 60 stage dalam Melayu dan Inggeris.
- [ ] Sasaran kesukaran dalam bahagian 5 dicapai, dan milestone sudah diuji oleh manusia.
- [ ] Semua seni wajib dipasang, dan tiada teks `RESEARCH_REQUIRED` kelihatan oleh pemain.
- [ ] Regression, smoke dan ujian baharu lulus.
