# Classify soil pH

DPI 2026 7-class scheme from Fert_Office v1.26 foglio `pH`:

- fortemente acido: pH \< 5.4

- acido: 5.4 - 6.0

- leggermente acido: 6.1 - 6.7

- neutro: 6.8 - 7.3

- leggermente alcalino: 7.4 - 8.1

- alcalino: 8.2 - 8.6

- fortemente alcalino: \> 8.6

The class is found as in Fert_Office (`VLOOKUP` on the lower thresholds
0, 5.4, 6.0, 6.7, 7.3, 8.1, 8.61), so a value equal to a threshold falls
in the upper class: for instance pH 6.0 is "leggermente acido". The
ranges above are those printed in the DPI table for one-decimal pH
readings.

## Usage

``` r
classify_pH(pH, ph.table = agrinutri_data_get("ph.table"))
```

## Arguments

- pH:

  Numeric.

- ph.table:

  Lookup (default
  [`agrinutri::ph.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

## Value

List with `ID_pH` and `class`.

## Examples

``` r
classify_pH(8.3)
#> $ID_pH
#> [1] 6
#> 
#> $class
#> [1] "alkaline"
#> 
#> $pH
#> [1] 8.3
#> 
```
