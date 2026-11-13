# Build QUEFTS biomass list from agrinutri state and Sentinel-2 NNI

Translates expected yield and per-pixel NNI into QUEFTS attainable
biomass partitioning. NNI scales attainable storage biomass between a
stressed and near-potential state.

## Usage

``` r
agrinutri_to_quefts_biom(
  expected_yield_tons_ha,
  NNI,
  crop_pars,
  leaf_to_store_ratio = 0.42
)
```

## Arguments

- expected_yield_tons_ha:

  Numeric. Expected attainable yield (t/ha).

- NNI:

  Numeric vector or scalar. Nitrogen Nutrition Index (typical range near
  0.5–1.1).

- crop_pars:

  Named list returned by
  [`agrinutri_to_quefts_crop()`](https://mcroci.github.io/agrinutri/reference/agrinutri_to_quefts_crop.md).

- leaf_to_store_ratio:

  Numeric. Leaf:store DM ratio for cereals. Default 0.42.

## Value

If `NNI` has length 1, a single list with `leaf_att`, `stem_att`,
`store_att`, `SeasonLength`. If `NNI` has length \> 1, a list of such
lists (one per element).
