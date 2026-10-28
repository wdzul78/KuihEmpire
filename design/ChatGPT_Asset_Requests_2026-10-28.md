# Permintaan aset imej untuk ChatGPT — 28 Oktober 2026

Audit grafik pada 28 Okt 2026 mendapati semua kuih, special, blocker, pelanggan, booster dan latar gerai sudah memakai PNG sebenar. Kod procedural untuk bahagian-bahagian itu hanya fallback dan tidak pernah dijalankan.

Yang masih dilukis dengan kod (placeholder) dan dilihat pemain disenaraikan di bawah, mengikut keutamaan. Untuk setiap item:

1. Salin **Gaya asas** dan prompt item ke ChatGPT.
2. Simpan hasilnya di laluan **Simpan ke**, dengan saiz yang dinyatakan.
3. Beritahu Claude supaya kod disambungkan dan backup dibuat dahulu.

Rujukan gaya yang perlu dilampirkan bersama prompt di ChatGPT:

- `design/Kuih Empire_ Sweet Match Adventure.png` (gaya UI dan permainan)
- `design/Kuih Empire Character Design Board.png` (gaya watak)
- `assets/characters/fullbody_v2/aina.png` (contoh watak siap: 1024×1536, latar telus)

## Gaya asas (tampal di awal setiap prompt)

**Watak:**
> Clean modern Malaysian chibi cartoon for a cozy mobile match-3 game. Rounded proportions, bold clean dark brown outlines, simple soft cel shading, warm friendly expression. Full body, head to shoes, nothing cropped, standing three-quarter view, centered. TRUE TRANSPARENT background (real alpha, no checkerboard, no white box). No text, no logo, no frame.

**UI / ikon:**
> Polished 2D casual mobile game UI asset, cozy Malaysian kampung style. Warm cream parchment and polished brown wood with a golden inner bevel, bold clean brown cartoon outlines, warm painted highlights, simple shapes readable at 64px. TRUE TRANSPARENT background (real alpha). No text, letters or numbers unless stated.

**Makanan:**
> Pure polished 2D casual-game cartoon: chunky dark brown outline, simple plump geometry, bold flat saturated colors, broad cel-shaded highlight shapes, very little surface detail. Cute food with no faces or limbs. Three-quarter slightly overhead view, centered square canvas, silhouette fills 82% of canvas. TRUE TRANSPARENT background. No plate, no text.

---

## Keutamaan 1: Watak cerita (sekarang dilukis sebagai kepala bulat ringkas)

Watak-watak ini muncul dalam dialog cerita stage 7, 10, 20, 28 dan 30, serta dalam "Memories" di Journey.

| Simpan ke | Saiz | Prompt (selepas gaya asas watak) |
|---|---|---|
| `assets/characters/fullbody_v2/ibu.png` | 1024×1536 | Ibu, Aina's warm Malay mother in her late 40s, soft pastel baju kurung with a matching tudung, a small apron, gentle proud smile, hands clasped in front. |
| `assets/characters/fullbody_v2/farah.png` | 1024×1536 | Farah, Aina's cheerful best friend aged about 20, Malay, orange-and-cream casual blouse with a simple bawal tudung, sling bag, waving happily. |
| `assets/characters/fullbody_v2/daniel.png` | 1024×1536 | Daniel, a friendly-rival young stall owner aged about 22, neat green polo shirt with a plain unbranded apron, confident grin, arms crossed, slightly smug but likeable. |

---

## Keutamaan 2: Panel dan butang UI (sekarang kotak warna rata)

