"""Fig. 2 - Farm example: per-plot mineral N dose and balance terms.

Data: data/farm_plots.geojson and data/farm_terms.csv from fig2_data.R
(bundled demo farm inst/extdata/example_farm.geojson).
Run from paper/softwarex/:  python fig2_farm.py
"""
import csv

import geopandas as gpd
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

import pubfig

p = pubfig.set_style("elsevier", color=True)
fig, (ax_m, ax_b) = pubfig.new_figure(width="double", ncols=2, aspect=0.42,
                                      journal="elsevier")
fig.subplots_adjust(wspace=0.35)

# (a) map ---------------------------------------------------------------------
g = gpd.read_file("data/farm_plots.geojson")
norm = mpl.colors.Normalize(vmin=0, vmax=200)
cmap = mpl.colormaps[pubfig.SEQUENTIAL_ALT]
g.plot(ax=ax_m, column="N_target", cmap=cmap, norm=norm, edgecolor="black", lw=0.5)
over = g[~g["MAS_ok"].astype(bool)]
if len(over):
    over.plot(ax=ax_m, facecolor="none", edgecolor="black", hatch="////", lw=0.8)
for _, r in g.iterrows():
    c = r.geometry.representative_point()
    ax_m.annotate(r["plot_id"], (c.x, c.y), ha="center", va="center",
                  fontsize=p.min_fontsize_pt, color="black",
                  bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.8))
ax_m.set_axis_off()
ax_m.set_aspect("equal")
sm = mpl.cm.ScalarMappable(norm=norm, cmap=cmap)
cb = fig.colorbar(sm, ax=ax_m, fraction=0.04, pad=0.02)
cb.set_label("Mineral N dose (kg N ha$^{-1}$)")
pubfig.add_scalebar(ax_m, 200, "200 m", loc="lower left")
pubfig.add_north_arrow(ax_m)
ax_m.text(1.0, -0.04, "hatched: dose above MAS", transform=ax_m.transAxes,
          fontsize=p.min_fontsize_pt, va="top", ha="right")

# (b) balance terms --------------------------------------------------------------
rows = list(csv.DictReader(open("data/farm_terms.csv", encoding="utf-8")))
ids = [r["plot_id"] for r in rows]
val = lambda k: np.array([float(r[k]) for r in rows])
y = np.arange(len(rows))[::-1]
# Okabe-Ito colours (colour-blind safe); demand/losses vs supplies
pos = [("A", "A", "#0072B2"), ("C", "C", "#56B4E9"), ("D", "D", "#E69F00")]
neg = [("B", "B", "#009E73"), ("E", "E", "#CC79A7"), ("F", "F", "#F0E442"),
       ("G", "G", "#999999"), ("Forg", "F$_{org}$", "white")]
left = np.zeros(len(rows))
for k, lab, fc in pos:
    v = val(k)
    ax_b.barh(y, v, left=left, color=fc, edgecolor="black", lw=0.4, height=0.65, label=lab)
    left += v
right = np.zeros(len(rows))
for k, lab, fc in neg:
    v = np.clip(val(k), 0, None)
    ax_b.barh(y, -v, left=-right, color=fc, edgecolor="black", lw=0.4, height=0.65,
              label=lab, hatch="xxx" if k == "Forg" else None)
    right += v
dose = val("N_dose")
ax_b.plot(dose, y, ls="none", marker="D", ms=3.2, mfc="white", mec="black", mew=0.7,
          label="mineral N dose")
ax_b.axvline(0, color="black", lw=0.6)
ax_b.set_yticks(y, ids)
ax_b.set_xlabel("Balance term (kg N ha$^{-1}$): $-$ supply | demand and losses $+$")
h, l = ax_b.get_legend_handles_labels()
order = [l.index(x) for x in ["A", "C", "D", "B", "E", "F", "G", "F$_{org}$", "mineral N dose"]]
ax_b.legend([h[i] for i in order], [l[i] for i in order], ncols=9, loc="lower center", bbox_to_anchor=(0.5, 1.0), frameon=False,
            columnspacing=0.6, handlelength=1.0, handletextpad=0.3, fontsize=p.min_fontsize_pt)

pubfig.label_panels([ax_m, ax_b], journal="elsevier")
pubfig.save_figure(fig, "figures/fig2_farm", journal="elsevier", kind="lineart")
