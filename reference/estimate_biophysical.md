# GPR-based estimation of canopy biophysical variables from Sentinel-2 L2A

Applies pre-trained Gaussian Process Regression (GPR) models to a
Sentinel-2 Level-2A surface-reflectance raster (10 bands, canonical
order `B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12`) and returns
canopy-level biophysical maps (e.g. leaf area index LAI, canopy water
content Cw, canopy nitrogen content CNC).

## Usage

``` r
estimate_biophysical(
  raster_path,
  output_dir,
  variables = c("LAI", "Cm", "Cw", "FVC", "Cab", "laiCab", "CNC_Cab", "CNC_Cprot"),
  model_dir = NULL,
  apply_offset = FALSE,
  offset = -1000,
  scale = 10000,
  nodata_in = 0,
  block_rows = 512
)
```

## Arguments

- raster_path:

  Path to a 10-band S2 L2A GeoTIFF in the canonical band order.

- output_dir:

  Directory where the output GeoTIFF maps are written. Created if
  missing.

- variables:

  Character vector. Any subset of
  `c("LAI", "Cm", "Cw", "FVC", "Cab", "laiCab", "CNC_Cab", "CNC_Cprot")`.

- model_dir:

  Directory containing the `*.json` GPR model files.

- apply_offset:

  Logical. If `TRUE` the raster is shifted by `offset` before being
  divided by `scale`. Default `FALSE`: the input is treated as
  offset-applied reflectance (reflectance = DN / scale), matching
  [`compute_vi`](https://mcroci.github.io/agrinutri/reference/compute_vi.md)
  and the bundled scenes. Set `TRUE` only for raw baseline-04.00 L2A DN
  (see the Inputs and outputs section).

- offset, scale:

  Radiometric conversion from DN to surface reflectance: reflectance =
  (DN + offset) / scale when `apply_offset = TRUE`, else DN / scale.
  `offset = -1000` matches the ESA S2 L2A processor baseline 04.00
  `BOA_ADD_OFFSET` and is only used when `apply_offset = TRUE`.

- nodata_in:

  Integer. Pixel value treated as nodata in the input.

- block_rows:

  Integer. Number of rows processed per chunk; tune to available RAM
  (512 is safe on 8 GB machines).

## Value

Named list of
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects, one per output GeoTIFF written: the mean map for each requested
variable plus a `<var>_unc` layer for every variable whose model exposes
prediction uncertainty. The corresponding on-disk file paths are
attached as the `"paths"` attribute (a named list aligned with the
result), so `attr(result, "paths")[[v]]` is the GeoTIFF backing variable
`v`.

## Details

The function is a pure-R port of the `pyeogpr` inference pipeline
(Estevez et al., 2022). It only depends on `terra` (raster I/O) and
`jsonlite` (model loading) and produces the same numerical output as the
reference Python implementation to machine precision (correlation 1.0,
relative error \< 1.4 \\\cdot 10^{-8}\\ on a 200-pixel benchmark). The
models themselves are trained on PROSAIL + canopy N simulations and are
distributed as `*.json` files.

## Inputs and outputs

The S2 raster is expected to store surface reflectance scaled by `scale`
(default `10000`), i.e. reflectance = DN / scale in the 0-1.5 range.
This "harmonized" / offset-applied convention is shared with
[`compute_vi`](https://mcroci.github.io/agrinutri/reference/compute_vi.md),
matches the bundled example scenes and most analysis-ready L2A products
(Copernicus harmonized, Google Earth Engine `HARMONIZED`, sen2r), and is
the reflectance range the bundled GPR models were trained on (per-band
training means 0.04-0.41). Accordingly **no additive offset is applied
by default** (`apply_offset = FALSE`). Only for *raw* Processing
Baseline 04.00+ L2A DN, where the `BOA_ADD_OFFSET` of -1000 has not yet
been applied, set `apply_offset = TRUE` (with `offset = -1000`) so the
function computes reflectance = (DN + offset) / scale. Getting this
wrong shifts every band by ~0.1 reflectance and can drive all pixels out
of the valid range, in which case the GPR returns empty (all-`NA`) maps;
the function warns when most valid pixels fall outside 0-1.5.

One GeoTIFF is written per requested variable (plus an `_unc.tif` file
with prediction standard deviation for variables whose model exposes the
pre-computed `Linv_pre_calc` matrix). Output rasters inherit the
geometry (CRS, extent, resolution) of the input.

## Use within agrinutri

Two of the outputs are directly usable as inputs to
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md):

- **W** (aboveground dry biomass, t DM ha\\^{-1}\\) can be approximated
  from `LAI` \\\times\\ `Cm` (leaf dry-matter mass per unit leaf area, g
  cm\\^{-2}\\) converted to t ha\\^{-1}\\ via the factor `100` (g
  cm\\^{-2}\\ \\\to\\ kg m\\^{-2}\\ \\\to\\ t ha\\^{-1}\\).

- **N_actual (% DM)** follows from `CNC_Cprot` (canopy N content, g
  m\\^{-2}\\ ground) divided by the biomass per unit ground area.

The helper
[`biophysical_to_NNI_inputs`](https://mcroci.github.io/agrinutri/reference/biophysical_to_NNI_inputs.md)
wraps this conversion.

## References

Estevez, J., Salinero-Delgado, M., Berger, K., Pipia, L.,
Rivera-Caicedo, J. P., Wocher, M., Reyes-Munoz, P., Tagliabue, G.,
Boschetti, M., & Verrelst, J. (2022). Gaussian processes retrieval of
crop traits in Google Earth Engine based on Sentinel-2 top-of-atmosphere
data. *Remote Sensing of Environment*, 273, 112958.

## See also

[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md),
[`diagnose_N_status`](https://mcroci.github.io/agrinutri/reference/diagnose_N_status.md),
[`biophysical_to_NNI_inputs`](https://mcroci.github.io/agrinutri/reference/biophysical_to_NNI_inputs.md),
[`estimate_N_rate_from_holland_schepers`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_holland_schepers.md)

## Examples

``` r
# \donttest{
# Loading the Gaussian-process model takes a few seconds
scene <- system.file("extdata/sentinel-2/S2_field001_20240711.tif", package = "agrinutri")
if (nzchar(scene)) {
  od <- tempfile()
  dir.create(od)
  maps <- estimate_biophysical(scene, od, variables = "LAI", block_rows = 32)
  stopifnot(inherits(maps$LAI, "SpatRaster"),
            file.exists(attr(maps, "paths")$LAI))
}
# }
```
