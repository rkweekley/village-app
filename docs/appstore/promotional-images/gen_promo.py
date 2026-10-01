from PIL import Image, ImageDraw, ImageFont
import hashlib

TEAL   = (13, 124, 102)
WHITE  = (255, 255, 255)
INK    = (44, 52, 50)
NEUTRAL= (239, 235, 231)
GREY   = (110, 118, 116)
F      = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FR     = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
S = 1024

def font(p, s): return ImageFont.truetype(p, s)

def center(d, y, text, f, fill):
    w = d.textlength(text, font=f)
    d.text(((S - w) / 2, y), text, font=f, fill=fill)
    return w

def sp_text(d, xy, text, f, fill, sp):
    x, y = xy
    for ch in text:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + sp
    return x - xy[0] - sp

def build(kind):
    if kind == "monthly": bg, band_top = WHITE, True
    else:                bg, band_top = NEUTRAL, False
    im = Image.new("RGB", (S, S), bg)
    d = ImageDraw.Draw(im)
    band_h = 190

    if band_top:
        d.rectangle([0, 0, S, band_h], fill=TEAL)
        w = d.textlength("V I L L A G E", font=font(F, 62))
        d.text(((S - w) / 2, (band_h - 78) / 2), "V I L L A G E", font=font(F, 62), fill=WHITE)
        center(d, 320, "Monthly", font(F, 168), TEAL)
        center(d, 545, "Full access for the whole", font(FR, 54), INK)
        center(d, 620, "family", font(FR, 54), INK)
        d.rectangle([(S - 420) / 2, 760, (S + 420) / 2, 766], fill=TEAL)
        center(d, 820, "villagefamily.app", font(FR, 44), GREY)
    else:
        d.text((72, 74), "V I L L A G E", font=font(F, 50), fill=TEAL)
        center(d, 320, "Annual", font(F, 168), TEAL)
        center(d, 545, "A full year of family", font(FR, 54), INK)
        center(d, 620, "access", font(FR, 54), INK)
        d.rectangle([0, S - band_h, S, S], fill=TEAL)
        w = d.textlength("villagefamily.app", font=font(FR, 46))
        d.text(((S - w) / 2, S - band_h + (band_h - 58) / 2), "villagefamily.app",
               font=font(FR, 46), fill=WHITE)

    im = im.convert("RGB")
    return im

for k in ("monthly", "annual"):
    im = build(k)
    p = f"promo-{k}.png"
    im.save(p, "PNG", dpi=(72, 72))
    chk = Image.open(p)
    print(f"{p}: {chk.size} mode={chk.mode} alpha={'alpha' in chk.mode.lower()} "
          f"corner_tl={chk.getpixel((0,0))} corner_br={chk.getpixel((1023,1023))} "
          f"sha256={hashlib.sha256(open(p,'rb').read()).hexdigest()[:16]} "
          f"px_sha={hashlib.sha256(chk.tobytes()).hexdigest()[:16]} bytes={__import__('os').path.getsize(p)}")
