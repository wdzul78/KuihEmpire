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
& 'F:\WDzul78\Documents\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . res://tools/balance_scene.tscn
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
- KuihIcon kini menggunakan KuihData.texture jika tersedia dan mengekalkan aspect ratio. KuihLibrary mengesan PNG assets/kuih berdasarkan ID semasa game bermula; tanpa PNG ia melukis placeholder lama. Special match 4 Lapis sudah menggunakan aset sebenar dan clear baris; Kek Lapis Sarawak clear kolum. Tutorial T4 menerima kedua-dua jenis dan menjelaskan arah. Integrasi Keria/Bom, set tile biasa baharu dan perubahan 3 tutorial asas + 5 pelajaran campaign masih belum dibuat.
- Persistence harness baharu PASS. Regression harness tambahan menguji pause sewaktu swap/serve, duplicate pause, app background dan story read. Ujian memakai save berasingan daripada save pemain.
- Screenshot harness menghasilkan 17 skrin termasuk Boot. Smoke OpenGL merangkumi semua 8 tutorial dan stage 1, 7, 30 dan lulus. Terdapat warning shutdown untuk dua instance audio (AudioStreamWAV/AudioStreamPlaybackWAV) pada sesetengah harness; belum diselesaikan, tanpa script error dalam run akhir.

