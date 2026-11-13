# Diagnose crop N status from biomass and N content (NNI classes)

Wraps
[`compute_NNI`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md)
and turns continuous NNI values into three discrete classes used for
fertilisation diagnosis and for diagnostic maps in variable-rate
applications.

## Usage

``` r
diagnose_N_status(
  N_content,
  biomass,
  crop,
  curve = NULL,
  is_percent = FALSE,
  deficient_threshold = 0.9,
  excessive_threshold = 1.1
)
```

## Arguments

- N_content:

  Aboveground N concentration as a fraction of DM (e.g. 0.025 = 2.5pct)
  **or** percentage DM (pass `is_percent = TRUE`).

- biomass:

  Aboveground dry biomass in t DM / ha (**tonnes**).

- crop:

  Crop identifier, passed to
  [`critical_N_curve`](https://mcroci.github.io/agrinutri/reference/critical_N_curve.md).

- curve:

  Optional list with `a` and `b` (and optionally `W_min`) to override
  the default curve. Useful for custom local calibration.

- is_percent:

  Logical. Is `N_content` supplied as a percentage (e.g. 2.5 for 2.5pct)
  rather than a fraction? Default `FALSE` (fraction). Auto-detected and
  warned if values \> 1.

- deficient_threshold:

  Lower bound of the optimal NNI band. Default 0.90.

- excessive_threshold:

  Upper bound of the optimal NNI band. Default 1.10.

## Value

A list with:

- `NNI`:

  Continuous NNI (numeric or SpatRaster).

- `class`:

  Integer class (1/2/3) or SpatRaster of classes.

- `labels`:

  Character labels matching `class`.

- `summary`:

  Counts / fractions per class (rasters only).

- `thresholds`:

  The thresholds used.

- `curve`:

  The critical-N curve parameters.

## Details

Class codes (integer factor levels):

1.  **1 - deficient**: NNI \< `deficient_threshold` (default 0.90)

2.  **2 - optimal**: `deficient_threshold` \<= NNI \<=
    `excessive_threshold` (default 1.10)

3.  **3 - excessive**: NNI \> `excessive_threshold`

The class raster can be fed straight into variable-rate logic: e.g.
apply the full agronomic dose only where class = 1 or 2, zero dose where
class = 3.

## Examples

``` r
if (FALSE) { # \dontrun{
# Scalar diagnosis
diagnose_N_status(N_content = 2.8, biomass = 4,
                  crop = "maize", is_percent = TRUE)

# Pixel-wise diagnosis
d <- diagnose_N_status(N_content = n_raster, biomass = w_raster,
                       crop = "wheat", is_percent = TRUE)
terra::plot(d$class)
d$summary
} # }
```
