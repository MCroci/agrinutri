# agrinutri Package Data

Internal datasets used by the agrinutri package for nitrogen (and, from
v0.2.0, phosphorus and potassium) balance calculations following the
Disciplinari di Produzione Integrata (DPI) Emilia-Romagna (Allegato 2 -
metodo del bilancio, Allegati 3, 4, 6, 7, 9) and the FertDPI /
Fert_Office reference tool (v1.26, Febbraio 2026).

## Details

These datasets are loaded automatically with the package using
`LazyData: true` in the DESCRIPTION file. Soil texture is grouped in
three DPI classes: (1) Tendenzialmente sabbioso (S, SF, FS), (2) Franco
/ Medio impasto (L, F, FL, FSA, FA), (3) Tendenzialmente argilloso (FLA,
AS, AL, A). Tables with character keys retain the original Italian
naming used in Fert_Office; English aliases (`*_it` columns, or English
primary values) are provided where backward compatibility with earlier
agrinutri versions is required.

## Core N datasets

- uptake_table:

  Crop unit absorption/asportation coefficients for N, P2O5 and K2O
  (from foglio `A`). 247 crops in v0.2.0.

- e.table:

  Precessione: N kg/ha from previous crop residues, with legume flag and
  Italian alias.

- f.table:

  Coefficients of recovery for organic fertilisation applied in previous
  years (4 matrici x 4 frequenze = 16 rows).

- g.table:

  Annual N deposition (kg/ha) per location (3 rows).

- soil.table:

  USDA 12 soil classes mapped to DPI 3-group (ID_Rag).

- tri2.table:

  USDA soil texture triangle lookup (ID_Rag by clay/sand).

- tri3.table:

  Simplified USDA soil texture triangle lookup.

- ca.table:

  Oxygen availability -\> ID_Dre mapping.

- cb.table:

  Leaching C (kg/ha) and immobilization factor `fc_D` by ID_Rag x
  ID_Dre.

- coefN_readily:

  Coefficient for readily available N per soil group.

- coefN_mineralised:

  Mineralisation coefficient per soil group x C/N.

- coef_time:

  `C_tempo` time adjustment factors by phase x cycle; in v0.2.0 also
  carries DPI 2026 percentages for N, P2O5 and K2O allowed per phase,
  plus `advance_allowed` and `husbandry` flags.

- s2.rast:

  Example Sentinel-2 raster (5 bands) for vignettes, stored as a `terra`
  `PackedSpatRaster`. Unwrap with `terra::rast(s2.rast)` before use.

## DPI 2026 additional lookup tables (v0.2.0)

- mas.table:

  Maximum allowed doses (MAS) per crop (DPI 2026, RR 2/2024); includes
  standard N dose, MAS_N, max_increment, max_N_dose.

- crops.table:

  Crop master list with genus/species, N fixation % and
  `no_till_reduction` flag (from foglio `Coltura`).

- crop_groups.table:

  6 crop macro-groups: arboree, erbacee, foraggere, orticole, da_seme,
  baby_life.

- texture_groups.table:

  Texture grouping with `specific_weight`, P immobilisation factor and
  soil weight at 20/30/40/50 cm.

- so.table, so_max_input:

  SOM class (12) and maximum annual SO input (t ss/ha) per class.

- ph.table:

  Soil pH classes (7).

- total_carbonate.table, active_carbonate.table:

  Total and active carbonate classes for soil reactivity.

- p_availability.table, p_availability_meta:

  Olsen-P availability classes and P \<-\> P2O5 conversion + P
  immobilisation factor.

- k_availability.table:

  Exchangeable-K availability classes per texture grouping.

- fertilizer_types.table:

  Fertiliser type classification (11 classes).

- organic_fertilizers.table:

  21 organic matrices with ss, N, P2O5, K2O (min/avg/max), zootec flag,
  SO increment.

- efficiency.table:

  DPI 2026 organic N efficiency: ID_Rag x level x sector x dose (220
  rows).

- distribution_modalities.table:

  22 distribution modalities (epoch + technique).

- cycle_modality.table:

  Compatibility matrix crop-cycle x distribution modality x efficiency
  level.

- cycles.table, cycle_phases.table:

  Crop cycles (6) and phase-duration (17).

- c_d.table:

  Combined C (leaching) and fc_D (immobilisation) lookup (foglio C&D of
  Fert_Office v1.26).

## DPI 2026 Scheda-standard datasets (v0.3.0)

