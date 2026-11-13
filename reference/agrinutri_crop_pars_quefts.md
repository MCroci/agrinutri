# Map agrinutri crop label to QUEFTS crop parameters (backward-compatible)

Returns parameters for
[`Rquefts::quefts()`](https://rdrr.io/pkg/Rquefts/man/quefts.html). If
`crop_params` is already a full QUEFTS crop list, it is returned
unchanged. Otherwise this function calls
[`agrinutri_to_quefts_crop()`](https://mcroci.github.io/agrinutri/reference/agrinutri_to_quefts_crop.md)
using `inst/extdata/quefts_crop_pars_IT.csv`. If the crop is missing
from that table, it falls back to
[`Rquefts::quefts_crop()`](https://rdrr.io/pkg/Rquefts/man/quefts_crop.html)
with a coarse heuristic (requires **Rquefts**).

## Usage

``` r
agrinutri_crop_pars_quefts(crop_params)
```

## Arguments

- crop_params:

  Character crop description (e.g. from
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md))
  or a named list of QUEFTS crop parameters.

## Value

List compatible with `Rquefts::quefts(..., crop = crop_pars)`.

## See also

[`agrinutri_to_quefts_crop()`](https://mcroci.github.io/agrinutri/reference/agrinutri_to_quefts_crop.md)
