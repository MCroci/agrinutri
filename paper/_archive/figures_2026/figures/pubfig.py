"""
pubfig.py - Publication-ready scientific figures with matplotlib.

A single, self-contained helper module that makes every figure conform to
journal specifications from the start: correct column width in millimetres,
legible final-size fonts, colorblind-safe and grayscale-robust encoding,
embedded (non-outlined) fonts in vector output, and the right resolution
measured at final print size.

Design principles
-----------------
1. Reproducible and author-controlled. Everything is plain matplotlib code
   driven by data. No AI-generated raster imagery (this matters for Elsevier's
   figure policy). Keep this file next to the figure script so the figure can
   always be regenerated.
2. Final-size first. The figure is built at its real publication width in mm
   and exported at the DPI the journal requires *at that size*. This avoids the
   classic rejection where a figure made at 3x and downsampled is effectively
   100 DPI at print.
3. Robust by default. Series are distinguishable in black and white (linestyle
   + marker, not colour alone) and colour maps are perceptually uniform.

Convention used here (override freely):
    diagrams / schematics ........ grayscale
    data plots (line/scatter/bar)  grayscale-safe by default; set color=True
    raster / satellite maps ...... colour (perceptually-uniform colormaps)

Typical use
-----------
    import pubfig
    pubfig.set_style("elsevier")                  # set rcParams once
    fig, axes = pubfig.new_figure(width="single", aspect=0.75, ncols=2)
    # ... plot ...
    pubfig.label_panels(axes)                      # (a), (b), ...
    pubfig.save_figure(fig, "fig2_yield", journal="elsevier", kind="lineart")

All numbers come from the journals' own author instructions; see
references/journal_specs.md for sources.
"""

from __future__ import annotations

import warnings
from dataclasses import dataclass, field
from typing import Iterable, Sequence

import matplotlib as mpl
import matplotlib.pyplot as plt
from cycler import cycler

MM_PER_INCH = 25.4


# --------------------------------------------------------------------------- #
# Journal profiles
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class JournalProfile:
    """Specifications for one publisher / journal family.

    widths_mm        : named column widths in millimetres
    max_height_mm     : maximum figure height (leave room for the caption)
    base_fontsize_pt  : target body text size at final print size
    min_fontsize_pt   : smallest allowed text (ticks, subscripts)
    panel_label_pt    : size of the (a)/(b) panel letters
    panel_parens      : True -> "(a)"  ; False -> "a"
    panel_case        : "lower" or "upper"
    dpi_halftone      : raster photos / continuous-tone (e.g. satellite RGB)
    dpi_combination   : line art + halftone in one figure
    dpi_lineart       : pure line art exported as raster (vector is preferred)
    vector_formats    : preferred vector output(s)
    raster_formats    : preferred raster output(s)
    notes             : free-text reminders
    """

    name: str
    widths_mm: dict[str, float]
    max_height_mm: float
    base_fontsize_pt: float
    min_fontsize_pt: float
    panel_label_pt: float
    panel_parens: bool
    panel_case: str
    dpi_halftone: int
    dpi_combination: int
    dpi_lineart: int
    vector_formats: tuple[str, ...]
    raster_formats: tuple[str, ...]
    notes: str = ""


