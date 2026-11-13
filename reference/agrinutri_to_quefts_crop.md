# Translate agrinutri crop name into QUEFTS crop parameters

Looks up QUEFTS crop parameters in the bundled `quefts_crop_pars_IT.csv`
table. Crop names follow agrinutri / English DPI-style labels (e.g.
`"Durum wheat (whole plant)"`, `"Grano duro (granella)"`).

## Usage

``` r
agrinutri_to_quefts_crop(crop, crop_pars_path = NULL)
```

## Arguments

- crop:

  Character. Crop name as accepted by
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md).

- crop_pars_path:

  Character. Optional path to a custom CSV. If `NULL`, the bundled file
  under `inst/extdata` is used.

## Value

A named list with elements suitable for
[`Rquefts::quefts()`](https://rdrr.io/pkg/Rquefts/man/quefts.html) as
the `crop` argument (`NminVeg`, `NmaxVeg`, `NminStore`, ...,
`SeasonLength`).