Rujukan API untuk implementation pause dan file replacement: [Godot pause](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) dan [DirAccess rename](https://docs.godotengine.org/en/stable/classes/class_diraccess.html#class-diraccess-method-rename).

## Semakan special Lapis — 4 Oktober 2026

- Match 4 mendatar menghasilkan Kuih Lapis dan clear satu baris; menegak menghasilkan Kek Lapis Sarawak dan clear satu kolum. PNG sumber disalin tanpa perubahan ke assets/specials.
- Ikon special menunjukkan arah dan badge jenis kuih asal. Tutorial T4 sebenarnya menghasilkan match mendatar Seri Muka; teks, gate dan ujian kini selaras dengan layout.
- Rules, blocker dan 8 tutorial lulus; regression UI lulus; 18 screenshot berjaya dirender termasuk preview kedua-dua special.
- Simulasi 240 campaign: win rate keseluruhan 89% selepas special dipisahkan (sebelumnya 95%). Stage 18/23/26/28/30 kini di bawah sasaran bot 75%; rebalance move/order perlu playtest susulan. Tiada budget level diubah dalam perubahan grafik ini.
- Cadangan tile biasa: Ang Ku, Onde-onde, Seri Muka, Vadai, Koci dan Karipap. Koci menggantikan ordinary Lapis; pilihan ini belum diterapkan pada campaign atau save. Keria dan Bom kekal aset untuk integrasi seterusnya.
- Smoke runtime akhir lulus (0 problems): 8 tutorial, stage 1/7/30, booster, pause/restart dan result overlay. Harness kini menunggu animasi invalid swap selesai sebelum meminta booster.

## Integrasi visual MVP — 4 Oktober 2026

- Rujukan Sweet Match Adventure digunakan untuk tujuh aset imagegen: latar gerai, Aina, Ketayap dan empat ikon booster. Prompt penuh dan destinasi disimpan dalam design/MVP_Visual_Assets.json. PNG transparan disahkan mempunyai alpha 0–255.
- Enam tile biasa kini Onde-onde/Koci/Seri Muka/Ketayap/Ang Ku/Vadai; special Lapis baris, Sarawak kolum, Keria 3x3 dan Bom satu jenis menggunakan PNG. Koci menggantikan Lapis biasa dalam data campaign/tutorial/recipe; unlock dan mastery save lama dimigrasi.
- Alpha bounds digunakan untuk ukuran sprite yang sekata tanpa mengubah fail sumber. Backdrop MVP dikongsi semua chapter sementara; Aina menggunakan satu pose gembira sementara.
- Ujian akhir: import, rules/blocker/8 tutorial, persistence termasuk migrasi, regression UI, runtime smoke dan 18 screenshot PASS. Scene playtest stage 18 juga berjaya dibuka tanpa script error.
- Buka tools/visual_playtest_scene.tscn dan tekan F6 untuk ujian grafik dengan save berasingan. Baki: playtest pemain sebenar, rebalance lima stage yang dicatat di atas dan prestasi Android.

## Pilihan visual kartun v2 — 4 Oktober 2026

Arahan terbaru pengguna mengembalikan special klasik: match 4 mendatar/menegak menghasilkan Tapau (clear baris DAN kolum), L/T menghasilkan Dulang (3x3), match 5 lurus menghasilkan Special Order (satu jenis kuih). Booster kekal inventory berasingan.

Enam sprite kartun baharu mengikuti reference Sweet Match Adventure: Onde-onde, Lapis Pandan, Koci PUTIH, Ketayap, Keria dan Kuih Lapis merah jambu. Koci merah jambu yang dijana semasa percubaan telah ditolak dan tidak dipasang. Dulang berisi kuih serta clipboard Special Order juga dijana; Tapau menggunakan kotak beriben. Fail asal dipelihara, active set dalam assets/kuih/cartoon_v2 dan assets/specials/cartoon_v2. Prompt penuh dan migration map ada dalam design/MVP_Cartoon_v2_Assets.json.

Migrasi save: Seri Muka → Lapis Pandan, Ang Ku → Kuih Lapis, Vadai → Keria, mengekalkan unlock/mastery. Nilai enum special kolum lama dikekalkan untuk compatibility sahaja dan kini berfungsi sebagai Tapau. Preview terbaru ialah .shots/14_classic_specials.png; scene F6 kekal tools/visual_playtest_scene.tscn.

Semakan kartun v2 akhir: import, rules/blocker/8 tutorial, 240 simulasi campaign (95% win rate; semua stage mencapai sasaran minimum 75%), save migration, regression, runtime smoke (0 problems), playtest entry dan 18 screenshot lulus. Had masa smoke booster kini mengikut budget stage kerana cascade Tapau boleh melebihi 8 saat. Baki: playtest manusia dan pengesahan Android.

## Watak penuh dan dialog atas — 4 Oktober 2026

Aina penuh termasuk kasut dan 11 pelanggan menggunakan PNG telus dalam assets/characters/fullbody_v2. Encik Lim dan Mei Ling menggunakan versi v3 bermata badam lebih sempit; Meena pelanggan India; Rider Din menggunakan helmet, jaket hijau dan beg penghantaran tanpa jenama. Stage 18 memperkenalkan Mei Ling dan Meena dengan tuning order/reward yang sama seperti pelanggan diganti. Semua prompt built-in imagegen dan pemetaan asset aktif ada dalam design/MVP_Character_Assets_v2.json.

Gameplay: pelanggan kiri, Aina kanan, dialog/order tengah, board kayu dan booster di bawah. Dialog pembukaan bergilir pelanggan/Aina dengan highlight penutur. PNG watak dipaparkan penuh tanpa crop; thumbnail queue menggunakan crop kepala. Tajuk panjang tidak lagi melebarkan HUD keluar skrin. Cover/Steamer kini berada di atas kuih, membetulkan halangan yang terlindung oleh PNG tile.

Tutorial 7 mengajar queue sahaja; Steamer ditangguh ke campaign 21 dengan dialog pengenalan. Penutup satu hit dibuka oleh match bersebelahan; stage 30 mempunyai versi dua hit. Cadangan struktur kandungan: 20 stage utama/stall serta 8 tutorial berasingan, sebagai keputusan reka bentuk (bukan standard wajib). Kempen 30 stage sedia ada dikekalkan untuk playtest MVP.

Semakan: Godot import, rules/special/blocker/8 tutorial, runtime smoke (0 masalah), regression termasuk pertukaran penutur dan lapisan blocker lulus. 23 screenshot dirender pada window 540x960 dan 360x800; judul panjang, customer 3 jenis dan rider diperiksa. Preview pelanggan: .shots/19_customer_encik.png, .shots/20_customer_meiling.png, .shots/21_customer_meena.png, .shots/22_customer_runner.png. Android/peranti sebenar masih belum diuji.

## Layout Sweet Match Adventure — 4 Oktober 2026

HUD kini menggunakan perkadaran rujukan: logo besar kiri atas; coin dan progress collection di atas; settings kanan atas; moves pada papan gantung; dialog dan order di bahagian atas; board berbingkai kayu emas dengan alas daun pisang; dulang empat booster di bawah. Pelanggan kiri dan Aina kanan dikekalkan mengikut arahan watak sebelumnya. Koci kekal putih dan board campaign kekal 8x8; rujukan tidak digunakan sebagai papan gameplay statik.

Progress bintang menunjukkan jumlah kuih yang dikumpul untuk semua order stage, bukan XP rekaan. Order chips kini memaparkan nama kuih. Restart dan booster +5 dipindah ke menu pause; empat booster utama ialah Sudip, Dulang, Shuffle dan Tapau. Preview .shots/20_customer_meiling.png dan .shots/22_customer_runner.png. Regression mengesahkan progress sebenar, empat booster, menu +5, lapisan blocker dan tiada overlap dialog/order atau board/booster.

Karakter gameplay dibesarkan untuk paparan dari kepala hingga sekitar pinggang, dengan tubuh penuh meneruskan di belakang board. CharacterIcon menyembunyikan bahagian di bawah tepi atas board termasuk di luar sisi bingkai supaya kaki tidak bocor di tepi. Aset PNG penuh kekal untuk kegunaan skrin lain; thumbnail queue kekal kecil. 23 screenshot dirender semula tanpa script error dan preview pelanggan/rider disemak.

## Layered main menu — 4 October 2026

The home screen now follows the supplied main-menu composition. Eight new PNG assets live in `assets/menu/v1`: clean background, slimmer full-body Aina, sleeping cat, foreground kuih tray with blank chalkboard, and four navigation icons. The existing dessert logo remains its own layer. Aina, cat and logo have subtle independent transform animations; these are scene layers rather than a skeletal character rig. The original Aina asset is preserved and gameplay portraits remain unchanged.

All menu captions, tagline and settings text are native editable UI, with Malay/English strings in `scripts/ui/menu_text.gd`. Settings saves a player name (24 characters maximum) and language. Profile level earns one level per ten campaign stars, with real saved star progress. The header uses actual coins and earned stars; no diamond economy is introduced. Records shows local stage results, while achievements shows real stage/star/recipe progress. Journey and Recipe Book remain reachable.

Exact built-in imagegen prompts and layer notes: `design/MVP_Main_Menu_Layers.json`. Open `scenes/menu/home.tscn` and run F6 to preview, or run the project normally. Preview screenshots are generated with `tools/screenshot_scene.tscn`. Functional menu tests use `tools/menu_test_scene.tscn` and a separate test save. Menu tests and existing regression tests passed; the 540x960 render was inspected.

### Main menu visual refinement v2

Matched the original menu reference more closely: painted wood-and-cream navigation panels with integrated book, trophy, stall and achievement icons; a glossy green Play surface on wooden planks; a painted wooden tagline ribbon. Six built-in imagegen assets and exact prompts are saved in `assets/menu/v2` and `design/MVP_Main_Menu_Refinement_v2.json`. Labels and the play glyph remain native editable UI. Navigation still uses real local player records, not an online ranking service.

Aina is larger and top-aligned within her waist crop. Logo and the foreground chalkboard/kuih tray are enlarged. Godot AtlasTexture trims transparent panel/banner margins without changing the source PNGs. Hover, pressed and keyboard focus remain native button states. Menu tests passed and the final 540x960 render was checked for overlap, labels and encoding.

### Gameplay HUD art v2 and upper tutorial coaching

Removed the small bottom Aina/tutorial card from gameplay by routing TutorialCoach into the existing upper OrderPanel dialogue. Tutorial titles, instructions and nudges remain available above the order board. Intro steps accept mouse/touch taps on that dialogue. The four-booster tray is visible on every lesson; tutorials 1–7 lock usage, tutorial 8 and campaign stages allow inventory-backed use. Controller guards prevent consuming locked boosters through direct requests or targeting.

Eleven new transparent imagegen assets in `assets/ui/gameplay_v2` restyle the coin pill, star, progress frame, settings button, hanging moves sign, order board with leaf corners, wooden booster tray and four glossy booster surfaces. Numeric progress and captions remain live UI. GameplaySkin trims transparent export margins using native AtlasTexture regions; original PNG pixels are retained. Exact prompts are in `design/MVP_Gameplay_UI_v2.json`.

Validation: Godot import and final 540x960 gameplay/tutorial renders checked; regression passes including upper dialogue taps, visible booster tray and early tutorial locks. Full smoke test passes all eight tutorial lessons plus stages 1/7/30 and booster/pause flows. Existing four ObjectDB shutdown warnings remain in the smoke harness.

### Locked tutorial boosters

Tutorials 1–7 show desaturated booster surfaces with a native padlock icon replacing the food/tool artwork. Inventory badges are hidden while locked. Tutorial 8 and campaign stages restore the original booster artwork and stock badges; disabled empty inventory remains distinct from progression locks. The existing controller guards continue to prevent locked use. Regression checks cover both locked and unlocked icon states, with tutorial 1 rendered and inspected.

Gameplay refinement v3: replaced green Lapis Pandan with red Ang Ku; preserved pink Kuih Lapis and migrated recipe/mastery progress. New smooth keria donut and cream speech bubble assets in assets/kuih/cartoon_v3 and assets/ui/gameplay_v3. Fixed bounded Order icon/name/count layout and integrated star meter. Bubble tail flips toward Aina (right) or customer (left), while text stays readable. Prompts: design/MVP_Gameplay_Refinement_v3.json. Rules and persistence tests passed. Invariant harness now mirrors MatchBoard's existing reshuffle after dead cascades.

Main menu header v3: painted profile/medallion frame, illustrated gold counter, saved diamond balance (default 0), matching brown gear settings button. Book navigation now opens Recipes; Map points open stage play plus already-read chapter decks and seen stage beats, including the stage 30 finale point. Replay preserves progress and names customer correctly. New art assets in assets/menu/v3; built-in imagegen prompts in design/MVP_Menu_Header_v3.json. Menu/save tests and Godot renders verified. Diamond earning/spending is not introduced by this UI change.

Order layout refinement: wider wooden board, larger warm caramel icon insets, clearer centred kuih names and compact collected/target counters. Font sizes fit the actual item area at each viewport; three-item render fixture uses Onde-onde 6/10, pink Kuih Lapis 3/8 and white Koci 1/6. Regression navigation updated for Recipes and map story replay.

Board/counters artwork v4: separate painted wooden frame and banana-leaf slot assets (assets/ui/board_v1), plus matching hanging MOVES plaque and integrated star/progress meter (assets/ui/gameplay_v4). Board reserves internal frame padding; native nine-patch keeps border thickness consistent for tutorial and 8x8 boards, and hit coordinates share the padded cell layout. Dynamic move/progress labels remain native; no baked numbers. Built-in imagegen prompts: design/MVP_Board_And_Counters_v4.json. Regression passed; 3x3 and 8x8 renders inspected.
# Header, journey and temporary avatars

- Stage result UI follows `design/stage success.png` and `design/stage failed.png`: layered floral cream/wood panel, separate cheerful/teary Aina sprites, painted green/pink buttons, localized stage heading and native text, stars and coin reward. Five transparent assets and built-in imagegen prompts are saved in `assets/ui/results_v1/` and `design/MVP_Result_UI_v1.json`.
- Success shows the actual awarded stars/coins, Next Stage, Play Again and Back to Stall. The campaign finale routes to Journey. Failure shows zero unearned rewards, Try Again and Use Booster; recovery preserves free/coin move offers and consumes exactly one inventory Extra Moves booster when selected.
- Regression verifies result button signals, English/Malay text, true reward values, and booster consumption/resume. Menu regression passes; screenshot fixtures include success, failed and recovery options.

- Dialogue that awaits a tap now shows an animated hand immediately below its bubble, replacing English tap-to-continue/close text. Tutorial action steps hide the hand and remain playable; intro steps accept taps on either the bubble or the hand. Regression verifies prompt visibility and rendered story/tutorial screens.

- Match-4 onboarding now starts directly on the playable step with three Ang Ku in the third row and the fourth directly above the gap. Immediate outlined highlights and a downward arrow identify the swap; unrelated tiles are dimmed. Focus clears when the move is accepted. Regression and rendered tutorial screenshots verified.

- Tutorial special lessons now use their authored hint pair instead of a generic match-3 hint. Intro dialogues preserve the board, and Tapau/Dulang creation lessons accept their guided swap so other matches cannot consume the teaching layout. Regression verifies rejected match-3 attempts leave the layout intact and the guided swaps create Tapau/Dulang and complete the lessons.

- Gameplay and menu coin/star bars share aligned visual heights; nine-patch drawing preserves round icons and star proportions.
- Main menu shows earned stars instead of diamonds. Play routes first-time users through mandatory tutorials without a tutorial caption beneath the button.
- Journey opens the route from the family stall in the kampung to later destinations, showing cleared stages and earned stars per stop. Story memories remain available at each stop.
- Settings offers 12 temporary character avatars. The selected avatar is saved in the player profile and displayed on the home screen; older saves default to Aina.
- Verified menu/avatar save round-trip, localization, journey progress, tutorial routing, regression suite and rendered screenshots.

Journey/heart update: Campaign Play, Next Stage, Retry and Restart show the illustrated Journey map before entry. The map contains all 30 individual stages across three chapter pages and retains seen-story memories. HeartManager adds 5 hearts, failure-only consumption, offline 30-minute recovery, coin refills and saved 15/30-minute Free Play rewards. Tutorials are exempt. Rewarded ads stay hidden until a verified provider is connected. Implementation details and art prompts are in design/Journey_Heart_Implementation.md and design/MVP_Journey_UI_v1.json.

The supplied four-frame finger tap sheet now animates under tap-required dialogue. DialogueSpotlight keeps the bubble and hand bright while dimming other UI; action tutorial steps restore normal screen visibility. Heart, menu, persistence and regression checks use disposable saves; rendered fixtures are available in .shots.