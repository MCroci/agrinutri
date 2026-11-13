#!/usr/bin/env python3
"""CERZOO Field 3 seasonal time series, rebuilt to Elsevier/SoftwareX spec.

Figure 2: biophysical variables (LAI, Cm, canopy N, FVC), 2x2 panels.
Figure 3: Nitrogen Nutrition Index with agronomic zones.

Driven by the cached per-scene table (cerzoo_timeseries_data.csv). Text is sized
to the journal at final print width by pubfig. Run: python fig_timeseries_pubfig.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.patches import Patch
import pubfig

HERE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(HERE, "cerzoo_timeseries_data.csv"), parse_dates=["date"])

def date_axis(ax):
    ax.xaxis.set_major_locator(mdates.MonthLocator(interval=4))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
    for t in ax.get_xticklabels():
        t.set_rotation(30); t.set_ha("right")

# ===================== Figure 2: biophysical 2x2 =====================
pubfig.set_style("elsevier")
fig, axes = pubfig.new_figure(width="double", nrows=2, ncols=2, height_mm=120,
                              journal="elsevier", sharex=True)
panels = [("LAI",       r"LAI (m$^2$ m$^{-2}$)",   "#2E7D32"),
          ("Cm",        r"Cm (g cm$^{-2}$)",       "#8E24AA"),
          ("CNC_Cprot", r"Canopy N (g N m$^{-2}$)", "#C0392B"),
          ("FVC",       r"FVC (fraction)",          "#1F4E79")]
for ax, (v, ylab, col) in zip(axes.ravel(), panels):
    d = df[df["var"] == v].sort_values("date")
    x, m, s = d["date"].values, d["mean"].values, d["sd"].fillna(0).values
    ax.fill_between(x, m - s, m + s, color=col, alpha=0.18, linewidth=0)
    ax.plot(x, m, color=col, linewidth=0.9)
    ax.plot(x, m, "o", color=col, markersize=2.2, markeredgecolor="none")
    ax.set_ylabel(ylab)
    ax.margins(x=0.02)
    date_axis(ax)
pubfig.label_panels(axes, journal="elsevier")
fig.supxlabel("Acquisition date", fontsize=plt.rcParams["axes.labelsize"])
pubfig.save_figure(fig, "cerzoo_biophysical_ts", journal="elsevier",
                   kind="lineart", outdir=HERE)

# ============ Figure 3: NNI interpreted against the LAI trajectory ============
# NNI is meaningful only when a crop canopy is present; overlaying LAI shows
# which acquisitions are agronomically reliable and explains the gaps (LAI ~ 0
# outside the maize cycles) and the off-season scatter.
from matplotlib.lines import Line2D
pubfig.set_style("elsevier")
fig, ax = pubfig.new_figure(width="double", aspect=0.40, journal="elsevier")
n   = df[df["var"] == "NNI"].sort_values("date")
lai = df[df["var"] == "LAI"].sort_values("date")
xN, mN, sN = n["date"].values, n["mean"].values, n["sd"].fillna(0).values

# --- LAI on a secondary axis: the canopy-development context ---
ax2 = ax.twinx()
LAI_C, LAI_F = "#3F6F3F", "#9CC49C"
ax2.fill_between(lai["date"].values, 0.0, lai["mean"].values,
                 color=LAI_F, alpha=0.45, linewidth=0, zorder=0)
ax2.plot(lai["date"].values, lai["mean"].values, color=LAI_C, linewidth=0.6,
         alpha=0.8, zorder=1)
ax2.set_ylim(0, 6.5)
ax2.set_ylabel(r"LAI (m$^2$ m$^{-2}$)", color=LAI_C)
ax2.tick_params(axis="y", colors=LAI_C)

# --- NNI on the primary axis, drawn above the LAI band ---
ax.set_zorder(ax2.get_zorder() + 1); ax.patch.set_visible(False)
NNI_C = "#8A3B00"
ax.axhspan(0.90, 1.10, color="#DCEFD8", alpha=0.85, zorder=0.5)  # optimal band
for y, ls in [(0.90, "--"), (1.00, "-"), (1.10, "--")]:
    ax.axhline(y, color="0.45", linestyle=ls, linewidth=0.6, zorder=2)
ax.fill_between(xN, mN - sN, mN + sN, color=NNI_C, alpha=0.16, linewidth=0, zorder=3)
ax.plot(xN, mN, color=NNI_C, linewidth=0.9, zorder=4)
ax.plot(xN, mN, "o", color=NNI_C, markersize=2.3, markeredgecolor="none", zorder=5)
ax.set_ylim(0, 2)
ax.set_ylabel("NNI (dimensionless)", color=NNI_C)
ax.tick_params(axis="y", colors=NNI_C)
ax.set_xlabel("Acquisition date")
ax.margins(x=0.01)
date_axis(ax)

handles = [
    Line2D([], [], color=NNI_C, marker="o", markersize=3, linewidth=0.9, label="NNI"),
    Patch(facecolor=LAI_F, edgecolor=LAI_C, linewidth=0.6, label="LAI (canopy development)"),
    Patch(facecolor="#DCEFD8", label="Optimal NNI band (0.90-1.10)"),
]
ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, -0.30),
          ncol=3, frameon=False, handlelength=1.4, columnspacing=1.4)
pubfig.save_figure(fig, "cerzoo_nni_ts", journal="elsevier", kind="lineart", outdir=HERE)
print("done timeseries figures")
