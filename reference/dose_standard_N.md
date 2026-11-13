# Scheda a dose Standard - Nitrogen (DPI Emilia-Romagna 2026)

Implements the DPI 2026 simplified "Scheda a dose Standard" method for
nitrogen, as coded in Fert_Office v1.26 sheet `Scheda_N`. Starts from a
crop-specific standard base dose (from `mas.table$standard_N`) and
applies user-selected decrement and increment factors. The final dose is
then capped at MAS (maximum allowed dose) from DPI 2026 Allegato 9 /
Reg. reg. 2/2024.

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

  Optional phase string (e.g. "Primaverile-estiva 100-130 gg") for crops
  with multiple fases. If `NULL` (default) and the crop has multiple
  rows, the first match is used and a note is emitted.

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

|            |                                       |               |
|------------|---------------------------------------|---------------|
| Direction  | Factor                                | Default kg/ha |
| Decremento | Resa bassa (\< 5 t/ha)                | user-defined  |
| Decremento | Ammendante nell'anno precedente       | user-defined  |
| Decremento | Tenore SO nel suolo elevato           | user-defined  |
| Decremento | Dopo medica o prato \> 5 anni         | 60            |
| Decremento | Dopo una leguminosa                   | 30            |
| Incremento | Resa alta (\> 7 t/ha)                 | user-defined  |
| Incremento | Tenore SO nel suolo basso             | user-defined  |
| Incremento | Ristoppio o interramento paglie       | 30            |
| Incremento | Lisciviazione x surplus pluviometrico | user-defined  |
| Incremento | Terreno compattato o semina su sodo   | 10            |

## Examples

``` r
# Grano duro pianta intera, fase primaverile-estiva 100-130 gg
scheda_N(crop = "Grano duro (pianta intera)",
         decrements = c(after_alfalfa_meadow = 60),
         increments = c(straw_burial = 30,
                        compacted_no_till = 10))
#> Crop 'Durum wheat (whole plant)' has 2 matching rows; using the first.
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
