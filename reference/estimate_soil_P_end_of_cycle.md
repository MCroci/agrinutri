# Estimate end-of-cycle soil P2O5 content (ppm)

Given the starting soil P2O5 (ppm), the crop P2O5 asportazione (kg/ha)
and the fertilization plan (from `plan_distribution`), returns the
estimated soil P2O5 at the end of the cycle in ppm P2O5 (useful as input
for the following year's calculation). Formula from Fert_Office v1.26
foglio `Gri_P!C27`:


      P2O5_end_ppm = P2O5_start_ppm + (P2O5_applied - P2O5_removed) / (soil_weight_30cm/1000) / P_immobilisation_factor

## Usage

``` r
estimate_soil_P_end_of_cycle(
  P2O5_start_ppm,
  unit = c("P2O5", "P"),
  P2O5_applied,
  P2O5_removed,
  soil_group,
  depth_cm = 30,
  texture_groups.table = agrinutri_data_get("texture_groups.table"),
  p_availability_meta = agrinutri_data_get("p_availability_meta")
)
```

## Arguments

- P2O5_start_ppm:

  Initial Olsen P2O5 ppm (or pass P and `unit="P"`).

- unit:

  `"P"` or `"P2O5"`.

- P2O5_applied:

  kg P2O5/ha applied via fertilisers.

- P2O5_removed:

  kg P2O5/ha removed by crop (asportazione).

- soil_group:

  DPI texture grouping.

- depth_cm:

  Soil depth (default 30 cm).

- texture_groups.table, p_availability_meta:

  Lookups.

## Value

Numeric ppm P2O5 at end of cycle.

## Examples

``` r
estimate_soil_P_end_of_cycle(P2O5_start_ppm = 15, P2O5_applied = 170,
                             P2O5_removed = 64, soil_group = "Medio impasto")
#> [1] 31.98718
```