- standard_pk_doses.table:

  Base N, P2O5 and K2O standard doses per crop, with 4 dotation classes
  (Molto_Bassa, Bassa, Normale, Elevata) for P and K (239 rows, 14
  cols).

- standard_decrements.table:

  Crop-level catalogue of reduction factors (Rid_N_Resa, Ammendante
  precedente, SO elevato, Dopo medica/leguminosa, ecc.) for the scheda
  method.

- standard_increments.table:

  Crop-level catalogue of increment factors (Resa alta, SO basso,
  Ristoppio paglie, Surplus pluvio, Terreno compattato, ecc.) for the
  scheda method; includes inc_N_max, Inc_P2O5_Max, Inc_K2O_Max DPI 2026
  caps.

- standard_multicycle.table:

  Pluriennali and multi-cut specific data (I/II anno husbandry, inizio
  produzione, incremento per taglio by K dotation class).

- mineral_fertilizers.table:

  146 mineral / organo-mineral fertilisers from Fert_Office v1.26 foglio
  Concimi with N, P2O5, K2O titres (kg/q).

## Examples

``` r
library(agrinutri)
head(uptake_table)
#>   id crop_id                                              crop    N      P2O5
#> 1  1      A2  Kiwifruit (green flesh) - fruit, wood and leaves 0.59 0.1600000
#> 2  2     Ab2 Kiwifruit (yellow flesh) - fruit, wood and leaves 0.59 0.1600000
#> 3  3      A4   Apricot (medium yield) - fruit, wood and leaves 0.55 0.1300000
#> 4  4      A5     Apricot (high yield) - fruit, wood and leaves 0.55 0.1300000
#> 5  5      A6        Other fruit trees - fruit, wood and leaves 0.33 0.2838462
#> 6  6      A8                   Orange - fruit, wood and leaves 0.28 0.1300000
#>         K2O balance reference_yield std_N_demand std_P2O5_demand std_K2O_demand
#> 1 0.5900000      si              25        147.5            40.0          147.5
#> 2 0.5900000      si              30        177.0            48.0          177.0
#> 3 0.5300000      si              13         71.5            16.9           68.9
#> 4 0.5000000      si              18         99.0            23.4           90.0
#> 5 0.7411538      si              NA           NA              NA             NA
#> 6 0.3900000      si              30         84.0            39.0          117.0
#>   harvested_part                                           crop_en
#> 1         frutti  Kiwifruit (green flesh) - fruit, wood and leaves
#> 2         frutti Kiwifruit (yellow flesh) - fruit, wood and leaves
#> 3         frutti   Apricot (medium yield) - fruit, wood and leaves
#> 4         frutti     Apricot (high yield) - fruit, wood and leaves
#> 5         frutti        Other fruit trees - fruit, wood and leaves
#> 6         frutti                   Orange - fruit, wood and leaves
#>                                             crop_it
#> 1      Actinidia polpa verde frutti, legno e foglie
#> 2     Actinidia polpa gialla frutti, legno e foglie
#> 3 Albicocco media produzione frutti, legno e foglie
#> 4 Albicocco  alta produzione frutti, legno e foglie
#> 5           Altri fruttiferi frutti, legno e foglie
#> 6                    Arancio frutti, legno e foglie
head(mas.table)
#>   id group_id crop_id phase                                              crop
#> 1  1        1      A2    nd  Kiwifruit (green flesh) - fruit, wood and leaves
#> 2  2        2     Ab2    nd Kiwifruit (yellow flesh) - fruit, wood and leaves
#> 3  3        3      A4    nd   Apricot (medium yield) - fruit, wood and leaves
#> 4  4        4      A5    nd     Apricot (high yield) - fruit, wood and leaves
#> 5  5        5      A6    nd        Other fruit trees - fruit, wood and leaves
#> 6  6        6      A8    nd                   Orange - fruit, wood and leaves
#>   max_theoretical_N MAS_N reference_yield yield_unit product dry_or_irrigated
#> 1               340   150              25         tq    <NA>               no
#> 2               340   150              25         tq    <NA>               no
#> 3               340   135              13         tq    <NA>               no
#> 4               340   135              13         tq    <NA>               no
#> 5               340    NA              NA         nd      nd               no
#> 6               340    NA              NA         nd      nd               no
#>   reference_yield_t_ha dry_matter_pct standard_yield standard_N max_increment
#> 1                   25             NA             25        120            40
#> 2                   25             NA             30        150            40
#> 3                   13             NA             13         75            50
#> 4                   13             NA             18        100            50
#> 5                    0             NA             NA         NA             0
#> 6                    0             NA             30        120            50
#>   max_N_dose         note                                           crop_en
#> 1        160 RR n. 2/2024  Kiwifruit (green flesh) - fruit, wood and leaves
#> 2        190 RR n. 2/2024 Kiwifruit (yellow flesh) - fruit, wood and leaves
#> 3        125 RR n. 2/2024   Apricot (medium yield) - fruit, wood and leaves
#> 4        150 RR n. 2/2024     Apricot (high yield) - fruit, wood and leaves
#> 5         NA         <NA>        Other fruit trees - fruit, wood and leaves
#> 6        170 RR n. 2/2024                   Orange - fruit, wood and leaves
#>                                             crop_it
#> 1      Actinidia polpa verde frutti, legno e foglie
#> 2     Actinidia polpa gialla frutti, legno e foglie
#> 3 Albicocco media produzione frutti, legno e foglie
#> 4 Albicocco  alta produzione frutti, legno e foglie
#> 5           Altri fruttiferi frutti, legno e foglie
#> 6                    Arancio frutti, legno e foglie
head(p_availability.table)
#>   ID_Gri_P min_P_ppm max_P_ppm min_P2O5_ppm max_P2O5_ppm    rating
#> 1        1         0         5         0.00        11.45  very low
#> 2        2         5        10        11.45        22.90       low
#> 3        3        10        15        22.90        34.35    medium
#> 4        4        15        30        34.35        68.70      high
#> 5        5        30       999        68.70      2287.71 very high
#>        rating_it        class
#> 1    molto bassa molto scarso
#> 2          bassa       scarso
#> 3          media      normale
#> 4        elevata      normale
#> 5  molto elevata   molto alto
head(k_availability.table)
#>   ID_Gri_K          group      group_it min_K_ppm max_K_ppm min_K2O_ppm
#> 1        1 Sandy textures      Sabbiosi         0        40           0
#> 2        2 Sandy textures      Sabbiosi        40        80          48
#> 3        3 Sandy textures      Sabbiosi        80       120          96
#> 4        4 Sandy textures      Sabbiosi       120       999         144
#> 5        5 Loamy textures Medio impasto         0        60           0
#> 6        6 Loamy textures Medio impasto        60       100          72
#>   max_K2O_ppm   rating   rating_it ID_Dot_K
#> 1        48.0 very low molto bassa        1
#> 2        96.0      low       bassa        2
#> 3       144.0   medium       media        3
#> 4      1198.8     high     elevata        4
#> 5        72.0 very low molto bassa        1
#> 6       120.0      low       bassa        2
head(organic_fertilizers.table)
#>   ID_F_org                                  fertilizer
#> 1        1                                     compost
#> 2        2 Whole digestate (biomass / cattle effluent)
#> 3        3       Whole digestate (mostly pig effluent)
#> 4        4   Whole digestate (mostly poultry effluent)
#> 5        5                Clarified digestate fraction
#> 6        6                    Solid digestate fraction
#>                                    fertilizer_it sector_id type_id min_dm
#> 1                                        compost       ind       3     65
#> 2     Digestato t.q. biomasse o con effl. bovini    dig_tq       7     20
#> 3      Digestato t.q. con prevalenza effl. Suini   dig_sui       7     20
#> 4 Digestato t.q. con prevalenza di effl. avicoli   dig_avi       7     20
#> 5                Digestato frazione chiarificata   dig_chi       7      2
#> 6                    Digestato frazione palabile   dig_pal       2     30
#>   max_dm avg_dm min_N max_N avg_N min_P2O5 max_P2O5 avg_P2O5 min_K2O max_K2O
#> 1     65     65    12    12    12        9        9        9      10      10
#> 2     24     22     3     9     6        4        4        4       4      10
#> 3     24     22     3     9     6        4        4        4       4      10
#> 4     24     22     3     9     6        4        4        4       4      10
#> 5      6      4     6    10     8        3        3        3       4      10
#> 6     40     35     2     8     5        5        5        5       4      10
#>   avg_K2O fully_zootec SO_increment
#> 1      10        FALSE            1
#> 2       7        FALSE            0
#> 3       7        FALSE            0
#> 4       7        FALSE            0
#> 5       7        FALSE            0
#> 6       7        FALSE            1
```
