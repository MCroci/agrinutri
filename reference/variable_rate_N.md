# Variable-rate nitrogen from balance + NDVI

Bridges the constant-rate output of
[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
/
[`calculate_N_fertilization()`](https://mcroci.github.io/agrinutri/reference/calculate_N_fertilization.md)
or
[`scheda_N()`](https://mcroci.github.io/agrinutri/reference/dose_standard_N.md)
with the spatial NDVI-based variable-rate estimators of agrinutri
([`estimate_N_rate_from_calibration_curve()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_calibration_curve.md)
and
[`estimate_N_rate_from_holland_schepers()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_holland_schepers.md)).

## Usage

``` r
variable_rate_N(
  ndvi_raster,
  n_dose,
  method = c("calibration", "holland"),
  envelope = 0.25,
  minN = NULL,
  maxN = NULL,
  mas_cap = NULL,
  plot = FALSE
)
```

## Arguments

- ndvi_raster:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  with NDVI (0–1); layer `NDVI` if present, otherwise the first layer.
  Legacy `raster` objects are accepted and converted with
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html).

- n_dose:

  Numeric. Field-average N dose (kg/ha) from
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md) +
  [`calculate_N_fertilization()`](https://mcroci.github.io/agrinutri/reference/calculate_N_fertilization.md),
  `scheda_N()$dose_final`, or any custom target.

- method:

  Either `"calibration"` (default, two-point linear) or `"holland"`
  (Holland & Schepers sufficiency index).

- envelope:

  Numeric in (0, 1). Half-amplitude of the dose range around `n_dose`
  for the calibration method. Default 0.25 (i.e. minN = 0.75 \* n_dose,
  maxN = 1.25 \* n_dose).

- minN, maxN:

  Optional explicit override of the envelope (in kg/ha).

- mas_cap:

  Numeric or NULL. If provided, caps the per-pixel rate so it never
  exceeds the MAS limit (e.g. from
  [`get_MAS()`](https://mcroci.github.io/agrinutri/reference/get_MAS.md)).

- plot:

  Logical, passed to the underlying estimator. Default FALSE.

## Value

A list with:

- rate_raster:

  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  of N rate per pixel (kg/ha).

- mean_kg_ha:

  Mean rate over non-NA pixels (kg/ha).

- min_kg_ha, max_kg_ha:

  Min and max rate over non-NA pixels.

- n_dose_input:

  The input field-average N dose.

- method:

  The method used.

## Details

Two integration patterns are supported:

1.  **Calibration curve** (`method = "calibration"`): the agronomic
    balance determines the *target field-average* dose; the function
    then derives a `minN`/`maxN` envelope around it (default +/- 25%)
    and applies the linear NDVI-driven calibration (low NDVI = more N,
    high NDVI = less N).

2.  **Holland & Schepers** (`method = "holland"`): the agronomic balance
    is used as the **base N rate** of the H&S sufficiency-index
    algorithm.

The output preserves the field-average dose computed by the balance: the
raster of variable rates has a mean equal to the input `n_dose`
(water-filling rescaling within ), so the agronomic constraint (MAS,
ZVN) is kept.

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)
library(agrinutri)
# NDVI raster
data(s2.rast)
ndvi <- terra::rast(s2.rast)   # s2.rast is a PackedSpatRaster; unwrap it

# 1) Compute agronomic dose with the balance
bal <- N_balance(expected_yield_tons_ha = 6,
                 crop = "Grano duro (pianta intera)",
                 ccp  = "Spring-summer crop 100-130 days",
                 sand = 15.5, clay = 18.5,
                 Ntot = 1.5, SOM = 2, CN = 7.73,
                 oxygen_availability = "Normal",
                 winter_rain = 150, start_spring_rain = 0,
                 prev_crop = "Maize stalks removed",
                 source = "None", fertorg_frequency = "every year",
                 location = "Plain adjacent to urbanized areas",
                 forg_quantity = 0)
n_dose <- calculate_N_fertilization(bal)   # ~128 kg/ha

# 2) Spatialise via NDVI calibration
vr <- variable_rate_N(ndvi, n_dose = n_dose, method = "calibration",
                      mas_cap = get_MAS("Grano duro (pianta intera)")$mas_N)
terra::plot(vr$rate_raster)
vr$mean_kg_ha
} # }
```
