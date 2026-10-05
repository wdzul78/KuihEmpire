# Journey MVP — 30 stage

Satu cerita **Gerai Keluarga**, dengan tiga milestone: Mula Bangkit (1–10), Kemas & Cantikkan Gerai (11–20), Kembangkan Bisnes (21–30). Tutorial kekal berasingan.

Peta memaparkan 30 node dalam satu laluan scroll. Butang 1–10, 11–20, 21–30 ialah pintasan scroll. Stage selesai boleh diulang; kemenangan satu bintang sudah membuka stage seterusnya. Stage 10, 20, 30 mempunyai node lebih besar, ribbon dan landmark gerai.

MULA membuka preview tempahan, jumlah langkah dan pilihan Dulang/Tapau. Inventori digunakan apabila board campaign dimuatkan. Membatalkan preview atau kekurangan heart tidak menggunakan special.

Milestone memberi resipi dan cosmetic gerai sekali sahaja. Gerai visual berkembang mengikut world state 0–3; tahap upgrade berbayar sedia ada dikekalkan. Stage 30 menjamin Gerai Lv 2 dan membuka metadata Kantin Sekolah. Kantin ditunjukkan sebagai destinasi akan datang; stage 31 tidak boleh dimainkan dalam MVP.

Resipi milestone untuk save baharu: stage 10 Ketayap, stage 20 Keria, stage 30 Penyaram. Resipi yang telah dibuka dalam save lama tidak ditarik balik.

Result → Continue → cerita milestone → Journey. Cerita yang telah dilihat boleh dibaca semula melalui Cerita pada peta. Save sedia ada dikekalkan; world state berasal daripada kemenangan milestone dan reward flag disimpan dalam story_seen. Free Play masih dikendalikan oleh HeartManager supaya tidak diberi dua kali.

Validasi: tools/journey_test_scene.tscn (save ujian berasingan), menu, heart dan regression suites.