JOURNAL_PROFILES: dict[str, JournalProfile] = {
    # Elsevier: widths and resolutions are the publisher defaults, measured at
    # final size. 7 pt body text (>=6 pt sub/superscript). Vector preferred.
    "elsevier": JournalProfile(
        name="Elsevier",
        widths_mm={"min": 30.0, "single": 90.0, "1.5": 140.0, "double": 190.0},
        max_height_mm=240.0,
        base_fontsize_pt=7.0,
        min_fontsize_pt=6.0,
        panel_label_pt=8.0,
        panel_parens=True,
        panel_case="lower",
        dpi_halftone=300,
        dpi_combination=500,
        dpi_lineart=1000,
        vector_formats=("pdf", "eps"),
        raster_formats=("tiff", "png"),
        notes="Use 3-4 tones max; bold solid colours reproduce well; CMYK for "
        "print. Recommended fonts: Arial, Helvetica, Times, Courier, Symbol.",
    ),
    # Nature: 89 / 183 mm. Text 5-7 pt, panel letters 8 pt bold lowercase.
    # Never outline/rasterize text; embed TrueType fonts.
    "nature": JournalProfile(
        name="Nature",
        widths_mm={"single": 89.0, "1.5": 120.0, "double": 183.0},
        max_height_mm=170.0,
        base_fontsize_pt=7.0,
        min_fontsize_pt=5.0,
        panel_label_pt=8.0,
        panel_parens=False,
        panel_case="lower",
        dpi_halftone=300,
        dpi_combination=600,
        dpi_lineart=600,
        vector_formats=("pdf", "eps"),
        raster_formats=("tiff", "png"),
        notes="Sans-serif only (Helvetica/Arial). RGB online -> CMYK print. "
        "Colorblind-safe (blue/orange or viridis); never red/green; do not "
        "rely on colour alone. Do not outline or rasterize text.",
    ),
    # MDPI (Remote Sensing, Agronomy, Sensors, ...): >=600 dpi recommended,
    # colour free, flexible width (production sets final placement).
    "mdpi": JournalProfile(
        name="MDPI",
        widths_mm={"single": 85.0, "double": 170.0},
        max_height_mm=230.0,
        base_fontsize_pt=8.0,
        min_fontsize_pt=7.0,
        panel_label_pt=9.0,
        panel_parens=True,
        panel_case="lower",
        dpi_halftone=600,
        dpi_combination=600,
        dpi_lineart=600,
        vector_formats=("pdf", "eps"),
        raster_formats=("tiff", "png"),
        notes="Min 600 dpi recommended; full colour at no cost (RGB 8-bit). "
        "TIFF/PNG/EPS accepted; flatten (no editable parts) for final raster.",
    ),
    # Conservative defaults that pass almost anywhere if the target is unknown.
    "generic": JournalProfile(
        name="Generic print",
        widths_mm={"single": 85.0, "1.5": 130.0, "double": 174.0},
        max_height_mm=225.0,
        base_fontsize_pt=7.0,
        min_fontsize_pt=6.0,
        panel_label_pt=8.0,
        panel_parens=True,
        panel_case="lower",
        dpi_halftone=300,
        dpi_combination=600,
        dpi_lineart=1200,
        vector_formats=("pdf",),
        raster_formats=("tiff", "png"),
        notes="Safe conservative defaults. Always check the journal's own "
        "author guide, which overrides these.",
    ),
}


def get_profile(journal: str) -> JournalProfile:
    key = journal.strip().lower()
    if key not in JOURNAL_PROFILES:
        raise KeyError(
            f"Unknown journal '{journal}'. Available: "
            f"{', '.join(sorted(JOURNAL_PROFILES))}. "
            "Use 'generic' or add a profile to JOURNAL_PROFILES."
        )
    return JOURNAL_PROFILES[key]


# --------------------------------------------------------------------------- #
# Palettes
# --------------------------------------------------------------------------- #
# Okabe-Ito colourblind-safe qualitative palette (8 colours). Order chosen to
# keep adjacent series distinct; pure yellow is last because it is weak on white.
OKABE_ITO: list[str] = [
    "#000000",  # black
    "#E69F00",  # orange
    "#56B4E9",  # sky blue
    "#009E73",  # bluish green
    "#0072B2",  # blue
    "#D55E00",  # vermillion
    "#CC79A7",  # reddish purple
    "#F0E442",  # yellow
]

# Recommended colormaps (perceptually uniform / colourblind friendly).
SEQUENTIAL = "viridis"      # e.g. NDVI, biomass, single increasing quantity
SEQUENTIAL_ALT = "cividis"  # optimised for colour-vision deficiency
DIVERGING = "RdBu_r"        # anomalies / differences around a midpoint
DIVERGING_ALT = "BrBG"      # good for soil / moisture style maps

