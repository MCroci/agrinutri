# Potassium balance (DPI Emilia-Romagna 2026 metodo del bilancio)

Implements the K2O balance of Fert_Office v1.26 foglio `Bilancio` /
`Gri_K`.

## Usage

``` r
K_balance(
  expected_yield_tons_ha,
  crop,
  k_value,
  k_unit = c("K", "K2O"),
  soil_group = NULL,
  clay = NULL,
  sand = NULL,
  advance_K2O = 0,
  include_leaching = TRUE
)
```

## Arguments

- expected_yield_tons_ha:

  Expected yield (t/ha).

- crop:

  Crop name (matches `uptake_table$crop`).

- k_value:

  Analytical K (or K2O) ppm.

- k_unit:

  `"K"` or `"K2O"`, default `"K"`.

- soil_group:

  DPI texture group; if `NULL` and `clay`/`sand` given, derived.

- clay, sand:

  Soil clay/sand percentages (%).

- advance_K2O:

  Advance anni futuri (default 0).

- include_leaching:

  Logical, use clay-based H leaching (default TRUE).

## Value

A data frame with A, H, B1, A2, B2, strategy, ID_Gri_K, K2O_required.

## Details

Formula:


      K2O da apportare = A (asportazione) + H (lisciviazione clay-based) + B1 (arricchimento)
                         + A2 (advance_allowed) - B2 (riduzione)

where B1 (enrichment) and B2 (reduction) depend on the exchangeable-K
class (see
[`soil_K_availability()`](https://mcroci.github.io/agrinutri/reference/soil_K_availability.md)).
The result is bounded to 0-300 kg K2O/ha as in Fert_Office.

## Examples

``` r
K_balance(expected_yield_tons_ha = 6,
          crop = "Grano duro (pianta intera)",
          k_value = 150, k_unit = "K2O",
          clay = 18.5, sand = 15.5)
#>       A A_fabbisogno  H B1 A2 B2     strategy ID_Gri_K K2O_required
#> 1 119.4        119.4 20  0  0  0 Mantenimento        3        139.4
```
