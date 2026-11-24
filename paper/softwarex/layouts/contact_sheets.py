"""One comparison sheet per figure with its layout alternatives (A = current layout of the article).
Run from paper/softwarex/ after layouts/layout_variants.R:  python layouts/contact_sheets.py
"""
from PIL import Image, ImageDraw, ImageFont

D = {
    "fig1": {"A": "current: modules with key functions",
             "B": "titles and equation only, no function names",
             "C": "one key function per box",
             "D": "greyscale"},
    "fig2": {"A": "current: map left, balance terms right",
             "B": "balance terms left (wider), map right",
             "C": "stacked: map above, terms below (1.5 column)",
             "D": "balance terms only, no map (doses in the bars)",
             "E": "map and balance vs standard dose per plot (dumbbell)",
             "F": "map and terms ordered by dose"},
    "fig3": {"A": "current: stacked terms, legend on the right",
             "B": "legend on top, wider bars",
             "C": "two panels: dose vs crop maximum above, terms below",
             "D": "horizontal bars, years on the vertical axis",
             "E": "dose and crop maximum dose with the rainfall curve",
             "F": "table of terms (year x term) with values"},
    "fig4": {"A": "current: rotation above, P and K classes below",
             "B": "rotation and farm plots above, P and K classes below",
             "C": "rotation left (wide), P and K classes stacked right",
             "D": "one row: rotation, P classes, K classes",
             "E": "rotation above, P and K in mg/kg (continuous) below",
             "F": "one row for P and one for K (doses + map)"},
    "fig5": {"A": "current: leaf area index and NNI",
             "B": "LAI, NNI and the NNI-zone prescription",
             "C": "LAI above NNI (single column)",
             "D": "NNI and the prescription only",
             "E": "LAI, NNI and the three NNI zones",
             "F": "NNI map and its histogram with the thresholds"},
    "fig6": {"A": "current: six columns, rule above map",
             "B": "three rows of two: rule beside map",
             "C": "two rows of three: rule above map",
             "D": "six maps in a row and one panel with all cell doses",
             "E": "difference from the balance dose, 2 x 3 maps",
             "F": "the six maps only, 2 x 3"},
    "extra": {"X1_pixel_balance": "balance per pixel on the regional soil maps",
              "X2_province": "province of Piacenza 2019-2026",
              "X3_sensitivity": "dose vs October-January rain and expected yield",
              "X4_runtime": "computing time vs number of fields",
              "X5_prescription_workflow": "how the prescription map is built, step by step"},
    "extra2": {"X6_organic_plan": "organic + mineral plan: slurry efficiency sets the urea dose",
               "X7_app": "Shiny app: N balance waterfall",
               "X9_tables": "agrinutri_tables(): edited uptake table re-parameterises the balance",
               "GA_graphical_abstract": "graphical abstract (13 x 5 cm)"},
}
W = 1500
try:
    font = ImageFont.truetype("arialbd.ttf", 34); small = ImageFont.truetype("arial.ttf", 30)
except OSError:
    font = small = ImageFont.load_default()
for fig, var in D.items():
    tiles = []
    for k, txt in var.items():
        im = Image.open(f"layouts/{k}.png" if fig.startswith("extra") else f"layouts/{fig}_{k}.png").convert("RGB")
        im = im.resize((W, int(im.height * W / im.width)))
        t = Image.new("RGB", (W, im.height + 70), "white")
        d = ImageDraw.Draw(t)
        d.rectangle([0, 0, W, 60], fill=(235, 240, 246))
        lab = k.split("_")[0] if fig.startswith("extra") else f"{fig.upper()}-{k}"
        d.text((16, 12), lab, font=font, fill=(0, 60, 120))
        d.text((200, 15), txt, font=small, fill=(30, 30, 30))
        t.paste(im, (0, 70))
        tiles.append(t)
    ncol = 2 if len(tiles) > 3 else len(tiles)
    rows = [tiles[i:i + ncol] for i in range(0, len(tiles), ncol)]
    rh = [max(t.height for t in r) for r in rows]
    sheet = Image.new("RGB", (ncol * W + (ncol + 1) * 30, sum(rh) + (len(rows) + 1) * 30), (200, 200, 200))
    y = 30
    for r, h in zip(rows, rh):
        x = 30
        for t in r:
            sheet.paste(t, (x, y)); x += W + 30
        y += h + 30
    sheet.save(f"layouts/{fig}_layouts.png")
    print(fig, sheet.size)
