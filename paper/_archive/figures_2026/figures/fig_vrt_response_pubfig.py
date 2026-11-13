#!/usr/bin/env python3
"""Response functions of the two NFert variable-rate algorithms (Elsevier spec).

(a) Calibration-curve method: a two-point linear ramp maps the vegetation index
    to the N rate, clipped to [min_dose, max_dose]; shown in both the inverse
    form (higher VI -> less N) and the direct form.
(b) Holland & Schepers method: the N rate decreases with the sufficiency index
    SI = NDVI / NDVI_ref toward the N-rich reference strip.

Schematic, driven by the CERZOO case-study settings (vi_low 0.35, vi_high 0.80,
dose envelope 165-235 kg N/ha). Run: python fig_vrt_response_pubfig.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import pubfig

HERE = os.path.dirname(os.path.abspath(__file__))
vi_low, vi_high = 0.35, 0.80
dmin, dmax = 165.0, 235.0

pubfig.set_style("elsevier")
fig, axes = pubfig.new_figure(width="double", nrows=1, ncols=2, height_mm=70,
                              journal="elsevier")
ax1, ax2 = axes.ravel()

# ---- (a) calibration ramps ----
vi = np.linspace(0.15, 0.95, 400)
def ramp(vi, dlo_at_low, dlo_at_high):
    t = np.clip((vi - vi_low) / (vi_high - vi_low), 0, 1)
    return dlo_at_low + t * (dlo_at_high - dlo_at_low)
inv = ramp(vi, dmax, dmin)   # inverse: high VI -> low dose
dir_ = ramp(vi, dmin, dmax)  # direct:  high VI -> high dose
ax1.plot(vi, inv, color="black", linewidth=1.2, marker="", label="inverse (VI up, dose down)")
ax1.plot(vi, dir_, color="0.45", linewidth=1.2, linestyle="--", marker="", label="direct (VI up, dose up)")
for v in (vi_low, vi_high):
    ax1.axvline(v, color="0.7", linewidth=0.5, linestyle=":")
ax1.set_xlabel("Vegetation index (NDVI)")
ax1.set_ylabel(r"N rate (kg N ha$^{-1}$)")
ax1.set_ylim(dmin - 8, dmax + 8)
ax1.legend(loc="center right", handlelength=1.6)

# ---- (b) Holland & Schepers response ----
q95, q05, base = 0.85, 0.35, 200.0
delta = 1.0 - q05 / q95
vi2 = np.linspace(q05, q95, 400)
SI = np.clip(vi2 / q95, None, 1.0)
dose = base * np.sqrt(np.clip((1.0 - SI) / delta, 0, None))
ax2.plot(vi2, dose, color="black", linewidth=1.2, marker="")
ax2.axvline(q95, color="0.7", linewidth=0.5, linestyle=":")
ax2.annotate(r"NDVI$_{\mathrm{ref}}$ (SI = 1)", xy=(q95, 8), xytext=(q95 - 0.30, 70),
             fontsize=6, arrowprops=dict(arrowstyle="->", lw=0.5, color="0.4"))
ax2.set_xlabel("Vegetation index (NDVI)")
ax2.set_ylabel(r"N rate before rescaling (kg N ha$^{-1}$)")
ax2.set_ylim(-5, base + 10)

pubfig.label_panels(axes, journal="elsevier")
pubfig.save_figure(fig, "cerzoo_vrt_response", journal="elsevier",
                   kind="lineart", outdir=HERE)
print("done response figure")
