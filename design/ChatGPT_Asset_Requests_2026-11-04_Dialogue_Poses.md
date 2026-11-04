# Permintaan aset imej untuk ChatGPT — pose dialog Aina (4 November 2026)

Dialog sebelum stage meletakkan pelanggan di kiri dan Aina di kanan, supaya mereka saling berpandangan. Lukisan pelanggan sedia ada sudah menghadap ke kanan dan boleh terus digunakan. Lukisan Aina pula menghala tangannya ke kiri tetapi matanya ke kanan, jadi dia tidak dapat memandang pelanggan dari mana-mana sisi. Buat sementara, permainan membalikkan Aina supaya matanya memandang pelanggan. Akibatnya, tangannya kini menunjuk ke luar skrin.

Untuk setiap item:

1. Salin **Gaya asas** dan prompt item ke ChatGPT.
2. Lampirkan imej rujukan yang dinyatakan.
3. Simpan hasil di laluan **Simpan ke**, pada saiz 1024×1536.
4. Beritahu Claude. Claude akan membuat backup dahulu, kemudian menyambungkan kod.

Permainan menggunakan pose baharu secara automatik sebaik sahaja kedua-dua fail ada, jadi kod tidak perlu diubah. Jika hanya satu fail yang siap, permainan terus menggunakan lukisan lama.

## Pose dialog Aina (2 imej, wajib)

Lampirkan: `assets/characters/fullbody_v2/aina.png` (rupa Aina) dan `assets/characters/fullbody_v2/kakak.png` (sudut badan yang betul, tetapi dicerminkan).

**Gaya asas:**

> Polished 2D casual mobile game character, full body, standing, matching the first attached reference exactly: same Aina, same face, pink floral tudung, pink baju kurung, cream apron with two brown buttons and a front pocket, white shoes, same outline weight, shading, colours and proportions. Body, head AND eyes all turned in three-quarter view towards the viewer's LEFT, as if talking to someone standing on the left of the frame. Modest, respectful and suitable for all ages. Centered, feet visible, same scale and foot position as the reference, 1024×1536 canvas. TRUE TRANSPARENT background (real alpha, no checkerboard, no white box), with the same soft glow edge as the reference. NO text, letters, numbers or badges.

| Simpan ke | Prompt |
|---|---|
| `assets/characters/dialogue_v1/aina_talk.png` | Aina talking happily: mouth open in a friendly smile, eyes looking left at the customer, the hand nearer the viewer's left raised with an open palm towards the left, the other hand resting on her apron. |
| `assets/characters/dialogue_v1/aina_listen.png` | Aina listening warmly: gentle closed-mouth smile, eyes looking left at the customer, head tilted slightly, both hands held together in front of her apron. |

## Pelanggan yang boleh diperbaiki kemudian (pilihan)

Tiga pelanggan berdiri menghadap ke hadapan, tetapi mata mereka sudah memandang ke kanan, jadi masih boleh diterima. Lukis semula hanya jika mereka masih nampak kaku semasa ujian main. Gunakan gaya asas di atas, gantikan "towards the viewer's LEFT" dengan "towards the viewer's RIGHT", dan lampirkan lukisan asal watak itu.

| Simpan ke | Prompt |
|---|---|
| `assets/characters/fullbody_v2/adik_danish.png` | Adik Danish, same boy and uniform as the attached reference, waving with the hand on the viewer's right. |
| `assets/characters/fullbody_v2/adik_priya.png` | Adik Priya, same girl and uniform as the attached reference, holding her lunch box, smiling towards the right. |
| `assets/characters/fullbody_v2/pak_mat.png` | Pak Mat, same caretaker as the attached reference, leaning lightly on his broom, smiling towards the right. |
