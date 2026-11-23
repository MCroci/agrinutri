# Compute soil K availability terms for the K balance

Compute soil K availability terms for the K balance

## Usage

``` r
soil_K_availability(
  k_value,
  unit = c("K", "K2O"),
  soil_group,
  A_demand_K2O,
  clay_pct,
  include_leaching = TRUE,
  k_availability.table = agrinutri_data_get("k_availability.table"),
  texture_groups.table = agrinutri_data_get("texture_groups.table")
)
```

## Arguments

- k_value, unit, soil_group:

  K analytical value and DPI texture group.

- A_demand_K2O:

  Crop K2O demand (kg/ha) from
  [`calc_crop_K_demand()`](https://mcroci.github.io/agrinutri/reference/calc_crop_K_demand.md).

- clay_pct:

  Clay percentage, used to compute leaching `H`.

- include_leaching:

  Logical, add K leaching to the maintenance term. Default TRUE.

- k_availability.table, texture_groups.table:

  Lookup tables.

  As in Fert_Office v1.26 (K sheet), with K2O the analytical value and W
  the soil weight of the 30 cm layer (t/ha):

  - enrichment (low / very low): B1 = (lower bound of the medium class -
    K2O) x W / 1000 x (1 + 0.018 x clay);

  - maintenance: A + H;

  - reduction (high): B2 = (K2O - upper bound of the medium class) x W /
    1000, subtracted from A + H.

## Value

A list with `strategy`, `ID_Gri_K`, `B1`, `A_mantenimento` (crop
removal + H), `B2`, `H` (leaching).

## Examples

``` r
soil_K_availability(k_value = 150, unit = "K2O",
                    soil_group = "Loamy textures",
                    A_demand_K2O = 119.4, clay_pct = 18.5)
#> $strategy
#> [1] "Mantenimento"
#> 
#> $ID_Gri_K
#> [1] 3
#> 
#> $rating
#> [1] "medium"
#> 
#> $B1
#> [1] 0
#> 
#> $A_mantenimento
#> [1] 139.4
#> 
#> $B2
#> [1] 0
#> 
#> $H
#> [1] 20
#> 
```
