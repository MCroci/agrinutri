# Empirical NNI from a vegetation index (no GPR models required)

Alternative to the GPR-based
[`compute_NNI_from_S2`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md)
pipeline that lets the user derive a Nitrogen Nutrition Index map
directly from a single vegetation index raster (NDRE, NDVI, or a
red-edge chlorophyll index) using a published crop-specific empirical
regression. The approach is less physically rigorous than the
PROSAIL-trained GPR pipeline but does not require any model files and
runs on a single band ratio.

## Usage

``` r
nni_from_vi_empirical(
  vi_raster,
  index = c("NDRE", "NDVI", "CIred_edge"),
  crop = "wheat",
  slope = NULL,
  intercept = NULL,
  nni_range = c(0.5, 1.5),
  nni_thresholds = c(0.9, 1.1)
)
```

## Arguments

- vi_raster:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  with a normalised vegetation index (dimensionless, typically 0-1).
  Legacy `raster` objects are accepted and converted with
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html).

- index:

  Character. The vegetation index used. One of `"NDRE"`, `"NDVI"`,
  `"CIred_edge"`.

- crop:

  Character. One of `"wheat"`, `"maize"`, `"rice"`, `"barley"`.
  Case-insensitive; Italian aliases ("frumento", "mais", "orzo") are
  accepted.

- slope, intercept:

  Optional numeric overrides for the linear regression
  `NNI = slope * VI + intercept`. Both must be supplied together.

- nni_range:

  Numeric length-2 vector giving the clipping range for the output
  (default `c(0.5, 1.5)`).

- nni_thresholds:

  Numeric length-2 vector with the lower and upper NNI thresholds for
  zone classification (default `c(0.90, 1.10)`).

## Value

A named list with two
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects: `NNI` (continuous) and `zones` (integer 1 / 2 / 3 for deficient
/ optimal / excessive).

## Details

The default equations ship as a lookup table tied to `index` and `crop`.
They reproduce the commonly cited regressions of Cao et al. (2013) for
rice (NDRE), Cilia et al. (2014) and Magney et al. (2017) for wheat
(NDRE), Li et al. (2014) for maize (Cired-edge), Fitzgerald et al.
(2010) for wheat (NDVI). They are linear in the vegetation index:
\$\$NNI = a \cdot VI + b\$\$ Users are strongly encouraged to replace
`a` and `b` with locally calibrated values (via `slope` and `intercept`
arguments) whenever a ground-truth dataset is available. NNI is clipped
to a user-configurable range (default 0.5-1.5).

## References

Cao Q, Miao Y, Wang H, Huang S, Cheng S, Khosla R, Jiang R.
Non-destructive estimation of rice plant nitrogen status with Crop
Circle multispectral active canopy sensor. Field Crops Res
2013;154:133-144.

Fitzgerald G, Rodriguez D, O'Leary G. Measuring and predicting canopy
nitrogen nutrition in wheat using a spectral index - The canopy
chlorophyll content index (CCCI). Field Crops Res 2010;116:318-324.

## See also

[`compute_NNI_from_S2`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md)
for the rigorous PROSAIL + GPR pipeline;
[`compute_vi`](https://mcroci.github.io/agrinutri/reference/compute_vi.md)
for index computation from raw bands.

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)
ndre <- rast("ndre.tif")
out  <- nni_from_vi_empirical(ndre, index = "NDRE", crop = "wheat")
terra::plot(out$NNI)
} # }
```
