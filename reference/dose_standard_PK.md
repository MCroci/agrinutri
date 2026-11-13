# Scheda a dose Standard - Phosphorus and Potassium (DPI 2026)

Implements the DPI 2026 simplified "Scheda a dose Standard" method for
P2O5 and K2O, matching Fert_Office v1.26 foglio `Scheda_PK`. The base
dose for phosphorus is selected from `standard_pk_doses.table` according
to soil P class; potassium base dose depends on soil K class. Then
user-selected decrements and increments are applied. No MAS cap exists
for P/K in DPI 2026 (the MAS applies to N only).

## Usage

``` r
dose_standard_PK(
  crop,
  phase = NULL,
  soil_P_class = c("normal", "low", "high", "very_low"),
  soil_K_class = c("normal", "low", "high", "very_low"),
  P_decrements = numeric(),
  P_increments = numeric(),
  K_decrements = numeric(),
  K_increments = numeric(),
  standard_pk_doses.table = agrinutri_data_get("standard_pk_doses.table")
)

scheda_PK(...)
```

## Arguments

- crop:

  Crop name (matches `standard_pk_doses.table$crop`).

- phase:

  Optional phase name.

- soil_P_class:

  One of `"normal"` (default), `"low"`, `"high"`, `"very_low"`. Selects
  the `P2O5_<class>` column in `standard_pk_doses.table`.

- soil_K_class:

  Same four levels for potassium (`K2O_<class>` columns).

- P_decrements, P_increments, K_decrements, K_increments:

  Named numeric vectors of adjustments (kg/ha). See
  [`scheda_N()`](https://mcroci.github.io/agrinutri/reference/dose_standard_N.md)
  for the same pattern.

- standard_pk_doses.table:

  Lookup (default
  [`agrinutri::standard_pk_doses.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

- ...:

  Passed to `dose_standard_PK()`.

## Value

A named list with `dose_base_P2O5`, `dose_base_K2O`, `dose_final_P2O5`,
`dose_final_K2O`, and subtotals.

## Examples

``` r
scheda_PK(
  crop = "Grano duro (pianta intera)",
  soil_P_class = "normal",
  soil_K_class = "normal"
)
#> $crop
#> [1] "Grano duro (pianta intera)"
#> 
#> $phase
#> [1] "nd"
#> 
#> $soil_P_class
#> [1] "normal"
#> 
#> $soil_K_class
#> [1] "normal"
#> 
#> $dose_base_P2O5
#> [1] 60
#> 
#> $P_total_decrement
#> [1] 0
#> 
#> $P_total_increment
#> [1] 0
#> 
#> $dose_final_P2O5
#> [1] 60
#> 
#> $dose_base_K2O
#> [1] 120
#> 
#> $K_total_decrement
#> [1] 0
#> 
#> $K_total_increment
#> [1] 0
#> 
#> $dose_final_K2O
#> [1] 120
#> 
#> $units
#> [1] "kg/ha"
#> 
#> $reference
#> [1] "DPI Emilia-Romagna 2026, Fert_Office v1.26 (Scheda_PK)"
#> 
```
