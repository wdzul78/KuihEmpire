# Permintaan aset imej untuk ChatGPT — Kantin Sekolah, stage 31–60 (November 2026)

Peta Perjalanan kini boleh memaparkan 60 stage, tetapi bahagian Kantin Sekolah masih meminjam dunia Gerai Keluarga. Fail ini meminta seni sebenar yang wajib ada sebelum keluaran 0.2.0.

Untuk setiap item:

1. Salin **Gaya asas** bahagian itu dan prompt item ke ChatGPT.
2. Lampirkan imej rujukan yang dinyatakan.
3. Simpan hasil di laluan **Simpan ke**, dengan saiz yang dinyatakan.
4. Beritahu Claude. Claude akan membuat backup dahulu, kemudian menyambungkan kod.

Jika ChatGPT tidak dapat menghasilkan nisbah yang diminta, simpan hasil paling tinggi yang ada dan beritahu Claude. Jangan regangkan imej.

## 1. Dunia peta (3 imej, wajib)

Lampirkan: `assets/ui/journey_world_v2/village.png` dan `assets/ui/journey_world_v2/waterfront.png`.

**Gaya asas:**

> Polished handpainted casual mobile puzzle game map, elevated top-down view, very tall vertical 1:3 scrolling map, matching the attached reference exactly in paving colour, greenery, lighting and level of detail. One continuous pale golden paved winding road enters at the bottom edge near the horizontal centre, curves gently, and leaves at the top edge near the horizontal centre. Keep the road free of objects and people. Warm daylight, present-day Sarawak, Malaysia, tidy and welcoming. Full-bleed opaque illustration. NO text, letters, numbers, signs with writing, UI, characters or sky.

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/journey_world_v3/school_gate.png` | 724×2172 | A Malaysian primary school entrance area: painted school gate without any writing, guard post, flagpoles without flags in frame, covered walkway, flowerbeds, parked bicycles along the road edge, cream and blue school blocks at the sides. |
| `assets/ui/journey_world_v3/school_canteen.png` | 724×2172 | A cheerful Malaysian school canteen area: open-sided canteen hall with long tables and benches, food counters with empty trays, potted plants, hand-washing sinks, shady trees, and classroom blocks at the sides. |
| `assets/ui/journey_world_v3/school_field.png` | 724×2172 | A Malaysian school sports field: green field with white track lanes at the sides of the road, small sports tents with bunting without writing, a low spectator stand, trees, and a school hall in the distance at the sides. |

## 2. Penyambung peta (3 imej, wajib)

Lampirkan: `assets/ui/journey_transitions_v1/connectors.png` dan dua dunia yang disambungkan.

**Gaya asas:**

> Game map transition strip, wide landscape 3:1, opaque illustration covering the whole image, matching the attached references exactly. One continuous pale golden paved road runs vertically, entering the top edge and leaving the bottom edge at exactly 50% of the width, road width about 25% of the canvas, free of objects. Organic leafy gardens and flowerbeds bridge the two environments so there is no horizontal cut. NO text, letters, numbers, UI or characters.

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/journey_transitions_v2/waterfront_to_gate.png` | 1536×512 | Top: school gate area with a covered walkway and flowerbeds. Bottom: Kuching waterfront garden promenade with palms and a stone railing. |
| `assets/ui/journey_transitions_v2/gate_to_canteen.png` | 1536×512 | Top: open-sided school canteen area with potted plants. Bottom: school gate area with flowerbeds. |
| `assets/ui/journey_transitions_v2/canteen_to_field.png` | 1536×512 | Top: green school sports field with white track lines. Bottom: open-sided school canteen area with shady trees. |

## 3. Pelanggan baharu (4 imej, wajib)

Lampirkan: `assets/characters/fullbody_v2/aina.png` dan `assets/characters/fullbody_v2/encik_v3.png`.

**Gaya asas:**

> Polished 2D casual mobile game character, full body, standing, friendly expression, matching the attached references exactly in outline, shading and proportions. Modest, respectful and suitable for all ages. Centered, feet visible, 1024×1536 canvas. TRUE TRANSPARENT background (real alpha, no checkerboard, no white box). NO text, letters, numbers or badges with writing.

| Simpan ke | Prompt |
|---|---|
| `assets/characters/fullbody_v2/cikgu_salmah.png` | Cikgu Salmah, a kind Malay woman teacher in her 40s, wearing a modest baju kurung and tudung, holding a small stack of exercise books. |
| `assets/characters/fullbody_v2/adik_danish.png` | Adik Danish, a cheerful Malay primary school boy in a white shirt and navy long trousers school uniform, wearing a backpack, waving. |
| `assets/characters/fullbody_v2/adik_priya.png` | Adik Priya, a bright Indian Malaysian primary school girl in a navy pinafore over a white shirt school uniform with long socks, neat braided hair, holding a small lunch box. |
| `assets/characters/fullbody_v2/pak_mat.png` | Pak Mat, a warm older Malay school caretaker in a plain work shirt and trousers with a songkok, holding a broom. |

## 4. Lukisan milestone Kantin (1 imej, wajib)

Lampirkan: `assets/ui/milestone_v1/family_stall_old.png` jika sudah siap, supaya gayanya sepadan.

| Simpan ke | Saiz | Prompt |
|---|---|---|
| `assets/ui/milestone_v1/school_canteen.png` | 1400×700 | Wide landscape illustration of a slightly tired but charming Malaysian school canteen waiting to come back to life: simple food counter, long benches, potted plants, morning light through open sides, classroom blocks behind. Whole canteen visible and centered, full-bleed background, soft painterly polished 2D casual-game style, hopeful and warm. NO text, letters, numbers or people. |

---

### Nota untuk Claude semasa menyambung

- Dunia: tukar medan `world` bahagian 31–60 dalam `JourneyLibrary.SECTIONS` dan laluan dalam `JourneyMap._world_path`, kemudian ukur 10 titik jalan untuk `centers.json`. Ujian `journey_scale_test` memeriksa setiap dunia mempunyai 10 titik.
- Penyambung: format baharu ialah satu jalur setiap fail, jadi `shaders/journey_connector.gdshader` perlu menerima jalur tunggal. Sandarkan dahulu.
- Pelanggan: `CustomerLibrary` memuatkan `fullbody_v2/<id>.png` mengikut id, jadi gunakan id `cikgu_salmah`, `adik_danish`, `adik_priya`, `pak_mat`.
- Permintaan lukisan resipi dan `family_stall_old` masih berada dalam `design/ChatGPT_Asset_Requests_2026-10-30_Recipes_Milestone.md`.
