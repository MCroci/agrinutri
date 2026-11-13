# Classify total carbonate (CaCO3 %)

Classify total carbonate (CaCO3 %)

## Usage

``` r
classify_carbonate_tot(
  caco3_tot,
  total_carbonate.table = agrinutri_data_get("total_carbonate.table")
)
```

## Arguments

- caco3_tot:

  Numeric.

- total_carbonate.table:

  Lookup.

## Value

List with `ID` and `class`.

## Examples

``` r
classify_carbonate_tot(15)
#> $ID
#> [1] 3
#> 
#> $class
#> [1] "Moderately calcareous"
#> 
#> $caco3_tot
#> [1] 15
#> 
```
