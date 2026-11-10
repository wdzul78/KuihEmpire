# Google Play Games: Setup untuk Kuih Empire

Kod dalam game sudah siap (`scripts/core/play_games.gd`). Ia akan aktif selepas ID dari Play Console dimasukkan.

## 1. Play Console (dibuat oleh pemilik akaun)

1. **Play Console → Kuih Empire → Grow users → Play Games Services → Setup and management → Configuration**
2. Pilih **"No, my game doesn't use Google APIs"** dan buat projek Play Games baharu.
3. **Credentials → Add credential → Android**:
   - Package name: `com.kuihempire.kuihempire`
   - SHA-1 untuk game di Play Store: **Setup → App signing → App signing key certificate**.
   - Buat kelayakan kedua dengan SHA-1 **upload key** atau **debug key** jika mahu cuba APK yang dipasang terus.
4. **Properties → Saved Games: ON**.
5. Buat **award** dan **ranking** di bawah. Play Console mahukan sekurang-kurangnya 5 award, dan setiap award perlu ikon 512×512.
6. Klik **Review and publish**. Sebelum diterbitkan, hanya akaun penguji yang boleh log masuk. Tambah e-mel penguji di bahagian **Testers**.
7. Beri saya:
   - **Game ID**, iaitu nombor panjang di atas halaman Configuration.
   - Setiap **Achievement ID** dan **Leaderboard ID**, yang bermula dengan `Cgk…`.

## 2. Award (Achievements)

Jumlah mata ialah 860, di bawah had 1000. Ini memberi ruang untuk award stage baharu nanti.

| ID dalam game | Nama (BM) | Nama (EN) | Penerangan (BM) | Mata |
|---|---|---|---|---|
| first_steps | Langkah Pertama | First Steps | Selesaikan stage pertama anda. | 5 |
| first_renovation | Ubah Suai Pertama | First Renovation | Beli naik taraf struktur gerai yang pertama. | 10 |
| stars_30 | Pengumpul Bintang I | Star Collector I | Kumpul 30 bintang. | 20 |
| stars_60 | Pengumpul Bintang II | Star Collector II | Kumpul 60 bintang. | 30 |
| stars_90 | Pengumpul Bintang III | Star Collector III | Kumpul 90 bintang. | 40 |
| stars_120 | Pengumpul Bintang IV | Star Collector IV | Kumpul 120 bintang. | 50 |
| stars_180 | Pengumpul Bintang V | Star Collector V | Kumpul 180 bintang. | 80 |
| perfect_server | Hidangan Sempurna | Perfect Server | Dapatkan tiga bintang di 10 stage berbeza. | 40 |
| recipes_10 | Peneroka Kuih | Kuih Explorer | Temui 10 resipi. | 20 |
| malaysian_kuih_master | Pakar Kuih Malaysia | Master of Malaysian Kuih | Temui kesemua 200 resipi warisan. | 100 |
| recipe_master | Pakar Kuih | Kuih Master | Lengkapkan buku resipi. | 100 |
| serve_100 | Gerai Sibuk | Busy Gerai | Hidangkan 100 pesanan pelanggan. | 30 |
| combo_25 | Tukang Kombo | Combo Cook | Aktifkan 25 gabungan istimewa. | 40 |
| no_help | Tak Perlu Bantuan | No Help Needed | Menang satu stage tanpa guna booster. | 15 |
| streak_5 | Rentetan Manis | Sweet Streak | Menang lima stage berturut-turut. | 30 |
| story_1 | Gerai Keluarga Selesai | Family Stall Complete | Selesaikan kesemua 30 stage gerai keluarga. | 80 |
| next_story | Perjalanan Diteruskan | Journey Continues | Buka cerita kantin sekolah. | 20 |
| story_2 | Kantin Sekolah Selesai | School Canteen Complete | Selesaikan kesemua 30 stage kantin sekolah. | 100 |
| score_3000 | Skor Manis | Sweet Score | Capai skor terbaik 3,000 dalam satu stage. | 30 |
| gerai_2 | Gerai Berkembang | Growing Gerai | Naik taraf gerai ke tahap dua. | 20 |

Tetapan untuk semua award:
- **Incremental: OFF**. Game membuka award apabila syaratnya tercapai.
- **Initial state: Revealed**.
- Bahasa lalai: English. Tambah terjemahan Bahasa Melayu dalam Play Console.

## 3. Ranking (Leaderboards)

| Kegunaan | Nama (BM) | Nama (EN) | Format | Susunan |
|---|---|---|---|---|
| LEADERBOARD_STARS | Bintang Terbanyak | Most Stars | Numeric, 0 decimal | Larger is better |
| LEADERBOARD_STAGE | Stage Terjauh | Furthest Stage | Numeric, 0 decimal | Larger is better |

Had skor: minimum 0. Maksimum ialah 3 × bilangan stage (sekarang 180) untuk bintang, dan bilangan stage (sekarang 60) untuk stage. Lebih selamat jika had maksimum dibiarkan kosong supaya stage baharu tidak tersekat.

## 4. Apa yang game buat selepas ID dimasukkan

- **Log masuk:** Play Games log masuk sendiri bagi pemain yang pernah log masuk. Pemain lain boleh tekan "Log masuk Google Play Games" di Tetapan, atau butang Google Play di skrin Pencapaian.
- **Simpanan awan:** selepas log masuk, game membandingkan progres di awan dengan progres di telefon (stage terjauh, kemudian bintang).
  - Jika awan lebih jauh, pemain ditanya sama ada mahu guna progres Google Play.
  - Jika tidak, progres telefon dimuat naik.
  - Selepas itu, progres dimuat naik paling kerap sekali setiap 45 saat, dan juga bila app ditutup atau dijeda.
  - Tetapan telefon (bahasa, bunyi) tidak ditimpa.
  - Progres lama telefon disimpan sebagai `kuih_empire_save.json.before_cloud`.
- **Award:** setiap pencapaian dalam game turut dibuka di Play Games. Pencapaian yang sudah didapati sebelum log masuk diselaraskan semasa log masuk.
- **Ranking:** jumlah bintang dan stage terjauh dihantar selepas setiap stage dimenangi dan semasa log masuk.

## 5. Di mana ID diletakkan

- Game ID: `export_presets.cfg` → `godot_play_game_services/game_id`. Isi untuk kedua-dua preset.
- Achievement dan Leaderboard ID: `scripts/data/play_games_ids.gd`.

Fail `export_presets.cfg` tidak dijejaki Git, jadi Game ID tidak masuk ke repo.