# Grayscale-safe cycle: each series differs in shade AND linestyle AND marker,
# so lines stay readable when printed in black and white.
_GRAY_COLORS = ["#000000", "#000000", "#595959", "#595959", "#a6a6a6", "#000000"]
_GRAY_LINESTYLES = ["-", "--", "-.", ":", "-", (0, (3, 1, 1, 1))]
_GRAY_MARKERS = ["o", "s", "^", "D", "v", "x"]


def grayscale_cycle(n: int | None = None):
    """Cycler combining gray shade + linestyle + marker for B/W-safe plots."""
    k = len(_GRAY_COLORS) if n is None else n
    reps = (k + len(_GRAY_COLORS) - 1) // len(_GRAY_COLORS)
    colors = (_GRAY_COLORS * reps)[:k]
    lss = (_GRAY_LINESTYLES * reps)[:k]
    mks = (_GRAY_MARKERS * reps)[:k]
    return cycler(color=colors) + cycler(linestyle=lss) + cycler(marker=mks)


def color_cycle(n: int | None = None, with_markers: bool = True):
    """Okabe-Ito colour cycler, optionally pairing distinct markers."""
    k = len(OKABE_ITO) if n is None else n
    reps = (k + len(OKABE_ITO) - 1) // len(OKABE_ITO)
    colors = (OKABE_ITO * reps)[:k]
    cyc = cycler(color=colors)
    if with_markers:
        base_markers = ["o", "s", "^", "D", "v", "P", "X", "*"]
        mks = (base_markers * reps)[:k]
        cyc = cyc + cycler(marker=mks)
    return cyc


# --------------------------------------------------------------------------- #
# Style
# --------------------------------------------------------------------------- #
def set_style(
    journal: str = "elsevier",
    *,
    base_fontsize: float | None = None,
    color: bool = False,
    grayscale_safe: bool = True,
    serif: bool = False,
) -> JournalProfile:
    """Configure matplotlib rcParams for the target journal.

    Call once before building figures. Returns the resolved profile so you can
    read widths etc. from it.

    color           : False -> grayscale-safe cycle (default, matches the
                      diagram convention); True -> Okabe-Ito colour cycle.
    grayscale_safe  : when color=True, still pair markers so series remain
                      distinguishable if the figure is printed in B/W.
    serif           : almost always leave False; high-impact journals require
                      sans-serif. (Times is only for journals that ask for it.)
    """
    p = get_profile(journal)
    fs = float(base_fontsize) if base_fontsize is not None else p.base_fontsize_pt
    tick_fs = max(p.min_fontsize_pt, fs - 1)

    # Sans-serif with graceful fallback. Arial/Helvetica are the journal
    # requirement; Liberation Sans / Nimbus / DejaVu are metric-compatible
    # stand-ins when those exact fonts are not installed on this machine.
    sans = ["Arial", "Helvetica", "Liberation Sans", "Nimbus Sans", "DejaVu Sans"]
    serif_list = ["Times New Roman", "Times", "Nimbus Roman", "DejaVu Serif"]

    rc = {
        "figure.dpi": 150,                 # on-screen; export DPI set on save
        "savefig.dpi": p.dpi_halftone,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.02,
        "savefig.facecolor": "white",
        "figure.facecolor": "white",
        "axes.facecolor": "white",

        "font.family": "serif" if serif else "sans-serif",
        "font.serif": serif_list,
        "font.sans-serif": sans,
        "font.size": fs,
        "axes.titlesize": fs,
        "axes.labelsize": fs,
        "xtick.labelsize": tick_fs,
        "ytick.labelsize": tick_fs,
        "legend.fontsize": tick_fs,
        "legend.title_fontsize": fs,
        "figure.titlesize": fs + 1,

        # Embed TrueType so text stays editable (not outlined) in PDF/EPS.
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "svg.fonttype": "none",
        "pdf.compression": 6,

        # Clean, thin, print-friendly geometry.
        "axes.linewidth": 0.6,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "lines.linewidth": 1.0,
        "lines.markersize": 3.5,
        "lines.markeredgewidth": 0.6,
        "patch.linewidth": 0.6,
        "grid.linewidth": 0.4,
        "grid.alpha": 0.4,
        "xtick.major.width": 0.6,
        "ytick.major.width": 0.6,
        "xtick.minor.width": 0.4,
        "ytick.minor.width": 0.4,
        "xtick.major.size": 2.5,
        "ytick.major.size": 2.5,
        "xtick.direction": "out",
        "ytick.direction": "out",
        "legend.frameon": False,
        "legend.handlelength": 1.8,
        "axes.axisbelow": True,

        # Make the minus sign a hyphen so it embeds in every font.
        "axes.unicode_minus": False,
    }
    mpl.rcParams.update(rc)

    if color:
        mpl.rcParams["axes.prop_cycle"] = color_cycle(with_markers=grayscale_safe)
    else:
        mpl.rcParams["axes.prop_cycle"] = grayscale_cycle()

    return p


