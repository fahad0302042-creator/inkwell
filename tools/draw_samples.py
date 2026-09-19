"""Generate original geometric cover art and a four-page silent-comic sample. Requires Pillow."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import random, math
ROOT = Path(__file__).resolve().parents[1]
FONT = '/usr/share/fonts/truetype/dejavu/'
def font(n, bold=False, serif=False):
    return ImageFont.truetype(FONT + ('DejaVuSerif' if serif else 'DejaVuSans') + ('-Bold' if bold else '') + '.ttf', n)
def label(d, xy, text, n, fill, serif=False, bold=False):
    d.text(xy,text,font=font(n,bold,serif),fill=fill)
def city(d, y, fg, seed=4, w=600):
    r=random.Random(seed)
    for x in range(-20,w,48):
        h=r.randint(45,210)
        d.rectangle((x,y-h,x+43,y+100),fill=fg)
        for wy in range(y-h+17,y-8,24):
            for wx in range(x+9,x+38,14):
                if r.random()>.4: d.rectangle((wx,wy,wx+4,wy+7),fill='#8f9a81')
def person(d,x,y,s=1,color='#142d2e'):
    d.ellipse((x-12*s,y-68*s,x+12*s,y-44*s),fill=color)
    d.polygon([(x-14*s,y-45*s),(x+13*s,y-45*s),(x+22*s,y-5*s),(x-24*s,y-5*s)],fill=color)
    d.line((x-10*s,y-8*s,x-15*s,y+23*s),fill=color,width=max(1,int(7*s)))
    d.line((x+9*s,y-8*s,x+17*s,y+22*s),fill=color,width=max(1,int(7*s)))
for key, bg, fg, title, sub in [('moon','#b9bcb0','#183d38','MOONLIT\nCOURIER','A LETTER TO THE MOON'),('garden','#e4c9a2','#496d53','PAPER\nGARDENS','SMALL THINGS, SLOWLY'),('signal','#b46742','#172e36','SIGNAL\n/ 09','SOMETHING IS LISTENING'),('sea','#99c3c1','#1d5860','THE\nLAST BLUE','BEYOND THE SHORE')]:
    im=Image.new('RGB',(600,900),bg); d=ImageDraw.Draw(im)
    r=random.Random(9)
    if key=='moon':
        d.ellipse((225,80,670,525),fill='#e9e6c9')
        for _ in range(35):
            x,y=r.randrange(600),r.randrange(540);d.ellipse((x,y,x+2,y+2),fill='#f7f1d6')
        city(d,690,'#729181');city(d,770,fg,8)
        d.polygon([(0,860),(600,700),(600,900),(0,900)],fill='#0e2926');person(d,350,790,1.8,'#e3dbb7')
    elif key=='garden':
        for x in range(20,700,110):
            d.arc((x-240,250,x+120,1200),180,350,fill=fg,width=5)
            for i in range(5):
                y=470+i*83; d.ellipse((x-20-i*6,y-50,x+65,y+12),fill=['#698967','#9eaa76','#345d48'][i%3])
        d.ellipse((340,270,520,450),fill='#f1e7c7')
    elif key=='signal':
        for i in range(11):
            d.ellipse((90-i*32,320-i*32,510+i*32,740+i*32),outline='#dca06d',width=2)
        city(d,810,fg,13);d.line((340,800,340,310),fill=fg,width=9)
        d.polygon([(340,320),(220,400),(360,425)],fill=fg)
        d.ellipse((327,295,353,321),fill='#efe8c5')
    else:
        d.ellipse((330,280,505,455),fill='#e5e4bc')
        for i in range(7):
            pts=[(x,530+i*58+math.sin(x/92+i)*28) for x in range(0,601,4)]
            d.polygon(pts+[(600,900),(0,900)],fill=['#76a9a9','#548e97','#3e7d8c','#2d6877','#1d5860','#14434d','#16363f'][i])
        d.polygon([(305,720),(390,710),(370,730),(325,735)],fill='#efe9ce');d.line((348,710,348,610),fill='#efe9ce',width=4)
        d.polygon([(353,615),(353,700),(400,695)],fill='#eee3bf')
    label(d,(40,46),'I N K W E L L   /   0 1',15,fg)
    label(d,(38,92),title,58,fg,serif=True)
    # Top typography contrasts the quiet lower illustration.
    label(d,(40,260),sub,13,fg)
    label(d,(40,860),'O R I G I N A L   S A M P L E',12,'#f2edda')
    im.save(ROOT/f'assets/covers/{key}.png',optimize=True)

captions=[('When the city falls asleep,','the smallest letters begin their journey.'),('Across the rooftops, above the noise,','one address is still awake.'),('Some messages need no words.','They only need someone to look up.'),('And sometimes, the night writes back.','Tomorrow, another journey.')]
for i,(a,b) in enumerate(captions,1):
    im=Image.new('RGB',(800,1200),'#f3eddd');d=ImageDraw.Draw(im)
    label(d,(38,28),'MOONLIT COURIER    /    CHAPTER 01',16,'#31413c')
    d.rectangle((32,72,768,560),fill='#bec8b7',outline='#1d3834',width=4)
    d.ellipse((440,100,690,350),fill='#f3eacc',outline='#31483e',width=2)
    city(d,470,'#718b79',seed=i,w=800)
    city(d,560,'#284d43',seed=i+8,w=800)
    d.rectangle((32,560,768,610),fill='#f3eddd')
    label(d,(45,572),a,20,'#243d35',serif=True)
    d.rectangle((32,635,389,1090),fill='#cad0ba',outline='#203c34',width=4)
    d.rectangle((409,635,768,1090),fill='#4e6e5c',outline='#203c34',width=4)
    for k in range(8):
        d.line((38,735+k*45,382,660+k*45),fill='#899c85',width=2)
    person(d,222,930,3.0)
    # Envelope held toward the sky.
    d.polygon([(240,800),(313,780),(329,831),(255,851)],fill='#f5e8c7',outline='#294638')
    d.line((241,800,285,818,313,780),fill='#294638',width=3)
    if i<4:
        d.ellipse((484,687,707,910),fill='#ede4c3')
        for k in range(13):
            x=435+(k*97)%295;y=680+(k*41)%350;d.ellipse((x,y,x+3,y+3),fill='#efe5c7')
        person(d,570,1060,1.3,'#1f3b32')
    else:
        d.polygon([(456,820),(680,743),(715,885),(488,963)],fill='#ede4c3')
        d.line((456,820,600,866,680,743),fill='#304c3d',width=4)
        label(d,(505,985),'THANK YOU.',19,'#f1e8c9',serif=True)
    label(d,(38,1120),b,19,'#243d35',serif=True)
    label(d,(38,1170),'ORIGINAL BUNDLED SAMPLE  /  INKWELL STUDIO',11,'#718172')
    label(d,(721,1160),f'{i:02}',22,'#243d35',serif=True)
    im.save(ROOT/f'assets/pages/page_{i}.png',optimize=True)
# Simple app icon, replacing default Flutter branding.
for folder,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    im=Image.new('RGB',(size,size),'#173e35');d=ImageDraw.Draw(im);s=size/100
    d.polygon([(20*s,25*s),(48*s,32*s),(48*s,77*s),(20*s,70*s)],fill='#e3edcd')
    d.polygon([(52*s,32*s),(80*s,25*s),(80*s,70*s),(52*s,77*s)],fill='#e3edcd')
    im.save(ROOT/f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png')
