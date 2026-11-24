"""Proposed final set of figures, in article order, on one board.  Run from paper/softwarex/."""
from PIL import Image, ImageDraw, ImageFont
F = [("fig1_A", "Fig. 1  Architecture: modules and key functions (1A)"),
     ("X7_app", "Fig. 2  Shiny app: N balance waterfall (X7)"),
     ("fig2_A", "Fig. 3  Farm: balance dose map + terms per plot (2A)"),
     ("fig3_B", "Fig. 4  P01 rotation 2019-2026, legend on top (3B)"),
     ("X6_organic_plan", "Fig. 5  Organic + mineral plan (X6)"),
     ("fig4_D", "Fig. 6  P and K: rotation doses + soil classes, one row (4D)"),
     ("X5_prescription_workflow", "Fig. 7  From Sentinel-2 to ISOXML, step by step (X5, replaces Fig. 5)"),
     ("fig6_A", "Fig. 8  Six prescription methods, rule above map (6A)"),
     ("X9_tables", "Fig. 9  agrinutri_tables(): re-parameterising the balance (X9)")]
W = 1500
font = ImageFont.truetype("arialbd.ttf", 34)
tiles = []
for k, txt in F:
    im = Image.open(f"layouts/{k}.png").convert("RGB")
    w = W // 2 if k == "X6_organic_plan" else W          # X6 is a one-column figure
    im = im.resize((w, int(im.height * w / im.width)))
    t = Image.new("RGB", (W, im.height + 70), "white")
    d = ImageDraw.Draw(t); d.rectangle([0, 0, W, 60], fill=(235, 240, 246))
    d.text((16, 12), txt, font=font, fill=(0, 60, 120)); t.paste(im, ((W - w) // 2, 70)); tiles.append(t)
cols = [tiles[0::2], tiles[1::2]]
hh = [sum(t.height + 30 for t in c) for c in cols]
sheet = Image.new("RGB", (2 * W + 90, max(hh) + 30), (200, 200, 200))
for i, c in enumerate(cols):
    y = 30
    for t in c: sheet.paste(t, (30 + i * (W + 30), y)); y += t.height + 30
sheet.save("layouts/best_combo.png"); print(sheet.size)
