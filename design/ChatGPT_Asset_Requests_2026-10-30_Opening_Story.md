# Permintaan aset imej untuk ChatGPT — Komik cerita pembukaan (30 Oktober 2026)

Komik pembukaan sekarang berbentuk jalur lebar yang pendek, jadi ada ruang kosong besar di atas dan bawahnya. Kawasan gambar sudah dibesarkan, tetapi lukisan lama tidak dapat memenuhinya. Fail ini meminta **semua 14 panel dilukis semula** dalam bentuk lebih tinggi. Tiga panel pertama ialah cerita baharu.

Untuk setiap item:

1. Salin **Gaya asas** dan prompt item ke ChatGPT.
2. Lampirkan imej rujukan di bawah, supaya wajah dan pakaian watak kekal sama.
3. Simpan hasil di laluan **Simpan ke**, bersaiz **1280×1056** (penuh, bukan latar telus).
4. Beritahu Claude. Setiap panel akan muncul sendiri selepas diimport, dan panel yang belum siap kekal memakai gambar lama. Claude tetap akan menyemak setiap panel.

Rujukan yang perlu dilampirkan:

- `assets/story/prologue_v2/panels_a.png` dan `assets/story/prologue_v2/panels_b.png` — gaya komik, watak dan adegan lama (rujukan utama)
- `assets/characters/fullbody_v2/aina.png` — rupa penuh Aina

## Gaya asas (tampal di awal setiap prompt)

> Polished 2D storybook comic panel for a cozy Malaysian mobile game, soft painterly cartoon style with clean dark-brown outlines, warm and emotional lighting. Characters must match the attached references exactly: Aina, a young girl in a pink floral hijab, pink long-sleeve baju and cream apron; her mother, in a teal hijab and blue-and-cream floral baju with an apron; Pak Ya, a kindly elderly Malay man where he appears. Modest clothing, gentle expressions, big expressive eyes. Malaysian kampung setting with wooden houses, coconut palms and tropical plants. Slightly taller than wide (1280×1056), with a full-bleed scene that fills the entire canvas: no borders, no rounded corners, no panel frame. Characters are large and close, with faces in the upper-middle area and the main action centred. NO text, letters, numbers, signs with writing or speech bubbles anywhere. Only one scene in the image, not a sheet of several panels.

## Panel

| Simpan ke | Babak | Prompt |
|---|---|---|
| `assets/story/prologue_v3/panel_01.png` | Gerai di Hujung Kampung | A warm happy memory on a bright golden morning. A small wooden kuih stall at the edge of a kampung road, with a red-and-cream striped awning and trays full of colourful kuih. A cheerful queue of villagers waits to buy. Aina's mother, smiling and healthy, serves a customer while a younger Aina happily helps beside her. Lively mood with a soft nostalgic glow. |
| `assets/story/prologue_v3/panel_02.png` | Semakin Sunyi | The same stall on a hot, still afternoon, now slightly worn. The kampung road is almost empty, with one distant passer-by walking away and fallen leaves on the ground. Aina stands behind the counter, chin on her hand, looking out and waiting, with trays of kuih still neatly full. Muted colours, quiet and lonely but not gloomy. |
| `assets/story/prologue_v3/panel_03.png` | Petang yang Sunyi | Dusk at the same stall, with an orange and purple sky and a warm lantern just lit. Aina and her mother sit side by side on a simple wooden bench in front of the stall, shoulders close, not speaking. Trays of unsold kuih sit beside them and the awning is half rolled up as they prepare to close. Mother looks tired with her hands in her lap; Aina glances at her with concern. Tender and heavy-hearted. |
| `assets/story/prologue_v3/panel_04.png` | Jualan Kurang | Close view of Aina's mother at the stall counter in fading evening light, sighing as she counts a few coins and small notes in her palm. Aina watches from beside her, worried. Unsold kuih in the foreground. |
| `assets/story/prologue_v3/panel_05.png` | Ibu Perlu Berehat | Evening on the kampung path beside the closed stall. Aina's mother coughs into her hand, weak and pale, while Aina gently supports her by the arm, walking her home. Lantern light, caring mood. |
| `assets/story/prologue_v3/panel_06.png` | Malam Itu | Inside a simple kampung wooden house at night. Mother sleeps under a batik blanket on a mattress, unwell and exhausted. Aina kneels beside her, holding her hand and looking at her with love and worry. Soft lamp glow, moonlight through the window. |
| `assets/story/prologue_v3/panel_07.png` | Penemuan Tidak Disangka | The same house at night. Aina reaches up to a wooden shelf for a medicine bottle, and an old worn book tumbles off the shelf towards her. Aina looks surprised. A small sense of magic: dust and warm light around the falling book. |
| `assets/story/prologue_v3/panel_08.png` | Resipi Nenek | Aina sits on the floor with the old recipe book open on her lap, eyes wide with wonder. The pages show hand-drawn kuih illustrations with no readable writing. Warm golden glow rises from the book, with small floating kuih illustrations around her. Hopeful mood. |
| `assets/story/prologue_v3/panel_09.png` | Demi Ibu | Aina stands in the small kitchen with the recipe book under one arm, clenching her fist, determined and smiling bravely. Behind her through a doorway, her mother sleeps in soft light. Inspiring mood. |
| `assets/story/prologue_v3/panel_10.png` | Cuba Lagi | Late night in the small kampung kitchen. Aina, with flour on her cheek, studies the open recipe book beside a tray of failed, lumpy kuih and scattered flour. She keeps trying, focused and tired, by lamplight. Warm, slightly comedic and earnest. |
| `assets/story/prologue_v3/panel_11.png` | Akhirnya Menjadi! | Dawn light through the kitchen window. Trays of beautiful colourful kuih fill the counter: onde-onde, kuih lapis, kuih koci and ang ku kueh. Aina, tired but beaming, admires her work with flour on her apron. Triumphant and warm. |
| `assets/story/prologue_v3/panel_12.png` | Pagi Baharu | Bright fresh morning at the kampung stall. Aina eagerly lifts the striped awning and sets out trays of fresh kuih. Pak Ya stops by on his old bicycle, smiling and waving. Hopeful and lively. |
| `assets/story/prologue_v3/panel_13.png` | Pesanan Pak Ya | At the stall counter, Aina happily hands Pak Ya a small banana-leaf package of three green onde-onde. Pak Ya smiles warmly, holding out a coin. Friendly morning mood, with fresh kuih in the foreground. |
| `assets/story/prologue_v3/panel_14.png` | Senyuman Pertama | Close view of Pak Ya taking a bite of an onde-onde, delighted and pleasantly surprised. Aina stands at the counter beaming with joy, hands clasped. Golden morning light. A joyful ending to the opening, the start of her journey. |

---

### Nota untuk Claude semasa menyambung

- `scripts/story/opening_story.gd` memuatkan `PANEL_ART` mengikut nombor panel. Jalankan `--headless --path . --import` selepas fail baharu masuk.
- Lukisan dipaparkan penuh dalam kawasan gambar skrin cerita (nisbah lebih kurang 1.21:1). Semak setiap panel pada saiz telefon dan dalam kedua-dua bahasa.
