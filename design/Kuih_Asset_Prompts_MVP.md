# Kuih Empire MVP food asset prompts

Disediakan pada 4 Oktober 2026. Set ini ialah brief dan prompt untuk pengguna menjana visual aset, bukan imej yang sudah dijana atau diluluskan untuk production. Skop awal: 6 kuih biasa dan 4 sprite special, jumlah 10 PNG. Special mengikuti cadangan reka bentuk terkini; mekanik dan integrasinya belum dilaksanakan dalam kod.

## Senarai aset

| Fail cadangan | Subjek | Peranan |
| --- | --- | --- |
| onde_onde.png | Sebiji onde-onde hijau bersalut kelapa | Tile biasa |
| kuih_lapis.png | Sepotong kuih lapis merah jambu dan putih | Tile biasa |
| seri_muka.png | Sepotong kuih dua lapisan pulut putih dan kastard pandan hijau | Tile biasa |
| kuih_ketayap.png | Satu gulungan ketayap pandan | Tile biasa |
| ang_ku_kueh.png | Satu kuih merah bujur bercorak cangkerang kura-kura | Tile biasa |
| vadai.png | Satu masala vadai berbentuk cakera tanpa lubang | Tile biasa |
| special_lapis_horizontal.png | Lapis special dengan penanda kiri dan kanan | Match 4; bersihkan baris |
| special_lapis_vertical.png | Lapis special dengan penanda atas dan bawah | Match 4; bersihkan kolum |
| special_keria.png | Keria cincin bersalut gula dengan aksen special | Match 5 bentuk L/T; kawasan 3x3 |
| special_bom_bijan.png | Bebola kuih bom bersalut bijan dengan aksen special | Match 5 sebaris; kutip satu jenis kuih |

Cadangan destinasi kemudian: tile biasa ke assets/kuih, special ke assets/kuih/special. Jangan tambah special ke random spawn pool kuih biasa. Nama fail ialah kontrak aset yang dicadangkan, bukan rujukan texture yang sudah dipasang dalam game.

## Spesifikasi bersama

- Master: PNG RGBA 1024 x 1024 dengan alpha sebenar. PNG sahaja tidak membuktikan transparency.
- Satu fail untuk satu subjek. Bukan contact sheet atau sprite sheet.
- Subjek dan semua aksen berada dalam kawasan tengah 80 peratus canvas, sekurang-kurangnya 10 peratus margin pada setiap sisi. Jangan trim setiap imej secara berbeza.
- Pandangan orthographic dari atas pada elevasi 45 darjah, tanpa perspektif dramatik. Kamera dan cahaya sama bagi seluruh set.
- Gaya ilustrasi 2D makanan yang berisi, tepi kemas, outline coklat hangat dan shading lembut. Warna jelas pada board krim/coklat.
- Tiada muka, mata, tangan atau kaki pada kuih. Tiada pinggan, props, tulisan, UI atau latar.
- Jangan bake glow luas, ground shadow atau serpihan. FX dan shadow board diurus dalam game supaya tidak melimpah ke tile jiran.
- Eksport turunan 256 x 256 selepas master diluluskan; semak juga pada 64 x 64 dan 48 x 48.
- Lapis biasa dan special mesti berbeza dengan jelas. Penanda arah perlu besar dan melekat pada silhouette; jangan hanya beza warna.

## Cara guna prompt

Untuk setiap aset, gabungkan prompt asas di bawah dengan prompt subjeknya. Jana satu demi satu. Mulakan dengan Kuih Lapis biasa untuk menetapkan gaya; selepas diluluskan, sertakan imej itu sebagai rujukan gaya pada semua generation lain. Penetapan resolusi dan transparency perlu dibuat dalam pilihan generator jika tersedia, bukan bergantung pada ayat prompt sahaja.

### Prompt asas

