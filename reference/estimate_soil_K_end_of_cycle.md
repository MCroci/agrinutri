# Estimate end-of-cycle soil K2O content (ppm)

Simplified relationship:


      K2O_end_ppm = K2O_start_ppm + (K2O_applied - K2O_removed - K2O_leaching) / (soil_weight_30cm/1000)

The lisciviazione (H) is taken from `K_leaching_by_clay(clay_pct)`.

## Usage

``` r
estimate_soil_K_end_of_cycle(
  K2O_start_ppm,
  K2O_applied,
  K2O_removed,
  clay_pct,
  soil_group,
  depth_cm = 30,
  texture_groups.table = agrinutri_data_get("texture_groups.table")
)
```

## Arguments

- K2O_start_ppm:

  Initial exchangeable K2O ppm.

- K2O_applied, K2O_removed:

  kg K2O/ha applied / removed.

- clay_pct:

  Clay percentage for H leaching.

- soil_group:

  DPI texture group.

- depth_cm:

  Default 30 cm.

- texture_groups.table:

  Lookup.

## Value

Numeric ppm K2O at end of cycle.

## Examples

``` r
estimate_soil_K_end_of_cycle(K2O_start_ppm = 150, K2O_applied = 230,
                             K2O_removed = 119.4, clay_pct = 18.5,
                             soil_group = "Medio impasto")
#> [1] 173.2308
```
