# Permintaan aset imej untuk ChatGPT — Skrin Gerai (30 Oktober 2026)

Kotak-kotak di skrin Gerai sekarang ialah kotak krim rata yang dilukis dengan kod. Rupanya tidak seragam dengan panel kayu emas yang bercat, jadi nampak membosankan. Fail ini meminta **satu set UI yang seragam** untuk menggantikannya: semua item berkongsi gaya, bingkai dan warna yang sama.

Untuk setiap item:

1. Salin **Gaya asas set Gerai** dan prompt item ke ChatGPT.
2. Lampirkan imej rujukan yang disenaraikan di bawah.
3. Simpan hasil di laluan **Simpan ke**, dengan saiz yang dinyatakan dan latar telus.
4. Beritahu Claude. Claude akan membuat backup dahulu, kemudian menyambungkan kod.

Rujukan gaya yang perlu dilampirkan:

- `assets/ui/stage_preview_v3/panel.png` — bingkai emas, daun pisang, kertas krim (gaya sasaran utama)
- `assets/stalls/accessories_v2/task_panel.png` — panel senarai tugasan sedia ada
- `assets/menu/nav_v4/shop.png` — ikon gerai berbingkai kayu
- Tangkapan skrin semasa Gerai (untuk susun atur): `.shots/accessories_family_stall.png`, `.shots/renovation_tasks.png`, `.shots/renovation_task_complete.png`

## Gaya asas set Gerai (tampal di awal setiap prompt)

> Polished 2D casual mobile game UI asset, cozy Malaysian kampung kuih stall theme, matching ONE consistent set. Warm cream parchment face with a very soft paper texture, glossy golden inner rim, slim polished honey-brown wood outer frame, bold clean dark-brown cartoon outline, soft warm top highlight, gentle drop shadow under the piece. Small green banana-leaf accents only where stated. Front-on flat view, perfectly symmetric. TRUE TRANSPARENT background (real alpha, no checkerboard, no white box). NO text, letters or numbers anywhere.

**Peraturan 9-patch (penting):** semua panel dan butang akan diregang mengikut lebar dan tinggi skrin. Bingkai mesti sama tebal di keempat-empat sisi. Ornamen hanya boleh berada di bucu, dan bahagian tengah setiap sisi mesti rata dan berulang. Jika ini tidak dipatuhi, bingkai akan nampak herot.

---

## 1. Header atas (Back · nama gerai · bilangan bintang)

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/header_bar.png` | 1536×300 | Wide horizontal top header plate for a mobile screen: cream parchment face inside a golden rim and honey wood frame, softly rounded corners (radius about 60px), two tiny banana-leaf sprigs tucked at the far left and far right corners only, plain flat centre for text. 9-slice friendly. |
| `assets/ui/gerai_v1/name_plate.png` | 1024×220 | Carved wooden name plaque for the stall name: warm honey wood with visible soft grain, golden beaded edge, gently scalloped ends like a shop signboard, recessed flat centre for a title. Symmetric. Horizontally 9-slice friendly (the middle section must be plain and repeatable). |
| `assets/ui/gerai_v1/star_counter.png` | 640×220 | Resource counter pill: rounded cream-to-honey pill with a golden rim and dark-brown outline. At the left end a big glossy golden five-point star medallion overlaps the pill edge. The rest of the pill is plain and recessed, for the number. Optional small round green "+" bubble at the right end, kept separate from the number area. |

## 2. Penanda hotspot di gerai (bulatan bintang / kunci)

Sekarang ia bulatan krim dengan ikon kecil, dan rupanya tidak menarik. Penanda mesti jelas boleh ditekan dan kelihatan dari jauh.

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/hotspot_ready.png` | 256×256 | Round tappable medallion for an available upgrade: glossy golden coin-like disc with a thick cream ring and brown outline, a plump shiny golden star in the centre, small sparkle glints, soft glow ring around it. Slight downward pointer tab at the bottom like a map pin. |
| `assets/ui/gerai_v1/hotspot_locked.png` | 256×256 | Same medallion shape and pin tab as the ready version but muted: pale beige disc, dusty brown ring, a chunky brown padlock in the centre, no glow. |
| `assets/ui/gerai_v1/hotspot_done.png` | 256×256 | Same medallion shape and pin tab, fresh leaf-green disc with a cream ring and a bold white check mark, a small sparkle. |