```text
Create one isolated food sprite for Kuih Empire, a cozy Malaysian mobile match-3 game. Output a square 1024x1024 PNG with a genuine transparent alpha background. Use polished 2D hand-painted casual-game illustration: appetizing food, rounded volumes, crisp warm dark-brown contours, soft controlled shading, simplified readable texture, saturated natural food colors. Fixed orthographic three-quarter view from 45 degrees above, showing the top and front. Soft light comes from the upper left. Center the complete subject and all accents within the middle 80% of the canvas, leaving at least 10% transparent padding on every edge. Match the supplied approved sprite's camera, lighting, line weight and visual scale. Make the silhouette immediately recognizable at 64x64 pixels. One food item only. No plate, tray, banana-leaf base, scene, lettering, watermark, UI, human features, extra food, floor, ground shadow, cast shadow outside the silhouette, motion blur, or broad glow. No checkerboard or solid-color background. Do not crop the food. This is a game sprite, not a photograph, poster, icon inside a button, or contact sheet.
```

### 01 Onde onde

Filename: onde_onde.png

```text
Subject: one authentic onde-onde, a plump pandan-green glutinous rice ball coated with grated white coconut. Preserve a clear circular silhouette. Show pandan green between broad, simplified coconut flakes; do not cover the whole ball in solid white. Gentle moist sheen, soft chewy volume, emerald-green shaded edge. Keep it whole, without a bite or exposed filling. No sesame seeds, no leaf wrapper, no cluster of balls.
```

### 02 Kuih Lapis

Filename: kuih_lapis.png

```text
Subject: one rectangular slice of Malaysian steamed kuih lapis with six clearly separated alternating rose-pink and creamy-white layers. Show the smooth pink top and the layered front face. Slightly rounded corners, soft gelatinous texture, subtle moist highlights, a broad rectangular silhouette. Layers are horizontal within the food. No pandan-green stripes, sprinkles, pastry crust, butter-cake crumb, rainbow aura or special markers. This is the ordinary collectible tile.
```

### 03 Seri Muka

Filename: seri_muka.png

```text
Subject: one neat square piece of authentic seri muka, exactly two distinct layers: a thick creamy-white steamed glutinous-rice base with a few readable rice grains, and a smooth rich pandan-green custard top. Show the top and front face, with a clean visible boundary between the two layers. Soft square silhouette, gently rounded edges, moist custard sheen. No pink layer, no pyramid, no leaf cup, no stacked rainbow layers.
```

### 04 Kuih Ketayap

Filename: kuih_ketayap.png

```text
Subject: one authentic kuih ketayap, a short plump pandan-green crepe rolled into a cylinder. Arrange its long axis gently diagonally from lower left to upper right. Show a tucked seam and one slightly open end revealing a small amount of dark palm-sugar shredded coconut filling. Smooth soft crepe surface with a few broad pores. The elongated rolled silhouette must remain clear at small size. No triangle, diamond, leaf wrapper, sushi seaweed, separate sliced pieces or plate.
```

### 05 Ang Ku Kueh

Filename: ang_ku_kueh.png

```text
Subject: one authentic ang ku kueh, a plump low oval red glutinous-rice cake with a simple embossed tortoise-shell pattern on its domed top. Warm vermilion-red skin, slightly darker red grooves, subtle soft sheen. Use a few large readable embossed segments rather than fine ornamental carving. No lettering in the mould. No green leaf base, flower shape, actual turtle head, eyes, legs, orange biscuit texture or exposed filling.
```

### 06 Masala Vadai

Filename: vadai.png

```text
Subject: one masala vadai, a thick flattened golden lentil fritter with no center hole. Slightly irregular scalloped round edge, crisp amber crust, a few broad lentil pieces and tiny restrained dark-green herb flecks. A low rough disk with a warm golden-yellow center and toasted brown rim. Simplify the crunchy texture so it reads at 64 pixels. No donut ring, no cluster of dough balls, no sugar coating, no sesame coating, no garnish beside it.
```

### 07 Lapis special horizontal

Filename: special_lapis_horizontal.png

```text
Subject: a powered-up kuih lapis special sprite, derived from the approved ordinary kuih lapis reference. Keep the same camera, rectangular silhouette and layer thickness. Use clearly separated pink, cream and pandan-green layers to distinguish this special version. Add two bold edible-looking golden triangular direction markers attached to the left and right sides, pointing outward horizontally. These markers must be large enough to read at 64 pixels. The complete food and markers fit within the same middle-80% safe area. No letters, detached arrows, broad aura or beam effect. This sprite communicates a horizontal row-clearing special.
```

### 08 Lapis special vertical

Filename: special_lapis_vertical.png

