# Compliance-aware variable-rate nitrogen prescription

Generates a spatially explicit nitrogen prescription that combines the
regulatory cap from the Italian DPI nutrient balance (computed by
[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md))
with the local economic optimum nitrogen rate (EONR) computed by the
QUEFTS crop model via **Rquefts**, redistributed across the field
according to Sentinel-2 nitrogen status (NNI) under a mass-balance
constraint.

## Usage

``` r
optimize_VR_DPI(
  field_inputs,
  NNI_raster,
  crop_params = NULL,
  fertilizers = NULL,
  prices = list(p_y = 280),
  zvn = TRUE,
  max_iter = 200L,
  tol = 0.01
)
```

## Arguments

- field_inputs:

  Named list of inputs accepted by
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
  (e.g. `crop`, `ccp`, `expected_yield_tons_ha`, `sand`, `clay`, ...).
  Extra elements are ignored.

- NNI_raster:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  of NNI values for the field. Cells with `NA` are excluded from the
  prescription.

- crop_params:

  Either `NULL` (use
  [`agrinutri_to_quefts_crop()`](https://mcroci.github.io/agrinutri/reference/agrinutri_to_quefts_crop.md)
  on `field_inputs$crop`), a character string (same lookup), or a named
  list of QUEFTS crop parameters passed straight to
  [`Rquefts::quefts()`](https://rdrr.io/pkg/Rquefts/man/quefts.html).

- fertilizers:

  `data.frame` with columns `name`, `N`, `P`, `K`, and `price_kg` (EUR
  per kg product). Defaults to `fertilizers_IT.csv` in `extdata`, or
  falls back to
  [`Rquefts::fertilizers()`](https://rdrr.io/pkg/Rquefts/man/fertilizer.html)
  with a synthetic `price_kg` if needed for
  [`Rquefts::fertApp()`](https://rdrr.io/pkg/Rquefts/man/fertApp.html).

- prices:

  Named list with `p_y` = crop price (EUR/t dry matter). Used as
  `dm_crop_value` in
  [`Rquefts::optApp()`](https://rdrr.io/pkg/Rquefts/man/optApp.html)
  after conversion to EUR/kg.

- zvn:

  Logical. If `TRUE`, apply a 170 kg N/ha cap on the **field-mean**
  applied dose (nitrate-vulnerable zone style territorial cap).

- max_iter:

  Integer. Maximum iterations for mass-balance projection.

- tol:

  Numeric. Convergence tolerance on mean N (kg N/ha).

## Value

A list with:

- N_prescription:

  `SpatRaster` of N rate (kg N/ha)

- P_prescription:

  `SpatRaster` of P2O5 rate (kg/ha)

- K_prescription:

  `SpatRaster` of K2O rate (kg/ha)

- fertilizer_mix:

  `data.frame` from
  [`Rquefts::fertApp()`](https://rdrr.io/pkg/Rquefts/man/fertApp.html)
  (may have one row per cell, depending on Rquefts version), or empty
  `data.frame` on failure

- economics:

  list: `mean_dose`, `p_y`, optional `note`

- compliance:

  list: DPI cap, MAS, ZVN flags, mass-balance check

## Details

Four layers:

1.  **Compliance:**
    [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
    DPI dose; cap with
    [`get_MAS()`](https://mcroci.github.io/agrinutri/reference/get_MAS.md)
    and optional ZVN field-mean 170 kg N/ha.

2.  **Spatial:** NNI drives relative deficit weights (lower NNI, higher
    N share).

3.  **Economic:**
    [`Rquefts::optApp()`](https://rdrr.io/pkg/Rquefts/man/optApp.html)
    per cell on QUEFTS with soil N supply from balance component B.

4.  **Operational:**
    [`Rquefts::fertApp()`](https://rdrr.io/pkg/Rquefts/man/fertApp.html)
    for a cost-optimal mix (optional; requires valid `price_kg` and
    compatible fertilizer table).

Requires suggested packages **Rquefts**, **terra**, and **limSolve**
(via Rquefts for LP).

## Examples

``` r
if (FALSE) { # \dontrun{
fld <- list(
  crop = "Grano duro (granella)",
  expected_yield_tons_ha = 6,
  ccp = "Spring-summer crop 100-130 days",
  sand = 15.5, clay = 18.5, Ntot = 1.5, SOM = 2.0, CN = 7.73,
  oxygen_availability = "Slow",
  winter_rain = 150, start_spring_rain = 0,
  prev_crop = "Winter cereals straw removal",
  source = "Cattle slurry", fertorg_frequency = "every year",
  location = "Isolated plain",
  forg_quantity = 0, organic_previous_year_N = 0, E_to_D = TRUE
)
r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 50, ymin = 0, ymax = 50,
                 crs = "EPSG:32632", vals = runif(25, 0.7, 1.05))
out <- optimize_VR_DPI(field_inputs = fld, NNI_raster = r, prices = list(p_y = 280))
terra::plot(out$N_prescription)
} # }
```
