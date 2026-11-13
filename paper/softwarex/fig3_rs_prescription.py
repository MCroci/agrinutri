"""Fig. 3 - From a Sentinel-2 scene to a variable-rate map (bundled demo data).

Data from fig3_data.R: GPR leaf area index, Nitrogen Nutrition Index and the
24 m x 30 m NNI-driven prescription of CERZOO Field 3 (Sentinel-2 L2A,
13 August 2024, silage maize), all in EPSG:32632.
Run from paper/softwarex/:  python fig3_rs_prescription.py
"""
import geopandas as gpd
import matplotlib as mpl
import numpy as np
import rasterio

import pubfig

p = pubfig.set_style("elsevier", color=True)
fig, axes = pubfig.new_figure(width="double", ncols=3, aspect=0.5, journal="elsevier")
fig.subplots_adjust(wspace=0.15, left=0.0, right=0.94)
field = gpd.read_file("data/cerzoo_f3_field.geojson")
rx = gpd.read_file("data/cerzoo_f3_rx.geojson")


def raster(ax, path, cmap, norm, label):
    with rasterio.open(path) as src:
        a = src.read(1, masked=True)
        b = src.bounds
    im = ax.imshow(a, cmap=cmap, norm=norm, extent=(b.left, b.right, b.bottom, b.top),
                   interpolation="nearest")
    return im


minx, miny, maxx, maxy = field.total_bounds
pad = 20
for ax in axes:
    ax.set_xlim(minx - pad, maxx + pad); ax.set_ylim(miny - 60, maxy + pad)
    ax.set_aspect("equal"); ax.set_axis_off()

im = raster(axes[0], "data/cerzoo_f3_LAI.tif", mpl.colormaps[pubfig.SEQUENTIAL],
            mpl.colors.Normalize(0, 6), "LAI")
cb = fig.colorbar(im, ax=axes[0], fraction=0.05, pad=0.03)
cb.set_label("Leaf area index (m$^2$ m$^{-2}$)")

nni_norm = mpl.colors.TwoSlopeNorm(vmin=0.6, vcenter=1.0, vmax=1.4)
im = raster(axes[1], "data/cerzoo_f3_NNI.tif", mpl.colormaps[pubfig.DIVERGING].reversed(),
            nni_norm, "NNI")
cb = fig.colorbar(im, ax=axes[1], fraction=0.05, pad=0.03)
cb.set_label("Nitrogen Nutrition Index (-)")
for v in (0.9, 1.1):
    cb.ax.axhline(v, color="black", lw=0.6, ls="--")

dnorm = mpl.colors.Normalize(160, 240)
rx.plot(ax=axes[2], column="dose", cmap=mpl.colormaps[pubfig.SEQUENTIAL_ALT].reversed(),
        norm=dnorm, edgecolor="white", lw=0.3)
sm = mpl.cm.ScalarMappable(norm=dnorm, cmap=mpl.colormaps[pubfig.SEQUENTIAL_ALT].reversed())
cb = fig.colorbar(sm, ax=axes[2], fraction=0.05, pad=0.03)
cb.set_label("N dose (kg N ha$^{-1}$)")

for ax in axes:
    field.boundary.plot(ax=ax, color="black", lw=0.7)
    pubfig.add_scalebar(ax, 100, "100 m", loc="lower left")
pubfig.add_north_arrow(axes[0])
pubfig.label_panels(axes, journal="elsevier")
pubfig.save_figure(fig, "figures/fig3_rs_prescription", journal="elsevier", kind="combination")
