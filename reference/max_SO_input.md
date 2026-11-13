# Maximum annual organic matter input (t dry matter / ha)

Returns the DPI 2026 maximum annual input of soil organic matter (SO) as
dry matter t/ha, based on the classification of initial SO in soil:
"Poor" = 13, "Normal" = 11, "Rich" = 9 (Fert_Office v1.26 foglio SO).

## Usage

``` r
max_SO_input(
  so_class = c("Poor", "Normal", "Rich"),
  so_max_input = agrinutri_data_get("so_max_input")
)
```

## Arguments

- so_class:

  One of `"Poor"`, `"Normal"`, `"Rich"` (case-insensitive).

- so_max_input:

  Lookup table (default
  [`agrinutri::so_max_input`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

## Value

Numeric t dry matter / ha.

## Examples

``` r
max_SO_input("Normal")
#> [1] 11
```
