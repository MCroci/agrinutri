# Resolve a crop name (Italian or English) to its canonical entry

agrinutri reference tables (`uptake_table`, `mas.table`, `crops.table`,
`standard_pk_doses.table`) carry the canonical English crop names in the
column `crop` (since agrinutri 0.12.0), with the Italian translation in
`crop_it` and a duplicate of the English name in `crop_en` for backward
compatibility. This helper accepts any of the three forms
(case-insensitive, whitespace-normalised, exact match) and returns the
canonical English key used for joins downstream.

## Usage

``` r
resolve_crop(x, table = agrinutri_data_get("uptake_table"))
```

## Arguments

- x:

  Character. Crop name in Italian or English.

- table:

  Lookup table; default
  [`agrinutri::uptake_table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

Character. The canonical crop name (English, as in the `crop` column).

## Details

If the input matches none of the columns, the input is returned
unchanged together with a warning.

## Examples

``` r
resolve_crop("Durum wheat (grain)")
#> [1] "Durum wheat (grain)"
resolve_crop("Grano duro (granella)")
#> [1] "Durum wheat (grain)"
resolve_crop("Mais trinciato classe 700")
#> [1] "Silage maize (class 700)"
```
