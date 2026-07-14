#!/usr/bin/env python3
"""CERZOO Field 3 variable-rate prescription strategies (Figure 4), rebuilt to
Elsevier/SoftwareX spec: one panel per method, a shared perceptually-uniform
colour bar, text sized to the journal at final width.

Geometry from cerzoo_strategies.geojson (exported by _export_grids_geojson.R).
Run: python fig_prescriptions_pubfig.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import geopandas as gpd
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize
import pubfig

HERE = os.path.dirname(os.path.abspath(__file__))
gdf = gpd.read_file(os.path.join(HERE, "cerzoo_strategies.geojson"))

order = [("Uniform", "Uniform"),
         ("Calibration (inverse)", "Calibration\n(inverse)"),
         ("Calibration (direct)",  "Calibration\n(direct)"),
         ("Quantile classes",      "Quantile\nclasses"),
         ("NNI zones",             "NNI zones")]

pubfig.set_style("elsevier", color=True)
fig, axes = pubfig.new_figure(width=118, nrows=2, ncols=3, height_mm=130,
                              journal="elsevier")
try:
    fig.get_layout_engine().set(wspace=0.0, hspace=0.04, w_pad=0.01, h_pad=0.02)
except Exception:
    pass
norm = Normalize(vmin=165, vmax=235)
cmap = "viridis"
flat = axes.ravel()
for ax, (name, title) in zip(flat, order):
    sub = gdf[gdf["strategy"] == name]
    sub.plot(column="dose", ax=ax, cmap=cmap, norm=norm,
             edgecolor="0.55", linewidth=0.08)
    ax.set_title(title, pad=3)
    ax.set_aspect("equal")
    ax.set_axis_off()
# hide any unused cells (5 panels in a 2x3 grid leaves one empty)
for ax in flat[len(order):]:
    ax.set_visible(False)

sm = ScalarMappable(norm=norm, cmap=cmap); sm.set_array([])
cbar = fig.colorbar(sm, ax=axes.ravel().tolist(), orientation="horizontal",
                    fraction=0.06, pad=0.03, aspect=45)
cbar.set_label(r"Nitrogen dose (kg N ha$^{-1}$)")
pubfig.save_figure(fig, "cerzoo_prescription_strategies", journal="elsevier",
                   kind="lineart", outdir=HERE)
print("done prescription figure")