# --------------------------------------------------------------------------- #
# Sizing
# --------------------------------------------------------------------------- #
def figure_size(
    width: str | float = "single",
    aspect: float = 0.75,
    *,
    height_mm: float | None = None,
    journal: str = "elsevier",
) -> tuple[float, float]:
    """Return (width_in, height_in) for a figure at its real publication size.

    width    : a named column ('min'/'single'/'1.5'/'double') or a width in mm.
    aspect   : height / width ratio (ignored if height_mm is given).
    height_mm: explicit height in mm; clamped to the journal max height.
    """
    p = get_profile(journal)
    if isinstance(width, str):
        if width not in p.widths_mm:
            raise KeyError(
                f"'{width}' not defined for {p.name}. "
                f"Available widths: {', '.join(p.widths_mm)}."
            )
        w_mm = p.widths_mm[width]
    else:
        w_mm = float(width)

    h_mm = height_mm if height_mm is not None else w_mm * aspect
    if h_mm > p.max_height_mm:
        warnings.warn(
            f"Height {h_mm:.0f} mm exceeds {p.name} max {p.max_height_mm:.0f} mm; "
            "clamping. Consider a multi-panel layout or a wider column.",
            stacklevel=2,
        )
        h_mm = p.max_height_mm
    return w_mm / MM_PER_INCH, h_mm / MM_PER_INCH


def new_figure(
    width: str | float = "single",
    aspect: float = 0.75,
    *,
    nrows: int = 1,
    ncols: int = 1,
    height_mm: float | None = None,
    journal: str = "elsevier",
    constrained: bool = True,
    **subplots_kw,
):
    """Create a correctly sized figure and axes in one call.

    Returns (fig, ax) for a single panel, or (fig, axes_array) otherwise.
    """
    size = figure_size(width, aspect, height_mm=height_mm, journal=journal)
    layout = "constrained" if constrained else None
    fig, axes = plt.subplots(
        nrows, ncols, figsize=size, layout=layout, **subplots_kw
    )
    return fig, axes


