"""Fig. 1 - NFert software architecture (modules, data and outputs).

Run from paper/softwarex/:  python fig1_architecture.py
"""
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

import pubfig

p = pubfig.set_style("elsevier")
fig, ax = pubfig.new_figure(width="double", aspect=0.56, journal="elsevier")
ax.set_xlim(0, 19); ax.set_ylim(0, 10.6); ax.axis("off")
FS = p.base_fontsize_pt
FT = p.min_fontsize_pt


def box(x, y, w, h, title, body="", fc="white", ls="-", lw=0.7, title_fs=FS):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.15",
                                mutation_scale=1, fc=fc, ec="black", lw=lw, ls=ls))
    ax.text(x + w / 2, y + h - 0.22, title, ha="center", va="top",
            fontsize=title_fs, fontweight="bold")
    if body:
        ax.text(x + w / 2, y + h - 0.62, body, ha="center", va="top",
                fontsize=FT, family="monospace", linespacing=1.35)


def arrow(x0, y0, x1, y1, ls="-"):
    ax.add_patch(FancyArrowPatch((x0, y0), (x1, y1), arrowstyle="-|>",
                                 mutation_scale=6, lw=0.7, color="black", ls=ls))


# --- inputs ---------------------------------------------------------------
ax.text(0.1, 10.45, "Inputs", fontsize=FS, fontweight="bold", va="top")
inputs = [("Soil maps + uncertainty", "soilgrids_input()"),
          ("Crop, yield, rainfall,\nmanagement", ""),
          ("Field / farm layout (sf)", ""),
          ("Sentinel-2 L2A or UAV\nmultispectral image", "")]
xs = [0.3, 4.95, 9.6, 14.25]
for x, (t, b) in zip(xs, inputs):
    box(x, 8.65, 4.45, 1.35, t, b, fc="0.93")

# --- agronomic core ---------------------------------------------------------
box(0.3, 2.9, 8.6, 5.25, "DPI 2026 nitrogen balance (Emilia-Romagna)", fc="white", lw=1.0)
box(0.6, 5.55, 4.05, 2.0, "N balance terms",
    "calc_crop_N_demand()  A\nsoil_fertility()      B\nleaching_loss()       C\n"
    "calc_N_immob..._loss() D\n... E, F, G", fc="0.97")
box(4.85, 5.55, 3.75, 2.0, "Field dose",
    "N_balance()\ncalculate_N_fertilization()\nP_balance()  K_balance()\nscheda_N()  scheda_PK()",
    fc="0.97")
box(0.6, 3.15, 4.05, 2.1, "Regulatory checks",
    "get_MAS()  check_MAS()\nplan_distribution()\n(organic + mineral,\n170 kg N/ha in ZVN)",
    fc="0.97")
box(4.85, 3.15, 3.75, 2.1, "Scale",
    "farm_balance()\nspatial_N_balance()\n(per plot / per pixel)\nMonte Carlo on soil error\n(user script, Section 2.6)", fc="0.97")
arrow(4.65, 6.55, 4.85, 6.55)

# --- remote sensing ---------------------------------------------------------
box(9.55, 5.15, 9.15, 3.0, "Remote-sensing diagnosis", fc="white", lw=1.0)
box(9.85, 5.4, 4.15, 2.15, "Canopy traits",
    "compute_vi()\n(NDVI, NDRE, GNDVI, ...)\nestimate_biophysical()\n(GPR: LAI, Cm, CNC, FVC)",
    fc="0.97")
box(14.25, 5.4, 4.15, 2.15, "Nitrogen status",
    "compute_NNI_from_S2()\ncompute_NNI()\ndiagnose_N_status()\n(deficient/optimal/excessive)",
    fc="0.97")
arrow(14.0, 6.47, 14.25, 6.47)

# --- variable rate and outputs ---------------------------------------------
box(9.55, 2.9, 9.15, 1.55, "Variable rate (field mean = balance dose)",
    "variable_rate_N()  build_strip_prescription()  optimize_VR_DPI()", fc="0.93", lw=1.0)
box(0.3, 0.6, 8.6, 1.55, "Reference tables (editable R data)",
    "uptake_table  mas.table  coef_time  crops.table\ncb.table  e.table  f.table  g.table  ...",
    fc="0.93", ls="--")
box(9.55, 0.25, 4.45, 1.9, "Export",
    "export_prescription()\nISOXML, Shapefile, GeoJSON,\nKML, GeoPackage, JD, Trimble", fc="white")
box(14.25, 0.25, 4.45, 1.9, "Interfaces",
    "R scripts and pipelines\nrun_app() (Shiny)\ntestthat unit tests", fc="white")

# --- flows --------------------------------------------------------------------
for x in xs[:2]:
    arrow(x + 2.2, 8.65, x + 2.2, 8.15)
# farm layout -> balance (elbow) and -> variable rate (down the gap)
ax.plot([xs[2] + 0.6, xs[2] + 0.6, 8.0], [8.65, 8.4, 8.4], color="black", lw=0.7, marker="", ls="-")
arrow(8.0, 8.4, 8.0, 8.15)
arrow(xs[3] + 2.2, 8.65, xs[3] + 2.2, 8.15)
arrow(8.9, 3.65, 9.55, 3.65)          # dose -> variable rate (mass balance)
arrow(14.1, 5.15, 14.1, 4.45)         # NNI -> variable rate
arrow(11.8, 2.9, 11.8, 2.15)          # variable rate -> export
arrow(4.6, 2.15, 4.6, 2.9, ls="--")   # tables -> core
ax.text(9.22, 3.85, "N*", ha="center", va="bottom", fontsize=FT, style="italic")

pubfig.save_figure(fig, "figures/fig1_architecture", journal="elsevier", kind="lineart")
