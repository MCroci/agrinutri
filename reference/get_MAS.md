# Maximum Allowed Doses (MAS) per DPI Emilia-Romagna

Returns or checks the Maximum Allowed Doses (MAS) of nitrogen for a
crop, as defined in the Emilia-Romagna Integrated Production Guidelines
(DPI) (Annex 9, Regional Regulation 2/2024). In ZVN the values are
binding; they can be exceeded if production over 3 years exceeds the
reference yield.

## Usage

``` r
get_MAS(crop = NULL, mas_table = NULL, edition = c("2026", "2025"))
```

## Arguments

- crop:

  Character. Crop name, as in `uptake_table$crop`; matching is case- and
  accent-insensitive. With `edition = "2025"` use the crop labels of
  that table. Use `get_MAS()` to list all crops.

- mas_table:

  Optional data frame with at least columns `crop` and `mas_N` (and
  optionally `crop_it`, `crop_en`). If NULL, uses the built-in table for
  the chosen `edition`.

- edition:

  Character. `"2026"` (default; DPI 2026 / Fert_Office v1.26, Regional
  Regulation 2/2024) or `"2025"` (DPI 2025 guide, ZVN table, 17 crops).

## Value

For `get_MAS(crop)`: a one-row data frame with columns `crop`,
`crop_it`, `crop_en`, `phase`, `mas_N` (kg N/ha; `NA` when the DPI sets
no MAS), `reference_yield` (t/ha), `max_theoretical_N`, `standard_N`,
`max_N_dose` and `note` (edition 2026), or all rows if `crop` is NULL.
For `check_MAS`: a list with `ok` (logical), `mas_N`, `N_planned`,
`message`.

## Details

The DPI 2026 values (default) are read from the bundled
[mas.table](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)
dataset, which mirrors the MAS sheet of Fert_Office v1.26 (234 crops).

## References

DPI Emilia-Romagna - General Rules 2025, Annex 9; guide to mineral and
organic fertilisation 2025 (N, P, K). Regional Regulation 2/2024. DPI
2026, FertDPI / Fert_Office_v1_26.

## Examples

``` r
get_MAS("Durum wheat (grain)")
#>                   crop               crop_it             crop_en phase mas_N
#> 49 Durum wheat (grain) Grano duro (granella) Durum wheat (grain)    nd   190
#>    reference_yield max_theoretical_N standard_N max_N_dose         note
#> 49               6               340        160        200 RR n. 2/2024
get_MAS("Silage maize (class 700)")$mas_N
#> [1] 280
get_MAS("Frumento tenero (granella)", edition = "2025")  # soft wheat, ZVN 2025 table
#>                         crop mas_N reference_yield    type
#> 1 Frumento tenero (granella)   180             6.5 Erbacee
head(get_MAS())  # full table
#>                                                crop
#> 1  Kiwifruit (green flesh) - fruit, wood and leaves
#> 2 Kiwifruit (yellow flesh) - fruit, wood and leaves
#> 3   Apricot (medium yield) - fruit, wood and leaves
#> 4     Apricot (high yield) - fruit, wood and leaves
#> 5        Other fruit trees - fruit, wood and leaves
#> 6                   Orange - fruit, wood and leaves
#>                                             crop_it
#> 1      Actinidia polpa verde frutti, legno e foglie
#> 2     Actinidia polpa gialla frutti, legno e foglie
#> 3 Albicocco media produzione frutti, legno e foglie
#> 4 Albicocco  alta produzione frutti, legno e foglie
#> 5           Altri fruttiferi frutti, legno e foglie
#> 6                    Arancio frutti, legno e foglie
#>                                             crop_en phase mas_N reference_yield
#> 1  Kiwifruit (green flesh) - fruit, wood and leaves    nd   150              25
#> 2 Kiwifruit (yellow flesh) - fruit, wood and leaves    nd   150              25
#> 3   Apricot (medium yield) - fruit, wood and leaves    nd   135              13
#> 4     Apricot (high yield) - fruit, wood and leaves    nd   135              13
#> 5        Other fruit trees - fruit, wood and leaves    nd    NA              NA
#> 6                   Orange - fruit, wood and leaves    nd    NA              NA
#>   max_theoretical_N standard_N max_N_dose         note
#> 1               340        120        160 RR n. 2/2024
#> 2               340        150        190 RR n. 2/2024
#> 3               340         75        125 RR n. 2/2024
#> 4               340        100        150 RR n. 2/2024
#> 5               340         NA         NA         <NA>
#> 6               340        120        170 RR n. 2/2024
check_MAS("Grain maize 500-700 (grain)", 250)
#> $ok
#> [1] TRUE
#> 
#> $mas_N
#> [1] 280
#> 
#> $N_planned
#> [1] 250
#> 
#> $message
#> [1] "Planned N is within MAS."
#> 
check_MAS("Durum wheat (grain)", 210)  # over MAS
#> $ok
#> [1] FALSE
#> 
#> $mas_N
#> [1] 190
#> 
#> $N_planned
#> [1] 210
#> 
#> $message
#> [1] "Planned N (210 kg/ha) exceeds MAS (190 kg/ha)."
#> 
```
