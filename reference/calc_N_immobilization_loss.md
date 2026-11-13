# Nitrogen Immobilization Loss Calculation

Calculates the amount of nitrogen immobilized by soil microorganisms
based on soil fertility, oxygen availability, and drainage.

## Usage

``` r
calc_N_immobilization_loss(
  B = 50,
  oxygen_availability = "Normal",
  id_rag = 1,
  greenhouse = FALSE,
  E_residual = 0
)
```

## Arguments

- B:

  Soil fertility factor (B) representing the potential nitrogen
  mineralization.

- oxygen_availability:

  Oxygen availability level in the soil (e.g., "Normal", "Reduced",
  "Poor").

- id_rag:

  Soil drainage index (ID_Rag), ranging from 1 (well-drained) to 5
  (poorly drained).

- greenhouse:

  Logical. If `TRUE`, adds 2 kg/ha of nitrogen immobilization as per DPI
  2026 foglio C&D (cella D23 "In serra = 2"). Default `FALSE`.

- E_residual:

  Optional numeric. When the previous crop has negative residual N (e.g.
  maize stalks buried, sorghum) the DPI 2026 sums `-E` into D (see
  foglio C&D, cella I21 "E da conteggiare"). If provided and negative,
  `-E_residual` is added to D. Default `0` (no adjustment; E is handled
  separately in `calculate_N_fertilization`).

## Value

The estimated nitrogen immobilization loss (D) in kg/ha.

## Details

This function uses lookup tables (`ca.table` and `cb.table`) from the
`agrinutri` package to determine the immobilization correction factor
(`fc_D`) based on soil drainage and oxygen availability. The nitrogen
immobilization loss is then calculated as:

D = B \* fc_D + 2 \* (greenhouse) + max(0, -E_residual)

## Examples

``` r
calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal", id_rag = 3)
#> [1] 15
# greenhouse:
calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal",
                           id_rag = 3, greenhouse = TRUE)
#> [1] 17
```
