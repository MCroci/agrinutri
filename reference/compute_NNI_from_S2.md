# End-to-end Nitrogen Nutrition Index pipeline from Sentinel-2 L2A

Combines the outputs of
[`estimate_biophysical`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md)
with a crop- specific critical-N dilution curve
([`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md))
to produce a pixel-level NNI map and the derived agronomic zones
(*deficient* / *optimal* / *excessive*) in a single call.

## Usage

``` r
compute_NNI_from_S2(
  lai_rast,
  cm_rast,
  cnc_rast,
  cnc_layer = c("CNC_Cprot", "CNC_Cab"),
  crop,
  params = NULL,
  fvc = NULL,
  scl = NULL,
  scl_keep = c(4L, 5L, 6L, 7L),
  nni_thresholds = c(0.9, 1.1),
  return_intermediates = TRUE
)
```

## Arguments

- lai_rast:

  SpatRaster or path to the LAI layer produced by
  [`estimate_biophysical`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md).

- cm_rast:

  SpatRaster or path to the Cm layer.

- cnc_rast:

  SpatRaster or path to the canopy N layer.

- cnc_layer:

  Character. Either `"CNC_Cprot"` (default) or `"CNC_Cab"`. Controls
  which conversion is applied.

- crop:

  Character. Crop name, resolved via
  [`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md).

- params:

  Optional list overriding the defaults returned by
  [`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md)
  (e.g. for locally calibrated `alpha_leaf` or `k_NChl`).

- fvc:

  A SpatRaster (or path) with fractional vegetation cover, optional. If
  provided the pipeline drops pixels with `FVC < params$fvc_min`.

- scl:

  A SpatRaster (or path) with the Sentinel-2 SCL layer, optional. Pixels
  not in `scl_keep` are masked.

- scl_keep:

  Integer vector of SCL classes to keep (default `c(4, 5, 6, 7)` =
  VEGETATION, NOT_VEGETATED, WATER, UNCLASSIFIED).

- nni_thresholds:

  Numeric length-2 vector with the lower and upper NNI thresholds
  (default `c(0.90, 1.10)`).

- return_intermediates:

  Logical. If `TRUE` the returned list also contains the intermediate W,
  N_total and N_actual rasters.

## Value

A named list of SpatRaster layers:

- `W` (t DM ha\\^{-1}\\) – aboveground biomass

- `N_actual` (pct DM) – plant N concentration

- `N_crit` (pct DM) – critical N from dilution curve

- `NNI` – Nitrogen Nutrition Index (dimensionless)

- `zones` – integer raster (1 deficient / 2 optimal / 3 excessive)

- `mask` – logical raster of retained pixels

Returned items are `NULL` when `return_intermediates = FALSE` for any
intermediate variable not requested.

## Details

The pipeline implements the classical Lemaire & Gastal (1997)
formulation: \$\$W\_{leaf} = LAI \cdot C_m \cdot 10^4 \quad (\mathrm{g\\
m^{-2}})\$\$ \$\$W = W\_{leaf} / \alpha\_{leaf} \quad (\mathrm{g\\
m^{-2}})\$\$ \$\$N\_{total} = k \cdot CNC\\Cab \quad \mathrm{or} \quad
N\_{total} = CNC\\Cprot\$\$ \$\$N\_{actual}(\\) = 100 \cdot N\_{total} /
W\$\$ \$\$N_c(\\) = a \cdot (W\_{tha})^{-b}\$\$ \$\$NNI = N\_{actual} /
N_c\$\$ where \\\alpha\_{leaf}\\ is the leaf-to-total aboveground
allocation coefficient and \\k\\ the N-to-chlorophyll ratio (both
crop-specific, see
[`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md)).
\\W\_{tha}\\ is W rescaled to t DM ha\\^{-1}\\.

Two N-content pathways are supported:

- **Protein path** (`cnc_layer = "CNC_Cprot"`, default). Uses the GPR
  retrieval trained on canopy N from protein content directly — the most
  internally consistent path, no extra coefficient is needed.

- **Chlorophyll path** (`cnc_layer = "CNC_Cab"`). Uses the canopy
  chlorophyll retrieval and multiplies it by a canopy-level N:Chl ratio
  \\k\\ (default ~55-60, requires local calibration — see
  [`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md)).
  Preferred only when CNC_Cab is the best-trained model for the target
  crop or when the calibration work has already been done.

## Masking

Two masks are applied before the NNI computation:

- If an `fvc` raster is supplied, pixels with
  `FVC < crop_params$fvc_min` are removed (default threshold 0.50).
  Below this level the BRDF is contaminated by the soil background and
  the GPR retrievals degrade.

- Pixels with W below `crop_params$w_min` are masked because the
  critical-N dilution curve is not defined at the seedling stage
  (default 1 t DM ha\\^{-1}\\).

Optional Sentinel-2 SCL (Scene Classification Layer) classes can be
dropped via `scl_keep` (vector of valid classes; defaults to the
standard vegetation-safe classes 4, 5, 6, 7 = VEGETATION, NOT_VEGETATED,
WATER, UNCLASSIFIED).

## Zones

The NNI is discretised into three classes following Lemaire & Gastal
(1997):

|           |                       |          |
|-----------|-----------------------|----------|
| **Zone**  | **NNI range**         | **Code** |
| Deficient | NNI \< 0.90           | 1        |
| Optimal   | 0.90 \<= NNI \<= 1.10 | 2        |
| Excessive | NNI \> 1.10           | 3        |

Thresholds are user-configurable via the `nni_thresholds` argument.

## References

Lemaire G, Gastal F. N uptake and distribution in plant canopies. In:
Diagnosis of the Nitrogen Status in Crops, Springer, 1997.

Houles V, Guerif M, Mary B. Elaboration of a nitrogen nutrition
indicator for winter wheat based on leaf area index and chlorophyll
content. Eur J Agron 2007;27:1-11.

## See also

[`estimate_biophysical`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md),
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md),
[`diagnose_N_status`](https://mcroci.github.io/agrinutri/reference/diagnose_N_status.md),
[`crop_params_NNI`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md),
[`variable_rate_N`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md)

## Examples

``` r
if (FALSE) { # \dontrun{
maps <- estimate_biophysical("scene.tif", "out",
  variables = c("LAI", "Cm", "CNC_Cprot", "FVC"),
  model_dir = "models_json")
nni <- compute_NNI_from_S2(
  lai_rast = maps$LAI,
  cm_rast  = maps$Cm,
  cnc_rast = maps$CNC_Cprot,
  cnc_layer = "CNC_Cprot",
  crop     = "maize",
  fvc      = maps$FVC
)
terra::writeRaster(nni$NNI,   "NNI.tif",   overwrite = TRUE)
terra::writeRaster(nni$zones, "zones.tif", overwrite = TRUE)
} # }
```
