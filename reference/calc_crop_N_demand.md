# Crop requirement estimation

Estimates the crop's nitrogen requirement based on unit crop absorption
and expected yield, with a biological N-fixation correction for legumes.

## Usage

``` r
calc_crop_N_demand(
  expected_yield_tons_ha = 10,
  crop = "Shredded corn class 700",
  apply_n_fixation = TRUE
)
```

## Arguments

- expected_yield_tons_ha:

  Expected crop yield in tons per hectare (t/ha).

- crop:

  The name of the crop for which to calculate the requirement. Must be a
  valid value in the `crop` column of the `uptake_table` (English
  canonical names after agrinutri 0.12.0).

- apply_n_fixation:

  Logical. If `TRUE` (default) the gross demand is multiplied by
  `(1 - n_fixation_pct / 100)` using
  [`agrinutri::crops.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).
  Set to `FALSE` to recover the pre-0.12.1 behaviour (no fixation
  correction).

## Value

A list with `N_requirement` (kg/ha), `units` ("kg/ha") and
`n_fixation_pct` (0-100, the fraction applied).

## Details

The calculation is:


    A_gross = unit crop absorption (kg N / t yield) * yield (t / ha)
    A       = A_gross * (1 - n_fixation_pct / 100)

where `n_fixation_pct` is taken from
`agrinutri::crops.table$n_fixation_pct` (0 for non-legumes, 85-100 for
soybean, pea, faba bean, alfalfa, lupin, clover, etc.). Non-legume crops
have `n_fixation_pct = 0`, so the correction is a no-op.

## Note

The `uptake_table` should provide the unit crop absorption for the
specified `crop`. The default table
([`agrinutri::uptake_table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md))
may not be suitable for all regions or specific crop varieties.
