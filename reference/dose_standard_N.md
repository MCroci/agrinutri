# Standard-dose scheme - Nitrogen (DPI Emilia-Romagna 2026)

Implements the DPI 2026 simplified standard-dose method for nitrogen, as
coded in the Fert_Office v1.26 standard-dose sheet for N. Starts from a
crop-specific standard base dose (from `mas.table$standard_N`) and
applies user-selected decrement and increment factors. The final dose is
then capped at MAS (maximum allowed dose) from DPI 2026 Annex 9 /
Regional Regulation 2/2024.

## Usage

``` r
dose_standard_N(
  crop,
  phase = NULL,
  decrements = numeric(),
  increments = numeric(),
  mas.table = agrinutri_data_get("mas.table"),
  apply_mas_cap = TRUE
)

scheda_N(...)
```

## Arguments

- crop:

  Crop name exactly as in `agrinutri::mas.table$crop`.

- phase:

  Optional phase string (as in `mas.table$phase`) for crops with
  multiple phases. If `NULL` (default) and the crop has multiple rows,
  the first match is used and a note is emitted.

- decrements:

  Named numeric vector (kg/ha) with one or more of: `yield_low`,
  `prev_amendant`, `high_SOM`, `after_alfalfa_meadow`, `after_legume`.
  Missing names default to 0. Values are treated as positive and
  subtracted.

- increments:

  Named numeric vector (kg/ha) with one or more of: `yield_high`,
  `low_SOM`, `straw_burial`, `rain_surplus`, `compacted_no_till`.
  Missing names default to 0.

- mas.table:

  Reference MAS lookup (default
  [`agrinutri::mas.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

- apply_mas_cap:

  Logical, default `TRUE`. Cap the final dose at
  `max_N_dose = standard_N + max_increment` from MAS.

- ...:

  Passed to `dose_standard_N()`.

## Value

A named list with components:

- `dose_base`: standard dose from MAS (kg N/ha)

- `total_decrement`, `total_increment`

- `dose_recalculated`: dose after increments/decrements

- `max_N_dose`: DPI 2026 cap

- `dose_final`: min(dose_recalculated, max_N_dose) if
  `apply_mas_cap = TRUE`

- `mas_exceeded`: logical

## Details

The decrement/increment catalogue (with default values in kg/ha) is:

|           |                                     |               |
|-----------|-------------------------------------|---------------|
| Direction | Factor                              | Default kg/ha |
| Decrement | Low yield (\< 5 t/ha)               | user-defined  |
| Decrement | Soil amendment in the previous year | user-defined  |
| Decrement | High soil organic matter            | user-defined  |
| Decrement | After alfalfa or meadow \> 5 years  | 60            |
| Decrement | After a legume                      | 30            |
| Increment | High yield (\> 7 t/ha)              | user-defined  |
| Increment | Low soil organic matter             | user-defined  |
| Increment | Cereal after cereal or straw burial | 30            |
| Increment | Leaching after rainfall surplus     | user-defined  |
| Increment | Compacted soil or no-till seeding   | 10            |

## Examples

``` r
# Durum wheat (whole plant)
scheda_N(crop = "Durum wheat (whole plant)",
         decrements = c(after_alfalfa_meadow = 60),
         increments = c(straw_burial = 30,
                        compacted_no_till = 10))
#> $crop
#> [1] "Durum wheat (whole plant)"
#> 
#> $phase
#> [1] "nd"
#> 
#> $dose_base
#> [1] 160
#> 
#> $total_decrement
#> [1] 60
#> 
#> $total_increment
#> [1] 40
#> 
#> $dose_recalculated
#> [1] 140
#> 
#> $max_N_dose
#> [1] 200
#> 
#> $dose_final
#> [1] 140
#> 
#> $mas_exceeded
#> [1] FALSE
#> 
#> $units
#> [1] "kg N/ha"
#> 
#> $reference
#> [1] "DPI Emilia-Romagna 2026, Fert_Office v1.26 (Scheda_N)"
#> 
```
