#!/usr/bin/env python3
"""Critical-nitrogen dilution curves and NNI diagnostic zones (Elsevier spec).

Species-specific critical-N curve Nc = a * W^-b (Lemaire and Gastal framework)
for wheat (a=5.35, b=0.44) and maize (a=3.40, b=0.37), with the optimal NNI
band (0.90 to 1.10 * Nc) shaded for maize, the CERZOO case-study crop.
Run: python fig_critical_curves_pubfig.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import pubfig

HERE = os.path.dirname(os.path.abspath(__file__))
W = np.linspace(1.0, 12.0, 400)
nc = {"wheat": 5.35 * W ** (-0.44), "maize": 3.40 * W ** (-0.37)}

pubfig.set_style("elsevier")
fig, ax = pubfig.new_figure(width="single", aspect=0.85, journal="elsevier")

# optimal NNI band for maize (0.90 .. 1.10 * Nc)
ax.fill_between(W, 0.90 * nc["maize"], 1.10 * nc["maize"],
                color="#DCEFD8", alpha=0.9, linewidth=0, zorder=0,
                label="Optimal band (maize)")
ax.plot(W, nc["maize"], color="black", linewidth=1.1, label="Maize  Nc = 3.40 W$^{-0.37}$")
ax.plot(W, nc["wheat"], color="0.45", linewidth=1.1, linestyle="--",
        label="Wheat  Nc = 5.35 W$^{-0.44}$")
ax.plot(W, 0.90 * nc["maize"], color="0.5", linewidth=0.5, linestyle=":")
ax.plot(W, 1.10 * nc["maize"], color="0.5", linewidth=0.5, linestyle=":")

# annotate the three NNI zones along the maize curve
ax.text(10.5, 1.10 * nc["maize"][-1] + 0.20, "excess\n(NNI > 1.10)", fontsize=5.5,
        ha="center", va="bottom", color="0.3")
ax.text(10.5, 0.90 * nc["maize"][-1] - 0.18, "deficient\n(NNI < 0.90)", fontsize=5.5,
        ha="center", va="top", color="0.3")

ax.set_xlabel(r"Aboveground biomass W (t DM ha$^{-1}$)")
ax.set_ylabel("Critical N concentration (% DM)")
ax.set_xlim(1, 12)
ax.set_ylim(0, 5.5)
ax.legend(loc="upper right", handlelength=1.8)
pubfig.save_figure(fig, "critical_n_curves", journal="elsevier",
                   kind="lineart", outdir=HERE)
print("done critical curves")