# --------------------------------------------------------------------------- #
# Panel labels (a, b, c ...)
# --------------------------------------------------------------------------- #
def label_panels(
    axes,
    labels: Sequence[str] | None = None,
    *,
    journal: str = "elsevier",
    inside: bool = False,
    pad_pt: float = 2.0,
    fontsize: float | None = None,
    weight: str = "bold",
) -> None:
    """Add (a), (b), ... labels to a sequence/array/grid of axes.

    By default the letter sits just *outside* the top-left corner of each axes
    (the common journal convention), which never collides with an in-plot
    legend or data. Set inside=True to place it inside the top-left corner
    instead. Style (parentheses, case, size) defaults to the journal
    convention; keep panel letters consistent across all figures in a paper.
    """
    p = get_profile(journal)
    fs = fontsize if fontsize is not None else p.panel_label_pt

    # Flatten any nested axes container in reading order.
    flat = []
    try:
        import numpy as _np

        if isinstance(axes, _np.ndarray):
            flat = list(axes.ravel())
        else:
            raise TypeError
    except (ImportError, TypeError):
        if hasattr(axes, "__iter__"):
            for a in axes:
                flat.extend(list(a) if hasattr(a, "__iter__") else [a])
        else:
            flat = [axes]

    if labels is None:
        letters = [chr(ord("a") + i) for i in range(len(flat))]
        if p.panel_case == "upper":
            letters = [s.upper() for s in letters]
        labels = [f"({s})" if p.panel_parens else s for s in letters]

    for ax, lab in zip(flat, labels):
        if inside:
            ax.text(
                0.025, 0.96, lab, transform=ax.transAxes,
                fontsize=fs, fontweight=weight, va="top", ha="left",
            )
        else:
            ax.annotate(
                lab, xy=(0.0, 1.0), xycoords="axes fraction",
                xytext=(0.0, pad_pt), textcoords="offset points",
                fontsize=fs, fontweight=weight, va="bottom", ha="left",
            )


# --------------------------------------------------------------------------- #
# Map helpers (for raster / satellite figures)
# --------------------------------------------------------------------------- #
def add_scalebar(
    ax,
    length,
    label,
    *,
    loc: str = "lower right",
    color: str = "black",
    pad: float = 0.4,
    size_vertical: float | None = None,
    fontsize: float | None = None,
):
    """Add a scale bar in data units (e.g. metres for a projected raster).

    length : bar length in the axis' data units.
    label  : text under the bar, e.g. '500 m' or '1 km'.
    """
    from mpl_toolkits.axes_grid1.anchored_artists import AnchoredSizeBar

    fp = {"size": fontsize} if fontsize is not None else None
    if size_vertical is None:
        y0, y1 = ax.get_ylim()
        size_vertical = abs(y1 - y0) * 0.008
    bar = AnchoredSizeBar(
        ax.transData, length, label, loc,
        pad=pad, color=color, frameon=False,
        size_vertical=size_vertical, fontproperties=_fontprops(fp),
    )
    ax.add_artist(bar)
    return bar


def _fontprops(d):
    if not d:
        return None
    from matplotlib.font_manager import FontProperties

    return FontProperties(**{k: v for k, v in d.items() if v is not None})


def add_north_arrow(
    ax,
    *,
    xy: tuple[float, float] = (0.95, 0.95),
    length: float = 0.08,
    color: str = "black",
    fontsize: float | None = None,
):
    """Add a simple north arrow in axes-fraction coordinates (top-right)."""
    x, y = xy
    ax.annotate(
        "N",
        xy=(x, y), xytext=(x, y - length),
        xycoords="axes fraction", textcoords="axes fraction",
        ha="center", va="center", fontsize=fontsize, fontweight="bold",
        color=color,
        arrowprops=dict(arrowstyle="-|>", color=color, lw=1.0),
    )


# --------------------------------------------------------------------------- #
# Export
# --------------------------------------------------------------------------- #
_VECTOR = {"pdf", "eps", "svg"}
_RASTER = {"tiff", "tif", "png", "jpg", "jpeg"}


def _dpi_for_kind(profile: JournalProfile, kind: str) -> int:
    kind = kind.lower()
    if kind in {"halftone", "raster", "map", "photo", "satellite"}:
        return profile.dpi_halftone
    if kind in {"combination", "combo", "mixed"}:
        return profile.dpi_combination
    if kind in {"lineart", "line", "diagram", "plot", "schematic", "chart"}:
        return profile.dpi_lineart
    raise ValueError(
        f"Unknown kind '{kind}'. Use one of: lineart, halftone, combination."
    )