## 3. Kotak "Seterusnya" (Up next)

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/next_hint.png` | 1280×260 | Wide rounded speech-banner card for an "up next" tip: cream parchment face, golden rim, honey wood frame. On the left end a round inset badge with a tiny clipboard-with-tick icon. Plain flat area to the right for two lines of text. 9-slice friendly horizontally. |

## 4. Senarai tugasan (To-do list)

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/list_panel.png` | 1024×1400 | Tall dialog panel matching the stage booster panel style: cream parchment face, golden inner rim, honey wood frame, banana-leaf clusters at the two bottom corners only, a small carved wooden title plaque centred on the top edge (empty, no text). Even straight sides for 9-slice. |
| `assets/ui/gerai_v1/task_row.png` | 1024×220 | List row card: slightly lighter cream inset card with a thin golden rim and soft inner shadow, rounded corners, a round recessed icon socket on the left. Plain centre. 9-slice friendly horizontally. |
| `assets/ui/gerai_v1/tab_active.png` | 384×120 | Selected tab chip: glossy leaf-green rounded pill, golden rim, soft highlight. Plain centre. |
| `assets/ui/gerai_v1/tab_idle.png` | 384×120 | Unselected tab chip: same shape, cream face, light golden rim, flat. |
| `assets/ui/gerai_v1/price_button.png` | 384×150 | Small glossy leaf-green pill button for a star price, golden rim and dark-green outline, a small golden star badge on its left end, plain area for the number. |
| `assets/ui/gerai_v1/progress_track.png` | 1024×64 | Rounded progress bar groove: recessed cream channel inside a golden rim and thin brown outline. 9-slice horizontally. |
| `assets/ui/gerai_v1/progress_fill.png` | 1024×64 | Progress bar fill matching the track: glossy pink-to-rose candy fill with a white top shine and subtle diagonal stripes. 9-slice horizontally. |

## 5. Popup "Tugasan selesai!"

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/complete_panel.png` | 1280×900 | Celebration dialog: same frame as list_panel (cream face, golden rim, honey wood, banana-leaf corners), plus a curved festive red-and-gold ribbon banner across the top edge (empty, no text) and a few small confetti sparkles and golden stars around the ribbon only. Plain centre. |

## 6. Bar navigasi bawah (Tasks · Design · Play)

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/gerai_v1/footer_bar.png` | 1536×260 | Bottom dock plate: honey wood frame with a golden rim and a cream recessed inner tray, rounded top corners, flat bottom edge. 9-slice friendly. |
| `assets/ui/gerai_v1/nav_button.png` | 512×200 | Secondary dock button: cream glossy rounded button, golden rim, brown outline, soft top shine, round recessed icon socket on the left, plain area for a label. 9-slice horizontally. |
| `assets/ui/gerai_v1/icon_tasks.png` | 256×256 | Cute clipboard with a checklist and a green tick, brown outline. |
| `assets/ui/gerai_v1/icon_design.png` | 256×256 | Cute painter's palette with a small brush and a pink hibiscus accent, brown outline. |

## 7. Aksesori pasu bunga (pilihan)

Pasu bunga kini diletakkan di atas kaunter, di hujung kanan. Pasu sedia ada tidak mempunyai bayang dasar, jadi ia nampak sedikit terapung. Jika mahu yang lebih kemas:

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/stalls/accessories_v3/hibiscus_counter.png` | 512×512 | Small terracotta pot with a lush red hibiscus bush, sized to sit on a wooden stall counter top, three-quarter front view, soft contact shadow at the pot base only. Food-stall cartoon style matching polished 2D casual-game art. |

---

### Nota untuk Claude semasa menyambung

- Simpan semua dalam `assets/ui/gerai_v1/` dan buat backup `scripts/ui/gerai_screen.gd` dahulu.
- Gunakan `StyleBoxTexture` dengan margin 9-patch (lebih kurang 22% tinggi imej) untuk panel, baris, tab dan butang.
- Teks kekal sebagai Label Godot dengan saiz fon baharu (header 46, progress 32, hint 36). Jangan bakar teks ke dalam imej.
