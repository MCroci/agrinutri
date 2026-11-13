# Resolve a numeric ID_Rag from any soil-group label or clay/sand %

Convenience wrapper that returns the integer 1/2/3 for any soil group
text (Italian plural, singular or English) or, alternatively, derives it
from clay and sand percentages via
[`calc_soil_group_and_id_rag()`](https://mcroci.github.io/agrinutri/reference/calc_soil_group_and_id_rag.md).

## Usage

``` r
resolve_id_rag(soil_group = NULL, clay = NULL, sand = NULL)
```

## Arguments

- soil_group:

  Character (any convention) or NULL.

- clay, sand:

  Numeric percentages, used only if `soil_group` is NULL.

## Value

Integer ID_Rag (1/2/3).

## Examples

``` r
resolve_id_rag("Loamy textures")
#> [1] 2
resolve_id_rag(clay = 18.5, sand = 15.5)
#> [1] 2
```
