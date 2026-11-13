"""Fig. 2 - NFert vs Fert_Office v1.26 on 400 random field scenarios.

Data: data/validation_fertoffice.csv, written from the package test fixture
tests/testthat/fixtures/fertoffice_v1.26_scenarios.csv (Fert_Office values
recorded through Excel by data-raw/fertoffice_validation.py) and the NFert
results of v1.0.0 and of the previous release v0.14.2.
Run from paper/softwarex/:  python fig2_validation.py
"""
import csv

import numpy as np

import pubfig

rows = list(csv.DictReader(open("data/validation_fertoffice.csv", encoding="utf-8")))
col = lambda k: np.array([float(r[k]) for r in rows])

p = pubfig.set_style("elsevier")
fig, axes = pubfig.new_figure(width="double", ncols=3, aspect=0.36, journal="elsevier")

panels = [("N", "N (kg N ha$^{-1}$)"), ("P", "P$_2$O$_5$ (kg ha$^{-1}$)"),
          ("K", "K$_2$O (kg ha$^{-1}$)")]
for ax, (k, lab) in zip(axes, panels):
    fo, nf, old = col(f"fo_{k}"), col(f"nf_{k}"), col(f"old_{k}")
    hi = max(fo.max(), nf.max(), old.max()) * 1.04
    ax.plot([0, hi], [0, hi], color="0.6", lw=0.6, zorder=1)
    ax.scatter(fo, old, s=7, marker="o", facecolors="none", edgecolors="0.55",
               linewidths=0.5, label="v0.14.2", zorder=2)
    ax.scatter(fo, nf, s=5, marker="s", color="black", lw=0,
               label="v1.0.0", zorder=3)
    ax.set_xlim(0, hi); ax.set_ylim(0, hi); ax.set_aspect("equal")
    ax.set_xlabel(f"Fert_Office v1.26 {lab}")
    ax.set_ylabel(f"NFert {lab}")
    d_new = np.abs(nf - fo); d_old = np.abs(old - fo)
    ax.text(0.04, 0.96,
            f"v1.0.0: |d| < $10^{{-6}}$ in {np.sum(d_new < 1e-6)}/{len(fo)}\n"
            f"v0.14.2: within 0.5 kg in {np.sum(d_old < 0.5)}/{len(fo)}",
            transform=ax.transAxes, va="top", ha="left", fontsize=p.min_fontsize_pt)
axes[0].legend(loc="lower right", frameon=False, handletextpad=0.2)
pubfig.label_panels(axes, journal="elsevier")
pubfig.save_figure(fig, "figures/fig2_validation", journal="elsevier", kind="lineart")
