# Classify Olsen phosphorus availability

Classifies soil phosphorus availability using the Olsen method,
following DPI Emilia-Romagna 2026 (Fert_Office v1.26 foglio `Gri_P`).
The input may be expressed either as elemental P or as P2O5 equivalent;
the conversion factor is P2O5 = P / 0.436681.

## Usage

``` r
classify_P_olsen(
  value,
  unit = c("P", "P2O5"),
  p_availability.table = agrinutri_data_get("p_availability.table"),
  p_availability_meta = agrinutri_data_get("p_availability_meta")
)
```

## Arguments

- value:

  Numeric. Olsen phosphorus value in ppm.

- unit:

  Either `"P"` or `"P2O5"` (default `"P"`).

- p_availability.table:

  Lookup table, default
  [`agrinutri::p_availability.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

- p_availability_meta:

  Conversion metadata, default
  [`agrinutri::p_availability_meta`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

A list with:

- `value_ppm_P`, `value_ppm_P2O5`: input converted to both units.

- `ID_Gri_P`: class id (1 molto bassa ... 5 molto elevata).

- `rating`: human-readable class.

- `soil_class`: DPI "Classe dotaz." (`molto scarso`, `scarso`,
  `normale`, `molto alto`).

- `strategy`: one of `"Arricchimento"`, `"Mantenimento"`, `"Riduzione"`.

## Examples

``` r
classify_P_olsen(value = 15, unit = "P2O5")
#> $value_ppm_P
#> [1] 6.550215
#> 
#> $value_ppm_P2O5
#> [1] 15
#> 
#> $ID_Gri_P
#> [1] 2
#> 
#> $rating
#> [1] "low"
#> 
#> $soil_class
#> [1] "scarso"
#> 
#> $strategy
#> [1] "Arricchimento"
#> 
classify_P_olsen(value = 6.55, unit = "P")
#> $value_ppm_P
#> [1] 6.55
#> 
#> $value_ppm_P2O5
#> [1] 14.99951
#> 
#> $ID_Gri_P
#> [1] 2
#> 
#> $rating
#> [1] "low"
#> 
#> $soil_class
#> [1] "scarso"
#> 
#> $strategy
#> [1] "Arricchimento"
#> 
```
