# Compute a vegetation index from a multi-band raster

Generic engine that computes the main vegetation indices used in
nitrogen diagnosis from a multi-band
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).
agrinutri supports six indices with configurable band mapping, so the
function works with Sentinel-2 L2A, UAV multispectral sensors
(MicaSense, Parrot Sequoia, Pix4D) or any other multispectral product.

## Usage

``` r
compute_vi(
  stack,
  index,
  bands = list(red = "B04", red_edge = "B05", nir = "B08", green = "B03"),
  scale_factor = 1,
  clamp = TRUE
)
```

## Arguments

- stack:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  with the required spectral bands (a legacy `raster` object is accepted
  and converted with
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)).
  Band names (or layer indices) are mapped through `bands`.

- index:

  One of `"NDVI"`, `"NDRE"`, `"GNDVI"`, `"CIred"`, `"MCARI"`, `"MSAVI2"`
  (case-insensitive).

- bands:

  Named list or character vector mapping the index inputs (`red`,
  `red_edge`, `nir`, `green`) to layer names in `stack`. Defaults to
  Sentinel-2 L2A naming (`red="B04"`, `red_edge="B05"`, `nir="B08"`,
  `green="B03"`). Only the bands required by the chosen index are looked
  up.

- scale_factor:

  Numeric. If the input reflectance is stored as integer DN (e.g.
  Sentinel-2 L2A 0–10000), divide by this factor before computing the
  index. Default `1` (reflectance already in 0–1).

- clamp:

  Logical. If `TRUE` (default for bounded indices NDVI, NDRE, GNDVI,
  MSAVI2), clamp output to the range -1 to 1. Ignored for CIred and
  MCARI (unbounded).

## Value

A single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with the computed index. Layer name is set to the index name.

## Details

Index formulas (references in the References section):

- NDVI:

  (NIR minus Red) divided by (NIR plus Red). Rouse 1974.

- NDRE:

  (NIR minus RedEdge) divided by (NIR plus RedEdge). Gitelson and
  Merzlyak 1994.

- GNDVI:

  (NIR minus Green) divided by (NIR plus Green). Gitelson 1996.

- CIred:

  NIR divided by RedEdge, minus one. Gitelson 2003.

- MCARI:

  The quantity RedEdge minus Red minus 0.2 times the quantity RedEdge
  minus Green, all multiplied by the ratio RedEdge over Red. Daughtry
  2000.

- MSAVI2:

  2 NIR + 1 minus the square root of (2 NIR + 1)^2 minus 8 times NIR
  minus Red, all divided by two. Qi 1994.

NDVI saturates at LAI \> 3–4 in closed canopies; in mid- to
late-vegetative stages (GS30+ for cereals, V8+ for maize) the red-edge
indices (NDRE, CIred) are considerably more sensitive to canopy nitrogen
status (Clarke 2001; Li 2014; Cao 2015). agrinutri variable-rate
functions
([`variable_rate_N()`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md),
[`estimate_N_rate_from_calibration_curve()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_calibration_curve.md),
[`estimate_N_rate_from_holland_schepers()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_holland_schepers.md))
all accept any normalised VI on a 0–1 scale, so the user can substitute
NDVI with NDRE or GNDVI transparently.

## References

Rouse, J.W. et al. (1974). Monitoring vegetation systems in the Great
Plains with ERTS. NASA SP-351.

Gitelson, A.A. & Merzlyak, M.N. (1994). Quantitative estimation of
chlorophyll-a using reflectance spectra. J. Photochem. Photobiol. B 22.

Gitelson, A.A. et al. (1996). Use of a green channel in remote sensing
of global vegetation from EOS-MODIS. Remote Sens. Environ. 58, 289-298.

Gitelson, A.A. et al. (2003). Relationships between leaf chlorophyll
content and spectral reflectance. J. Plant Physiol. 160, 271-282.

Daughtry, C.S.T. et al. (2000). Estimating corn leaf chlorophyll
concentration from leaf and canopy reflectance. Remote Sens. Environ.
74.

Qi, J. et al. (1994). A modified soil adjusted vegetation index. Remote
Sens. Environ. 48, 119-126.

Clarke, T.R. et al. (2001). Remote sensing of nitrogen status in wheat.
Proc. Beltwide Cotton Conf.

Li, F. et al. (2014). Improving estimation of summer maize nitrogen
status with red edge-based spectral vegetation indices. F. Crops Res.
157.

Cao, Q. et al. (2015). Active canopy sensing of winter wheat nitrogen
status: An evaluation of two sensor systems. Comput. Electron. Agric.
112.

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)
library(agrinutri)

# Sentinel-2 L2A stack (integer DN, 0-10000)
s2 <- terra::rast("S2_Cremonesi_20260415.tif")
names(s2) <- c("B03", "B04", "B05", "B08")

ndvi  <- compute_vi(s2, "NDVI",  scale_factor = 10000)
ndre  <- compute_vi(s2, "NDRE",  scale_factor = 10000)
gndvi <- compute_vi(s2, "GNDVI", scale_factor = 10000)

# Use any VI as input to the VRT pipeline
vr <- variable_rate_N(ndre, n_dose = 142, method = "holland",
                      minN = 60, maxN = 180)
} # }
```