def save_figure(
    fig,
    stem: str,
    *,
    journal: str = "elsevier",
    kind: str = "lineart",
    formats: Iterable[str] | None = None,
    dpi: int | None = None,
    outdir: str = ".",
    preview_png: bool = True,
    verbose: bool = True,
) -> list[str]:
    """Export a figure to publication formats with correct resolution.

    kind     : 'lineart' (plots, diagrams), 'halftone' (photos, satellite RGB),
               or 'combination'. Sets the export DPI for raster outputs.
    formats  : output extensions. If None, a sensible default is chosen:
                 line art / diagrams -> vector PDF (text stays editable)
                 halftone / maps     -> high-res TIFF
               A PNG preview is added for quick on-screen checking.
    dpi      : override the resolution (otherwise from the journal + kind).

    Resolution is correct *by construction*: the figure is at final size and
    raster output is rasterized at the journal DPI, so the effective resolution
    at print size equals the requested DPI (no hidden downsampling).
    """
    import os

    p = get_profile(journal)
    res = dpi if dpi is not None else _dpi_for_kind(p, kind)

    if formats is None:
        if kind.lower() in {"halftone", "raster", "map", "photo", "satellite"}:
            formats = [p.raster_formats[0]]
        else:
            formats = [p.vector_formats[0]]
    formats = [f.lower().lstrip(".") for f in formats]
    if preview_png and "png" not in formats:
        formats = list(formats) + ["png"]

    os.makedirs(outdir, exist_ok=True)
    written: list[str] = []
    for fmt in formats:
        path = os.path.join(outdir, f"{stem}.{fmt}")
        save_kw: dict = {}
        if fmt in _RASTER:
            save_kw["dpi"] = res if fmt != "png" else min(res, 300)
            if fmt in {"tiff", "tif"}:
                # LZW keeps TIFFs lossless but much smaller.
                save_kw["pil_kwargs"] = {"compression": "tiff_lzw"}
        fig.savefig(path, **save_kw)
        written.append(path)

    if verbose:
        w_in, h_in = fig.get_size_inches()
        print(
            f"[{p.name}] {stem}: {w_in * MM_PER_INCH:.0f} x "
            f"{h_in * MM_PER_INCH:.0f} mm, kind={kind}, {res} dpi raster"
        )
        for path in written:
            print(f"    -> {path}")
    return written


# --------------------------------------------------------------------------- #
# Quick self-check
# --------------------------------------------------------------------------- #
def check_style(journal: str = "elsevier") -> dict:
    """Return a small report comparing current rcParams to the journal limits.

    Useful as a sanity gate before exporting: confirms the smallest font is not
    below the journal minimum.
    """
    p = get_profile(journal)
    sizes = {
        "font.size": mpl.rcParams["font.size"],
        "xtick.labelsize": mpl.rcParams["xtick.labelsize"],
        "ytick.labelsize": mpl.rcParams["ytick.labelsize"],
        "legend.fontsize": mpl.rcParams["legend.fontsize"],
    }
    numeric = [v for v in sizes.values() if isinstance(v, (int, float))]
    smallest = min(numeric) if numeric else None
    ok = smallest is None or smallest >= p.min_fontsize_pt
    report = {
        "journal": p.name,
        "min_allowed_pt": p.min_fontsize_pt,
        "smallest_in_use_pt": smallest,
        "fonts_embedded_as_truetype": mpl.rcParams["pdf.fonttype"] == 42,
        "passes_min_fontsize": ok,
        "sizes": sizes,
    }
    if not ok:
        warnings.warn(
            f"Smallest font {smallest} pt is below {p.name} minimum "
            f"{p.min_fontsize_pt} pt.",
            stacklevel=2,
        )
    return report


if __name__ == "__main__":
    # Minimal smoke test that the module imports and styles cleanly.
    set_style("elsevier")
    print("Loaded profiles:", ", ".join(sorted(JOURNAL_PROFILES)))
    print("Elsevier single-column size (in):", figure_size("single"))
    print("Style check:", check_style("elsevier")["passes_min_fontsize"])
