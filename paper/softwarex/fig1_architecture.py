"""Fig. 1 - agrinutri software architecture (modules, data and outputs).

Colour codes the modules: nutrient balance (blue), remote sensing (green), variable rate
(purple), data and outputs (grey). Run from paper/softwarex/:  python fig1_architecture.py
"""
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

import pubfig

p = pubfig.set_style("elsevier")
fig, ax = pubfig.new_figure(width="double", aspect=0.56, journal="elsevier")
ax.set_xlim(0, 19); ax.set_ylim(0, 10.6); ax.axis("off")
FS = p.base_fontsize_pt
FT = p.min_fontsize_pt

# module colours: edge (Okabe-Ito) and light fill
BAL = ("#0072B2", "#E3EEF7")
RS = ("#009E73", "#E0F2EB")
VR = ("#6A51A3", "#ECE8F4")
GREY = ("0.25", "0.94")


def box(x, y, w, h, title, body="", col=GREY, fill=None, ls="-", lw=0.7, title_fs=FS):
    ec, fc = col
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.15",
                                mutation_scale=1, fc=fc if fill is None else fill, ec=ec,
                                lw=lw, ls=ls))
    ax.text(x + w / 2, y + h - 0.22, title, ha="center", va="top",
            fontsize=title_fs, fontweight="bold", color=ec if ec != "0.25" else "black")
    if body:
        ax.text(x + w / 2, y + h - 0.62, body, ha="center", va="top",
                fontsize=FT, family="monospace", linespacing=1.35)


def arrow(x0, y0, x1, y1, ls="-", lw=0.7, col="black", ms=6):
    ax.add_patch(FancyArrowPatch((x0, y0), (x1, y1), arrowstyle="-|>",
                                 mutation_scale=ms, lw=lw, color=col, ls=ls))


# --- inputs ---------------------------------------------------------------
ax.text(0.1, 10.45, "Inputs", fontsize=FS, fontweight="bold", va="top")
inputs = [("Soil analyses or soil maps", "soilgrids_input()"),
          ("Crop, yield, rainfall,\nmanagement", ""),
          ("Field or farm layout (sf)", ""),
          ("Sentinel-2 L2A or UAV\nmultispectral image", "")]
xs = [0.3, 4.95, 9.6, 14.25]
for x, (t, b) in zip(xs, inputs):
    box(x, 8.65, 4.45, 1.35, t, b)

# --- nutrient balance -------------------------------------------------------
box(0.3, 2.9, 8.6, 5.25, "Nutrient balance (N, P, K)", col=BAL, fill="white", lw=1.2)
ax.text(4.6, 7.42, "N = A − B + C + D − E − F − G", ha="center", va="top",
        fontsize=FS + 1.5, fontweight="bold", color=BAL[0])
ax.text(4.6, 6.98, "A crop demand, B soil supply, C leaching, D immobilisation,\n"
        "E previous crop, F past organic inputs, G deposition and fixation",
        ha="center", va="top", fontsize=FT, linespacing=1.3)
box(0.6, 4.55, 4.05, 1.65, "Balance terms",
    "calc_crop_N_demand()\nsoil_fertility()\nleaching_loss()  ...", col=BAL)
box(4.85, 4.55, 3.75, 1.65, "Doses",
    "N_balance()  P_balance()\nK_balance()\ndose_standard_N() / _PK()", col=BAL)
box(0.6, 3.1, 4.05, 1.3, "Limits and plan",
    "check_MAS()\nplan_distribution()", col=BAL)
box(4.85, 3.1, 3.75, 1.3, "Scale: plot, year, pixel",
    "farm_balance()\nspatial_N_balance()", col=BAL)

# --- remote sensing ---------------------------------------------------------
box(9.55, 5.15, 9.15, 3.0, "Remote-sensing diagnosis", col=RS, fill="white", lw=1.2)
box(9.85, 5.4, 4.15, 2.15, "Canopy traits",
    "compute_vi()\n(NDVI, NDRE, GNDVI, ...)\nestimate_biophysical()\n(GPR: LAI, Cm, CNC, FVC)",
    col=RS)
box(14.25, 5.4, 4.15, 2.15, "Nitrogen status",
    "compute_NNI_from_S2()\ndiagnose_N_status()\n(deficient / optimal /\nluxury consumption)",
    col=RS)
arrow(14.0, 6.47, 14.25, 6.47, col=RS[0])

# --- variable rate and outputs ---------------------------------------------
box(9.55, 2.9, 9.15, 1.55, "Variable rate: field mean kept at N*",
    "variable_rate_N()    build_strip_prescription()", col=VR, lw=1.2)
box(0.3, 0.6, 8.6, 1.55, "Coefficient tables (editable R data)",
    "uptake_table  mas.table  coef_time  cb.table  e.table  ...", ls="--")
ax.text(4.6, 1.0, "default set: Emilia-Romagna guidelines; replace a table to change it",
        ha="center", va="top", fontsize=FT, style="italic")
box(9.55, 0.25, 4.45, 1.9, "Export",
    "export_prescription()\nISOXML, Shapefile, GeoJSON,\nKML, GeoPackage, JD, Trimble")
box(14.25, 0.25, 4.45, 1.9, "Interfaces",
    "R scripts and pipelines\nrun_app() (Shiny)\ntestthat unit tests")

# --- flows --------------------------------------------------------------------
for x in xs[:2]:
    arrow(x + 2.2, 8.65, x + 2.2, 8.15)
ax.plot([xs[2] + 0.6, xs[2] + 0.6, 8.0], [8.65, 8.4, 8.4], color="black", lw=0.7, ls="-", marker="")
arrow(8.0, 8.4, 8.0, 8.15)
arrow(xs[3] + 2.2, 8.65, xs[3] + 2.2, 8.15)
arrow(8.9, 3.65, 9.55, 3.65, lw=1.6, col=VR[0], ms=9)     # balance dose -> variable rate
arrow(14.1, 5.15, 14.1, 4.45, lw=1.2, col=RS[0], ms=8)    # NNI -> variable rate
arrow(11.8, 2.9, 11.8, 2.15, lw=1.2, col=VR[0], ms=8)     # variable rate -> export
arrow(4.6, 2.15, 4.6, 2.9, ls="--")                       # tables -> balance
ax.text(9.22, 3.85, "N*", ha="center", va="bottom", fontsize=FS, style="italic",
        fontweight="bold", color=VR[0])

pubfig.save_figure(fig, "figures/fig1_architecture", journal="elsevier", kind="lineart")
