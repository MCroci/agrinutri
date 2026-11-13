# Phosphorus balance (DPI Emilia-Romagna 2026 metodo del bilancio)

Implements the P2O5 balance of Fert_Office v1.26 foglio `Bilancio`.

## Usage

``` r
P_balance(
  expected_yield_tons_ha,
  crop,
  olsen_value,
  olsen_unit = c("P", "P2O5"),
  soil_group = NULL,
  clay = NULL,
  sand = NULL,
  advance_P2O5 = 0,
  depth_cm = 30,
  total_carbonate = NULL
)
```

## Arguments

- expected_yield_tons_ha:

  Expected yield (t/ha).

- crop:

  Crop name (matches `uptake_table$crop`).

- olsen_value:

  Analytical Olsen P (or P2O5) in ppm.

- olsen_unit:

  `"P"` or `"P2O5"`, default `"P"`.

- soil_group:

  DPI texture group; if `NULL` and `clay`/`sand` given, derived via
  [`calc_soil_group_and_id_rag()`](https://mcroci.github.io/agrinutri/reference/calc_soil_group_and_id_rag.md)
  and mapped to Italian Ragg.

- clay, sand:

  Soil clay/sand percentages (%).

- advance_P2O5:

  Advance anni futuri (default 0 kg/ha).

- depth_cm:

  Soil depth for enrichment calculation (default 30 cm).

- total_carbonate:

  Total carbonate (CaCO3, percent). Sets the P immobilisation factor of
  the enrichment term as in Fert_Office (texture base + 0.02 x CaCO3);
  `NULL` keeps the legacy constant 1.6. See
  [`soil_P_availability()`](https://mcroci.github.io/agrinutri/reference/soil_P_availability.md).

## Value

A data frame with A, B1, A2, B2, `strategy`, `ID_Gri_P`,
`P2O5_required`.

## Details

Formula:


      P2O5 da apportare = A (asportazione) + B1 (arricchimento) + A2 (advance_allowed)
                           - B2 (riduzione)

where B2 is the excess over the normal availability range ("Riduzione"
strategy). The result is bounded to 0-250 kg P2O5/ha as in Fert_Office.

## Examples

``` r
P_balance(expected_yield_tons_ha = 6,
          crop = "Grano duro (pianta intera)",
          olsen_value = 15, olsen_unit = "P2O5",
          clay = 18.5, sand = 15.5, total_carbonate = 15)
#>      A A_fabbisogno       B1 A2 B2      strategy ID_Gri_P soil_weight_t_ha
#> 1 63.6         63.6 49.29605  0  0 Arricchimento        2             3900
#>   P2O5_required
#> 1       112.896
```
