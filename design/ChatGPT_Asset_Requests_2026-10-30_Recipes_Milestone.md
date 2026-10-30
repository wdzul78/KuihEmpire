# Permintaan aset imej untuk ChatGPT — Lukisan resipi dan milestone (30 Oktober 2026)

Popup "Kuih baharu ditemui" dan buku resipi merujuk 10 fail lukisan yang belum wujud. Kerana itu, kuih yang bukan kuih papan permainan memaparkan "Artwork coming later". Popup milestone pula menunjukkan potongan latar gerai yang tidak dilukis untuk popup. Fail ini meminta lukisan tersebut.

Untuk setiap item:

1. Salin **Gaya asas** dan prompt item ke ChatGPT.
2. Lampirkan imej rujukan di bawah.
3. Simpan hasil di laluan **Simpan ke**, dengan saiz yang dinyatakan dan latar telus (kecuali dinyatakan lain).
4. Beritahu Claude. Claude akan membuat backup dahulu, kemudian menyambungkan kod.

Rujukan gaya yang perlu dilampirkan:

- `assets/kuih/onde_onde.png` — gaya lukisan kuih dalam permainan
- `assets/ui/gerai_v1/complete_panel.png` — bingkai yang akan memaparkan lukisan ini
- `assets/stalls/accessories_v3/hibiscus_counter.png` — gaya objek bercat

## Gaya asas lukisan resipi (tampal di awal setiap prompt)

> Polished 2D casual mobile game food illustration, cozy Malaysian kampung style, matching ONE consistent set. A generous serving of the kuih on a small round woven rattan tray lined with fresh banana leaf, three-quarter front view, appetizing glossy highlights, bold clean dark-brown cartoon outline, soft warm lighting, gentle contact shadow under the tray. Centered, filling about 85% of the canvas. TRUE TRANSPARENT background (real alpha, no checkerboard, no white box). NO text, letters or numbers anywhere. Culturally accurate shape and colour for the named kuih.

## 1. Lukisan resipi (semua 1024×1024)

| Simpan ke | Prompt |
|---|---|
| `assets/recipes/shared/onde_onde.png` | Onde-onde: round pandan-green glutinous rice balls coated in white grated coconut, one cut open showing dark palm sugar filling. |
| `assets/recipes/sabah/kuih_cincin.png` | Kuih cincin from Sabah: deep-fried dark brown ring-shaped palm sugar pastries with slightly rough surfaces. |
| `assets/recipes/shared/bahulu.png` | Bahulu: small golden-brown mini sponge cakes baked in fluted button and fish shapes. |
| `assets/recipes/sarawak/tebaloi.png` | Tebaloi from Sarawak: thin flat golden sago-and-coconut crackers, stacked and overlapping. |
| `assets/recipes/shared/putu_piring.png` | Putu piring: soft white steamed rice flour discs on small squares of banana leaf, palm sugar filling peeking out, sprinkled grated coconut. |
| `assets/recipes/shared/ang_ku_kueh.png` | Ang ku kueh: glossy red oval glutinous rice cakes with a tortoise-shell pattern, each on a small banana leaf base. |
| `assets/recipes/indian_malaysian/vadai.png` | Vadai: crispy golden-brown Indian Malaysian lentil fritters in doughnut shape, with curry leaves and a small green chilli. |
| `assets/recipes/sarawak/penganan.png` | Penganan from Sarawak: dark brown glossy palm-sugar fried rice cakes shaped like flat discs with a thicker centre. |
| `assets/recipes/shared/kuih_cara.png` | Kuih cara: small golden flower-shaped savoury pancakes baked in a mould, with a little minced filling in the centre. |
| `assets/recipes/sarawak/kek_lapis_sarawak.png` | Kek lapis Sarawak: slices showing many precise, colourful geometric layers in red, yellow, green and brown, neat rectangular cuts. |

## 2. Lukisan milestone gerai

Sekarang popup memotong latar gerai, jadi gambarnya nampak tidak sengaja. Gambar ini khusus untuk popup, berlatar penuh (bukan telus).

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/milestone_v1/family_stall_old.png` | 1400×700 | Wide landscape illustration of a small, worn but charming old Malaysian family kuih stall in a kampung: faded wooden counter, simple rack, no sign, potted hibiscus, green garden and sunny sky behind, hopeful warm morning light. Whole stall visible and centered, full-bleed background, soft painterly polished 2D casual-game style. NO text, letters or numbers anywhere. |

---

### Nota untuk Claude semasa menyambung

- Laluan bahagian 1 sudah tertulis dalam `data/recipes/catalog.json`, jadi lukisan resipi akan muncul sendiri selepas diimport (`--headless --path . --import`).
- Sambungkan `family_stall_old.png` menggantikan `GeraiBackdrop` dalam `scripts/ui/journey_milestone_popup.gd`, dengan backup dahulu.
