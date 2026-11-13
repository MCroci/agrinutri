# Classify exchangeable potassium availability

Classifies K (or K2O) availability by soil texture grouping, following
DPI Emilia-Romagna 2026 (Fert_Office v1.26 foglio `Gri_K`). The
threshold ranges depend on the DPI texture group (`Sabbiosi`,
`Medio impasto`, `Argillosi e limosi`).

## Usage

``` r
classify_K(
  value,
  unit = c("K", "K2O"),
  soil_group,
  k_availability.table = agrinutri_data_get("k_availability.table")
)
```

## Arguments

- value:

  Numeric K or K2O value in ppm.

- unit:

  `"K"` (default) or `"K2O"`. Conversion K2O = K / 0.83333.

- soil_group:

  Texture grouping (must match `k_availability.table$group`).

- k_availability.table:

  Lookup table, default
  [`agrinutri::k_availability.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

A list with `value_ppm_K`, `value_ppm_K2O`, `ID_Gri_K`, `rating`,
`strategy` (`Arricchimento` / `Mantenimento` / `Riduzione`).

## Examples

``` r
classify_K(value = 150, unit = "K2O", soil_group = "Medio impasto")
#> $value_ppm_K
#> [1] 124.9995
#> 
#> $value_ppm_K2O
#> [1] 150
#> 
#> $ID_Gri_K
#> [1] 3
#> 
#> $rating
#> [1] "medium"
#> 
#> $strategy
#> [1] "Mantenimento"
#> 
```
