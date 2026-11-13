# Leaching Loss of Nitrogen

DPI 2026 (Allegato 2; foglio `C&D` di Fert_Office v1.26): loss of
readily available mineral nitrogen ("N pronto") from leaching.

## Usage

``` r
leaching_loss(
  winter_rain = 160,
  start_spring_rain = 40,
  oxygen_availability = "Normal",
  id_rag = 3,
  b1 = 29.16,
  perennial = FALSE,
  autumn_loss = TRUE
)
```

## Arguments

- winter_rain:

  Winter rainfall (October 1 to January 31) in mm.

- start_spring_rain:

  Rainfall in February in mm.

- oxygen_availability:

  Oxygen availability level in the soil: one of `ca.table$availability`
  (e.g. `"Normal"`, `"Slow"`, `"Fast"`).

- id_rag:

  Soil texture group index (`ID_Rag`); retained for backward
  compatibility (not used in the formulas).

- b1:

  Readily available nitrogen in the soil (kg N/ha).

- perennial:

  Logical; `TRUE` for perennial crops in production (time coefficient
  1), whose leachable pool is fixed at 30 kg N/ha.

- autumn_loss:

  Logical; `FALSE` sets \\C_a\\ to 0.

## Value

A list containing:

- C1:

  Autumn–winter leaching loss (kg N/ha).

- C2:

  End-of-winter leaching loss (kg N/ha).

- surplus_pluviometrico:

  Logical. `TRUE` when `winter_rain + start_spring_rain >= 300` mm (DPI
  2026 scheda a dose standard: surplus-pluviometric flag).

## Details

Let \\N_p\\ be the leachable N pronto: `b1` for crops with a cycle
shorter than one year, or a fixed 30 kg N/ha for perennial crops in
production (`perennial = TRUE`, i.e. time coefficient 1).

- **C1** (\\C_a\\, autumn–winter):

  Depends on winter rainfall \\y\\ (1 October – 31 January,
  `winter_rain`, mm): \\N_p \times \min(\max(y - 150, 0), 100)/100\\,
  i.e. no loss up to 150 mm and the whole pool above 250 mm. It is 0
  when `autumn_loss = FALSE` (first phase of a crop cycle, e.g. a second
  crop or pre-planting, as in Fert_Office).

- **C2** (\\C_b\\, end of winter):

  With \\s = y + f - 250\\, where \\f\\ is February rainfall
  (`start_spring_rain`): when \\s \> 0\\ the N pronto not yet lost
  (\\N_p - C_a\\) is lost, plus 1 kg N/ha for every 10 mm of \\s\\ if
  \\y \> 150\\ mm.

`oxygen_availability` is validated against
[`ca.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)
for consistency with other balance terms; the leaching formulas do not
use it.

## Examples

``` r
leaching_loss(winter_rain = 160, start_spring_rain = 40,
              oxygen_availability = "Normal", id_rag = 3, b1 = 29.16)
#> $C1
#> [1] 2.916
#> 
#> $C2
#> [1] 0
#> 
#> $surplus_pluviometrico
#> [1] FALSE
#> 
leaching_loss(winter_rain = 300, start_spring_rain = 20, b1 = 0,
              perennial = TRUE)
#> $C1
#> [1] 30
#> 
#> $C2
#> [1] 7
#> 
#> $surplus_pluviometrico
#> [1] TRUE
#> 
```
