from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

root = Path(__file__).parent
project = root.parents[1]
font_path = project / 'assets/fonts/fredoka_v1/Fredoka.ttf'
def font(size): return ImageFont.truetype(str(font_path), size)
cards = [
    ('Kuih tempatan jadi game?', 'Ini progress Kuih Empire setakat ini.', 'PROGRESS UPDATE'),
    ('Padankan kuih kegemaran!', 'Match-3 dengan rasa tempatan.', 'GAMEPLAY'),
    ('Combo makin sedap!', 'Bagus!  Sedapnyaaa!  Terbaek!', 'COMBO'),
    ('Special pun ada!', 'Lebih banyak cara untuk clear board.', 'SPECIAL KUIH'),
    ('Gerai pun boleh dihias.', 'Selesaikan task, bina gerai impian.', 'HIAS GERAI'),
    ('Kenali koleksi kuih kita.', 'Recipe Book sedang dibangunkan.', 'RECIPE BOOK'),
    ('COMING SOON', 'Masih jauh perjalanan. Target: MVP dulu!', 'KUIH EMPIRE'),
]
for i, (heading, sub, label) in enumerate(cards):
    im = Image.new('RGBA', (1080, 1920), '#fff0d0')
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 1080, 12), fill='#e99637')
    d.rounded_rectangle((345, 40, 735, 96), 28, fill='#3e7839')
    d.text((540, 67), label, font=font(27), fill='white', anchor='mm')
    size = 64 if i == 6 else 54
    d.text((540, 156), heading, font=font(size), fill='#633921', anchor='mm')
    d.text((540, 227), sub, font=font(32), fill='#946344', anchor='mm')
    d.rounded_rectangle((123, 268, 957, 1732), 22, fill='#88502b')
    d.rectangle((135, 280, 945, 1720), fill=(0,0,0,0))
    d.text((540, 1780), 'KUIH EMPIRE  •  WORK IN PROGRESS', font=font(28), fill='#87583c', anchor='mm')
    if i == 6:
        d.rounded_rectangle((220, 1240, 860, 1550), 32, fill=(255,240,208,245), outline='#e6a548', width=5)
        d.text((540, 1320), 'COMING SOON', font=font(58), fill='#3e7839', anchor='mm')
        d.text((540, 1410), 'Ikuti perkembangan', font=font(36), fill='#633921', anchor='mm')
        d.text((540, 1470), 'Kuih Empire', font=font(42), fill='#633921', anchor='mm')
    im.save(root / f'caption_{i+1:02}.png')

