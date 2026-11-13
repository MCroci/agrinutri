# Calculate soil fertility parameters (B = B1 + B2 in DPI).

Estimates readily available and mineralized nitrogen in the soil as in
Fert_Office v1.26 (foglio `B`). DPI naming: b1 = readily available N
from soil total N ("N pronto", DPI B2); b2 = mineralized N from SOM (DPI
B1).

## Usage

``` r
soil_fertility(
  Ntot = 1.2,
  SOM = 2,
  soil.group = "Sandy textures",
  CN = 8,
  ccp = "Autumn-winter crop <150 days",
  soil_seeding = c("traditional", "no-till"),
  crop = NULL,
  coefN_readily = agrinutri_data_get("coefN_readily"),
  coefN_mineralised = agrinutri_data_get("coefN_mineralised"),
  coef_time = agrinutri_data_get("coef_time")
)
```

## Arguments

- Ntot:

  Total nitrogen content in the soil (g/kg, per mille).

- SOM:

  Soil organic matter content (%).

- soil.group:

  Soil group (e.g., "Sandy textures").

- CN:

  Carbon-to-nitrogen ratio.

- ccp:

  Crop category and planting period (e.g., "Autumn-winter crop \<150
  days").

- soil_seeding:

  Seeding mode, one of `"traditional"` (default) or `"no-till"`.

- crop:

  Optional crop name; used to check whether the no-till reduction
  applies to the crop. If `NULL`, the reduction applies to every crop.

- coefN_readily, coefN_mineralised, coef_time:

  Lookup tables.

## Value

A named list containing:

- b1: Readily available nitrogen (kg/ha), DPI B2 (0 for perennial crops
  in production).

- b2: Mineralized nitrogen from SOM (kg/ha), DPI B1.

- b1_potential: N pronto before the perennial rule (used by the leaching
  term).

- no_till_reduction: Reduction for no-till seeding (kg/ha).

- B: Total soil supply b1 + b2 - no_till_reduction (kg/ha).

- C_tempo: Time coefficient of the crop phase.

- units: The units of the output values ("kg/ha").

## Details

- b1 = `coef.N.readily` x min(Ntot, 2.1); it is counted only for crops
  with a time coefficient below 1 (cycle shorter than one year).
  Perennial crops in production (`C_tempo` = 1) use B = b2 only.

- b2 = `coef.N.mineralised` x min(SOM, 3) x `C_tempo`; the DPI keeps the
  mineralised N constant above 3 percent organic matter.

- With `soil_seeding = "no-till"` (semina su sodo) the soil supply is
  reduced by 10 kg N/ha, for crops where the DPI allows it
  (`crops.table$no_till_reduction`) and only when b1 is counted.

Total B = b1 + b2 - `no_till_reduction`.

## Examples

``` r
soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Loamy textures", CN = 7.7,
               ccp = "Spring-summer crop 100-130 days")
#> $b1
#> [1] 39
#> 
#> $b2
#> [1] 34.84
#> 
#> $b1_potential
#> [1] 39
#> 
#> $no_till_reduction
#> [1] 0
#> 
#> $B
#> [1] 73.84
#> 
#> $C_tempo
#> [1] 0.67
#> 
#> $units
#> [1] "kg/ha"
#> 
```