Panel ini dipakai dalam Settings, pengepala gerai, kad tugasan, popup Records, kad "habis langkah" dan kad cerita. Panel mesti boleh diregang sebagai 9-patch: bucu dan bingkai seragam, bahagian tengah kosong rata.

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/panels_v1/cream_panel.png` | 512×512 | Rounded rectangle panel, warm cream parchment face, thin golden inner bevel, slim polished brown wood rim, corner radius about 80px, perfectly even border on all sides, plain centre with no pattern (for 9-slice stretching). |
| `assets/ui/panels_v1/wood_panel.png` | 512×512 | Same shape as above but the face is warm honey-brown polished wood planks, golden inner bevel, darker brown rim, even border, plain centre (9-slice). |
| `assets/ui/panels_v1/button_wood.png` | 512×160 | Wide pill-shaped wooden button, glossy honey wood, golden rim, soft top highlight, perfectly symmetric rounded ends (9-slice horizontally). |
| `assets/ui/panels_v1/slider_track.png` | 512×64 | Slim rounded slider track, recessed cream groove inside a brown wood rim. |
| `assets/ui/panels_v1/slider_grab.png` | 128×128 | Round slider knob, glossy pink candy button with a gold rim. |

---

## Keutamaan 3: Ikon kecil (sekarang dilukis dengan kod atau simbol teks seperti ✓ ▶ ∞)

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/booster_tray_v1/lock.png` | 256×256 | Chunky golden padlock, closed, cartoon style, brown outline. |
| `assets/ui/pause_icons_v1/exit.png` | 256×256 | Wooden stall door slightly open with a small arrow pointing out, cartoon icon. |
| `assets/ui/gameplay_v2/order_tick.png` | 256×256 | Big glossy green check mark with a cream outline and a brown outer stroke, cartoon "order complete" icon. |
| `assets/boosters/extra_moves.png` | 1254×1254 | Booster icon "+5 moves": a cute golden hourglass beside a green leaf badge, glossy cartoon, no numbers. |
| `assets/ui/icons_v1/glyphs.png` | 1024×1024 | Icon sheet, 2 rows × 3 columns on a transparent background, evenly spaced: play triangle, down chevron, check mark, plus sign, infinity loop, small sparkle star. Same golden-cream cartoon style and brown outline. |
| `assets/ui/resources_v1/plus_button.png` | 256×256 | Round glossy green "+" button with a gold rim (for heart and coin refill). |

---

## Keutamaan 4: Ikon pencapaian (sekarang hanya simbol ★ atau ✓)

Hasilkan 9 ikon, setiap satu 256×256 dengan latar telus. Gunakan medallion bulat yang sama: rim emas, wajah krim, dan objek di tengah.

| Simpan ke | Objek di tengah |
|---|---|
| `assets/ui/achievements_v1/journey.png` | small rolled map with a red route line |
| `assets/ui/achievements_v1/stars.png` | three stacked gold stars |
| `assets/ui/achievements_v1/puzzle.png` | 2×2 grid of colourful kuih tiles |
| `assets/ui/achievements_v1/recipes.png` | open recipe book with a pandan leaf bookmark |
| `assets/ui/achievements_v1/orders.png` | paper food bag tied with a ribbon |
| `assets/ui/achievements_v1/specials.png` | glowing wrapped kuih with a burst |
| `assets/ui/achievements_v1/streak.png` | flame-shaped ribbon |
| `assets/ui/achievements_v1/score.png` | trophy cup |
| `assets/ui/achievements_v1/gerai.png` | tiny wooden market stall with a striped awning |

---

## Keutamaan 5: Imej resepi (10 resepi, Recipe Book sekarang tulis "art pending")

Prompt penuh sudah ada dalam `data/recipe_image_requests_batch_01.md`. Formatnya 1024×1024 RGBA, latar benar-benar telus. Item bertanda RESEARCH_REQUIRED memerlukan gambar rujukan sebenar yang diluluskan sebelum dijana. Laluan simpanan:

- `assets/recipes/shared/onde_onde.png`
- `assets/recipes/shared/bahulu.png`
- `assets/recipes/shared/putu_piring.png`
- `assets/recipes/shared/ang_ku_kueh.png`
- `assets/recipes/shared/kuih_cara.png`
- `assets/recipes/sabah/kuih_cincin.png`
- `assets/recipes/sarawak/tebaloi.png`
- `assets/recipes/sarawak/penganan.png`
- `assets/recipes/sarawak/kek_lapis_sarawak.png`
- `assets/recipes/indian_malaysian/vadai.png`

---

## Tidak perlu dijana (aset sudah ada, hanya perlu disambung dalam kod)

- **Nod stage Journey:** `assets/ui/journey_v1/stage_gold.png`, `stage_green.png` dan `stage_locked.png` sudah wujud tetapi `journey_stage_disc.gd` masih melukis bulatan dengan kod.
- **Pil hati/syiling di HUD dan Journey:** boleh guna semula `assets/ui/menu/resource_v5/counter.png`.
- **Suis audio di menu pause:** boleh guna `assets/ui/settings_v1/toggle_sheet.png`.
- **Pasu bunga di onboarding:** boleh guna `assets/stalls/accessories_v1/hibiscus.png`.

Kesan VFX (garis, cahaya, riak) dan permukaan board memang sengaja dilukis dengan kod untuk prestasi, jadi tidak perlu diganti.
