# Convert GPR biophysical outputs into NNI inputs (low-level helper)

Low-level helper that turns `LAI`, `Cm` and a canopy-N raster into the
two layers consumed by
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md):
the aboveground dry biomass `W` (t DM ha\\^{-1}\\) and the plant N
concentration `N_actual` (pct DM).

## Usage

``` r
biophysical_to_NNI_inputs(
  lai_rast,
  cm_rast,
  cnc_rast,
  alpha_leaf = 0.35,
  k_NChl = NULL,
  w_min = 1
)
```

## Arguments

- lai_rast:

  RasterLayer or terra SpatRaster with leaf area index.

- cm_rast:

  RasterLayer or terra SpatRaster with leaf dry-matter content (g
  cm\\^{-2}\\).

- cnc_rast:

  RasterLayer or terra SpatRaster with canopy nitrogen: either
  `CNC_Cprot` (g N m\\^{-2}\\, protein path) or `CNC_Cab` (g Chl
  m\\^{-2}\\, chlorophyll path - in that case supply `k_NChl`).

- alpha_leaf:

  Leaf-to-total aboveground biomass allocation coefficient (default
  0.35; use
  [`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md)
  for crop-specific values).

- k_NChl:

  When `cnc_rast` contains CNC_Cab (g Chl m\\^{-2}\\), the canopy-level
  N:Chl ratio used to convert it to g N m\\^{-2}\\ (default `NULL` =
  protein path, no conversion).

- w_min:

  Minimum biomass (t DM ha\\^{-1}\\) below which pixels are masked
  (default 1.0).

## Value

A named list with two SpatRaster layers, `W` and `N_actual`, ready to be
passed to
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md).

## Details

Most users should rather call the end-to-end
[`compute_NNI_from_S2`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md)
wrapper, which handles crop-specific parameters, FVC / SCL masking and
zone classification in a single call. This function is exposed for
advanced workflows that need direct control over the conversion.

The conversions follow \$\$W\_{leaf}\\ (\mathrm{g\\ m^{-2}}) = LAI \cdot
C_m \cdot 10^4\$\$ \$\$W\\ (\mathrm{t\\ DM\\ ha^{-1}}) = W\_{leaf} /
(100 \cdot \alpha\_{leaf})\$\$ (leaf-to-total aboveground allocation
coefficient \\\alpha\_{leaf}\\, ~0.30-0.45 depending on crop and
phenology), and \$\$N\_{actual}(\\ DM) = 100 \cdot N\_{total} /
W\_{leaf} \cdot \alpha\_{leaf}^{-1}\$\$ with \\N\_{total}\\ either equal
to `CNC_Cprot` (g N m\\^{-2}\\) or `k * CNC_Cab` when the chlorophyll
path is used. Pixels where `W < w_min` are set to `NA` because the
critical-N dilution curve is not defined below that biomass.

## See also

[`compute_NNI_from_S2`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md),
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md),
[`estimate_biophysical`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md),
[`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md)
