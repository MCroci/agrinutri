# Crop K2O demand

Crop K2O demand

## Usage

``` r
calc_crop_K_demand(
  expected_yield_tons_ha,
  crop,
  uptake_table = agrinutri_data_get("uptake_table")
)
```

## Arguments

- expected_yield_tons_ha, crop:

  See `calc_crop_P_demand`.

- uptake_table:

  Lookup table.

## Value

List with `K2O_requirement`, `unit_coef`.

## Examples

``` r
calc_crop_K_demand(expected_yield_tons_ha = 6,
                   crop = "Grano duro (pianta intera)")
#> $K2O_requirement
#> [1] 119.4
#> 
#> $unit_coef
#> [1] 1.99
#> 
#> $crop
#> [1] "Durum wheat (whole plant)"
#> 
#> $units
#> [1] "kg K2O/ha"
#> 
```
