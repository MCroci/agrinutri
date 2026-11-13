# Classify active carbonate

Classify active carbonate

## Usage

``` r
classify_carbonate_att(
  caco3_att,
  active_carbonate.table = agrinutri_data_get("active_carbonate.table")
)
```

## Arguments

- caco3_att:

  Numeric %.

- active_carbonate.table:

  Lookup.

## Value

List with `ID` and `class`.

## Examples

``` r
classify_carbonate_att(6.8)
#> $ID
#> [1] 3
#> 
#> $class
#> [1] "High"
#> 
#> $caco3_att
#> [1] 6.8
#> 
```
