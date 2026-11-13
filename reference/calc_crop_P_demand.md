# Crop P2O5 demand

Returns the crop P2O5 requirement (kg/ha) from `uptake_table` (column
`P2O5`) multiplied by the expected yield.

## Usage

``` r
calc_crop_P_demand(
  expected_yield_tons_ha,
  crop,
  uptake_table = agrinutri_data_get("uptake_table")
)
```

## Arguments

- expected_yield_tons_ha:

  Expected yield (t/ha).

- crop:

  Crop name (must match `uptake_table$crop`).

- uptake_table:

  Lookup table (default
  [`agrinutri::uptake_table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

## Value

A list: `P2O5_requirement` (kg/ha), `unit_coef` (kg P2O5 / t yield),
`crop`.

## Examples

``` r
calc_crop_P_demand(expected_yield_tons_ha = 6,
                   crop = "Grano duro (pianta intera)")
#> $P2O5_requirement
#> [1] 63.6
#> 
#> $unit_coef
#> [1] 1.06
#> 
#> $crop
#> [1] "Durum wheat (whole plant)"
#> 
#> $units
#> [1] "kg P2O5/ha"
#> 
```