```text
Subject: the vertical variant of the approved special kuih lapis sprite. Preserve the exact food shape, camera, layered colors, lighting and outline weight from the horizontal reference. Change only the direction markers: remove the left and right markers, and place matching bold edible-looking golden triangular markers at the upper and lower edges, pointing upward and downward in screen space. Keep all markers within the middle-80% safe area. Do not rotate the food or camera, and do not generate another horizontal variant. No lettering, broad aura or beam effect. This sprite communicates a vertical column-clearing special.
```

### 09 Keria special

Filename: special_keria.png

```text
Subject: one special kuih keria, an authentic sweet-potato doughnut with a thick golden-brown ring and a large clearly open center hole. Show a sugar-coated crust, soft rounded dough and broad simplified sugar highlights. Add three large cream-white sugar accents spaced around the top of the ring and a narrow golden rim highlight to distinguish it as a powered-up food sprite. Keep its silhouette clearly different from the solid vadai disk. The center hole must have genuine transparency. No frosting rainbow, sprinkles, plate, detached particles, cartoon face or baked explosion. This sprite represents a 3x3 area-clearing special.
```

### 10 Bom Bijan special

Filename: special_bom_bijan.png

```text
Subject: one special kuih bom bijan, a round golden fried glutinous-rice ball coated in large simplified ivory sesame seeds. Toasted amber-gold crust, plump spherical volume, clean circular silhouette. Add a narrow cream-and-gold sugar ribbon around its middle as a deliberate fictional game accent, with three large jewel-like sugar highlights in pink, green and blue to signal its all-colors targeting ability. Keep the real sesame-ball food appearance dominant. No coconut flakes, pandan-green ball, metal bomb, fuse, fire, skull, exposed filling, detached sparkles or broad glow. This sprite represents a special that collects one selected kuih type; two such specials can trigger a board wipe in the proposed game rules.
```

## Semakan sebelum masuk game

1. Buka pada latar putih, hitam dan warna board krim. Pastikan alpha sebenar, tiada kotak background, checkerboard palsu atau halo tepi.
2. Bandingkan semua sprite pada 64 dan 48 px. Onde-onde, Seri Muka dan Ketayap berkongsi hijau tetapi mesti dikenali melalui bentuk; Vadai, Keria dan Bom berkongsi emas tetapi berbeza melalui cakera, lubang dan bebola.
3. Pastikan kamera, ketebalan outline, saiz tampak dan margin konsisten. Bagi Lapis dua arah, putaran subjek tidak berubah.
4. Semak sendiri rupa makanan. Label budaya dalam kod placeholder lama bukan rujukan yang boleh dipercayai untuk bentuk final.
5. Simpan master yang diluluskan dan eksport PNG runtime tanpa mengubah canvas/pivot. Selepas import Godot, semak pada tile sebenar, order panel dan recipe book.
6. Semak lesen dan syarat penggunaan generator yang dipilih sebelum release. Prompt sahaja tidak mengesahkan hak penggunaan atau kualiti output.

Tiada fail imej dihasilkan atau script gameplay diubah oleh penyediaan brief ini. Kod KuihIcon semasa masih melukis bentuk procedural; memasukkan PNG ke folder sahaja belum menggantikan visual. Penggunaan KuihData.texture, renderer special dan migrasi identity perlu dibuat pada fasa integrasi aset.

## Rujukan bentuk makanan

- [Kuih Lapis](https://goingplaces.malaysiaairlines.com/malaysa-kuih/)
- [Kuih Keria](https://www.malaysia.travel/explore/must-try-local-food-in-melaka)
- [Kuih Bom Bijan](https://resepichenom.com/resepi/kuih-bom-bijan-kelapa)
- [Kuih Ketayap](https://www.ajinomoto.com.my/bm/resipi/kuih-gulung-ketayap)
- [Ang Ku Kueh](https://www.nyonyacooking.com/recipes/ang-ku-kueh~QRcnQUq1t)
- [Seri Muka](https://en.wikipedia.org/wiki/Seri_muka)
- [Onde-onde](https://prpm.dbp.gov.my/Cari1?d=176312&keyword=onde-onde)
- [Masala Vadai](https://nutriweb.org.my/cms/picture/upload/file/hcwo-vol-3.pdf)

Rujukan menyokong identiti makanan; arah clear, letupan, penanda emas dan aturan combo ialah reka bentuk fiksyen permainan.
