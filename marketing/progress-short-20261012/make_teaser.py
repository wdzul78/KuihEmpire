from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps
from pathlib import Path
root = Path(__file__).parent
project = root.parents[1]
def font(n): return ImageFont.truetype(str(project/'assets/fonts/fredoka_v1/Fredoka.ttf'),n)
bg = Image.open(project/'assets/stalls/family_stall/complete/background_v2.png').convert('RGB')
logo = Image.open(project/'assets/ui/logo_dessert.png').convert('RGBA')
def make(size, output):
    w,h=size
    im=ImageOps.fit(bg,size).filter(ImageFilter.GaussianBlur(5)).convert('RGBA')
    im.alpha_composite(Image.new('RGBA',size,(43,28,14,95)))
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((w*.25,h*.055,w*.75,h*.095),24,fill='#fff0d0')
    d.text((w/2,h*.075),'GAME KUIH TEMPATAN',font=font(30),fill='#633921',anchor='mm')
    lg=ImageOps.contain(logo,(int(w*.85),int(h*.28)))
    im.alpha_composite(lg,((w-lg.width)//2,int(h*.12)))
    for j,n in enumerate(['onde_onde','kuih_ketayap','ang_ku_kueh','kuih_lapis','kuih_koci','keria']):
        tile=Image.open(project/f'assets/kuih/cartoon_v3/{n}.png').convert('RGBA')
        tile=ImageOps.contain(tile,(int(w*.235),int(w*.235)))
        x=int(w*(.15+.35*(j%3))) if False else int(w*(.05+.31*(j%3)))
        y=int(h*.40+(j//3)*w*.23)
        im.alpha_composite(tile,(x,y))
    top=int(h*.72)
    d=ImageDraw.Draw(im)
    d.rounded_rectangle((55,top,w-55,int(h*.94)),36,fill=(255,240,208,247),outline='#e9ae44',width=6)
    d.text((w/2,h*.77),'COMING SOON',font=font(78 if h>1500 else 65),fill='#3e7839',anchor='mm')
    d.text((w/2,h*.824),'Match kuih. Hias gerai.',font=font(42 if h>1500 else 36),fill='#633921',anchor='mm')
    d.text((w/2,h*.864),'Target: launch MVP dulu.',font=font(37 if h>1500 else 32),fill='#946344',anchor='mm')
    d.text((w/2,h*.908),'Ikuti progress Kuih Empire',font=font(32 if h>1500 else 29),fill='#3e7839',anchor='mm')
    im.convert('RGB').save(root/output)
make((1080,1920),'poster_coming_soon.jpg')
make((1080,1350),'poster_feed.jpg')
