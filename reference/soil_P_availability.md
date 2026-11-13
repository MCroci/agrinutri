# Compute soil P availability terms (B1 / A mantenimento / B2) for the P balance

Implements the DPI 2026 Allegato 2 logic coded in Fert_Office v1.26
foglio `Gri_P`: depending on the phosphorus availability class
(`Arricchimento`, `Mantenimento`, `Riduzione`) returns the contribution
that goes onto the NECESSITA' side (B1, A anticipations) or onto the
DISPONIBILITA' side (B2).

## Usage

``` r
soil_P_availability(
  olsen_value,
  unit = c("P", "P2O5"),
  soil_group,
  A_demand_P2O5,
  depth_cm = 30,
  total_carbonate = NULL,
  p_availability.table = agrinutri_data_get("p_availability.table"),
  p_availability_meta = agrinutri_data_get("p_availability_meta"),
  texture_groups.table = agrinutri_data_get("texture_groups.table")
)
```

## Arguments

- olsen_value:

  Numeric, Olsen P or P2O5 ppm.

- unit:

  `"P"` or `"P2O5"` (default `"P"`).

- soil_group:

  One of `"Sabbiosi"`, `"Medio impasto"`, `"Argillosi e limosi"` (must
  match `texture_groups.table$group`).

- A_demand_P2O5:

  Crop P2O5 demand (kg/ha) (from
  [`calc_crop_P_demand()`](https://mcroci.github.io/agrinutri/reference/calc_crop_P_demand.md)).

- depth_cm:

  Soil depth used for weight (default 30 cm).

- total_carbonate:

  Total carbonate (CaCO3, percent) from the soil test. `NULL` (default)
  uses the legacy constant immobilisation factor.

- p_availability.table, p_availability_meta, texture_groups.table:

  Lookup tables.

## Value

A list with `strategy`, `B1` (arricchimento kg/ha), `A_mantenimento`,
`B2` (riduzione kg/ha), and diagnostic `soil_weight_t_ha`,
`P_immobilisation_factor`.

## Details

In "Riduzione" (very high P) the crop removal A is kept and the excess
over the upper bound of the normal range (68.7 ppm P2O5) times the soil
weight is returned as B2, to be subtracted.

The B1 arricchimento term equals the distance of the analytical value
from the lower bound of the normal class (22.9 ppm P2O5), multiplied by
the soil weight at 30 cm (t/ha) and by the P immobilisation factor. As
in Fert_Office (foglio `Gri_P`, cell L10) the factor is the
texture-group base value
(`texture_groups.table$P_immobilisation_factor`: 1.2 sandy, 1.3 loamy,
1.4 clay) plus 0.02 times the total carbonate content (percent). When
`total_carbonate` is not supplied, the legacy constant
`p_availability_meta$P_immobilisation_factor` (1.6, i.e. a loamy soil
with 15 percent total carbonate) is used.

## Examples

``` r
soil_P_availability(olsen_value = 15, unit = "P2O5",
                    soil_group = "Medio impasto", A_demand_P2O5 = 63.6)
#> $strategy
#> [1] "Arricchimento"
#> 
#> $ID_Gri_P
#> [1] 2
#> 
#> $rating
#> [1] "low"
#> 
#> $B1
#> [1] 49.29605
#> 
#> $A_mantenimento
#> [1] 63.6
#> 
#> $B2
#> [1] 0
#> 
#> $soil_weight_t_ha
#> [1] 3900
#> 
#> $P_immobilisation_factor
#> [1] 1.6
#> 
```
