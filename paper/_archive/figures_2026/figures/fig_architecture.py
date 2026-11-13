#!/usr/bin/env python3
"""NFert architecture diagram (Figure 1) for the SoftwareX article.

Grayscale block/flow diagram: the agronomic core (per-term DPI balance ->
N_balance(), plus P/K balances, MAS caps, distribution plan) produces a
field-level target dose that flows into the precision-agriculture module
(vegetation indices, GPR canopy traits, NNI, mass-balance-constrained
variable-rate prescriptions, machine export). DPI coefficient tables underpin
the whole package.

Reproducible: run `python fig_architecture.py` with pubfig.py alongside.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import pubfig

pubfig.set_style("elsevier")
fig, ax = pubfig.new_figure(width="double", aspect=0.60, journal="elsevier")
ax.set_xlim(0, 12)
ax.set_ylim(0, 10)
ax.axis("off")

LW = 0.8

def box(cx, cy, text, w=4.9, h=0.85, fc="white", bold=False):
    ax.add_patch(FancyBboxPatch(
        (cx - w / 2, cy - h / 2), w, h, mutation_scale=5,
        boxstyle="round,pad=0.02", linewidth=LW,
        edgecolor="black", facecolor=fc, zorder=3))
    ax.text(cx, cy, text, ha="center", va="center", zorder=4,
            fontweight="bold" if bold else "normal")

def varrow(cx, y0, y1):
    ax.add_patch(FancyArrowPatch((cx, y0), (cx, y1), mutation_scale=7,
                 arrowstyle="-|>", linewidth=LW, color="black", zorder=2))

def group(cx, y0, y1, title, w=5.4):
    ax.add_patch(FancyBboxPatch(
        (cx - w / 2, y0), w, y1 - y0, mutation_scale=5,
        boxstyle="round,pad=0.02", linewidth=LW, linestyle="--",
        edgecolor="0.35", facecolor="none", zorder=1))
    ax.text(cx, y1 + 0.28, title, ha="center", va="bottom", fontweight="bold")

XC, XP = 2.85, 9.15                 # core / precision column centres
rows = [8.75, 7.55, 6.45, 5.35, 4.20, 2.95]

# --- dashed group containers ---------------------------------------------
group(XC, 2.45, 9.25, "Agronomic core (DPI 2026 balance)")
group(XP, 2.45, 9.25, "Precision-agriculture module")

# --- agronomic core (left) -----------------------------------------------
box(XC, rows[0], "Soil analysis, crop, yield, climate,\nprevious crop, organic inputs", fc="0.95")
box(XC, rows[1], "Per-term N balance (A to G)\n$\\rightarrow$  N_balance()")
box(XC, rows[2], "P_balance()      K_balance()")
box(XC, rows[3], "MAS caps:\nget_MAS() / check_MAS()")
box(XC, rows[4], "plan_distribution()\nfarm_balance()")
box(XC, rows[5], "Field-level target dose", fc="0.80", bold=True)
for a, b in zip(rows[:-1], rows[1:]):
    varrow(XC, a - 0.43, b + 0.43)

# --- precision module (right) --------------------------------------------
box(XP, rows[0], "Sentinel-2 L2A time series", fc="0.95")
box(XP, rows[1], "compute_vi()\nvegetation indices")
box(XP, rows[2], "estimate_biophysical()\nGPR canopy traits")
box(XP, rows[3], "compute_NNI()\nNitrogen Nutrition Index")
box(XP, rows[4], "variable_rate_N()\nbuild_strip_prescription()")
box(XP, rows[5], "export_prescription()\nISOXML / shapefile / GeoJSON")
for a, b in zip(rows[:-1], rows[1:]):
    varrow(XP, a - 0.43, b + 0.43)

# --- core -> precision link (the field-level target dose) ----------------
link = FancyArrowPatch((XC + 2.45, rows[5]), (XP - 2.45, rows[4]),
                       connectionstyle="arc3,rad=-0.18", mutation_scale=9,
                       arrowstyle="-|>", linewidth=1.1, color="black", zorder=5)
ax.add_patch(link)
ax.text(6.0, 3.05, "target dose\n(mass-balance\nconstraint)",
        ha="center", va="center", fontsize=6, style="italic")

# --- DPI coefficient tables at the base ----------------------------------
box(6.0, 1.15, "DPI 2026 coefficient tables: crop uptake, leaching and immobilization "
                "factors, MAS limits,\norganic-N efficiency, fertiliser catalogue",
    w=11.4, h=0.95, fc="0.90")
varrow(XC, 1.62, 2.45)
varrow(XP, 1.62, 2.45)

pubfig.check_style("elsevier")
pubfig.save_figure(fig, "fig1_architecture", journal="elsevier",
                   kind="lineart", outdir=os.path.dirname(os.path.abspath(__file__)))
