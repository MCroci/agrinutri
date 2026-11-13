# Nitrogen Nutrition Index (NNI)

Computes the Nitrogen Nutrition Index, the standard scalar indicator of
crop N status (Lemaire & Gastal 1997). NNI = N_actual / N_c, where
N_actual is the measured aboveground N concentration (% DM) and N_c is
the critical N concentration derived from the species-specific dilution
curve \\N_c = a \cdot W^{-b}\\.

## Usage

``` r
compute_NNI(N_content, biomass, crop, curve = NULL, is_percent = FALSE)
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

## Value

A numeric scalar / vector or a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
of NNI values.

## Details

Interpretation:

- NNI \< `deficient_threshold` (default 0.90): N-deficient

- `deficient_threshold` \<= NNI \<= `excessive_threshold` (0.90 to 1.10
  by default): optimal / balanced

- NNI \> `excessive_threshold` (default 1.10): luxury consumption /
  N-excess

All three arguments can be scalar, numeric vectors of the same length
(pixel-wise / plot-wise), or
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)s
aligned to the same grid. If any of them is a `SpatRaster`, the output
is a `SpatRaster`; otherwise a numeric vector is returned. Legacy
`raster` objects are accepted and converted with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html).

## References

Lemaire, G. & Gastal, F. (1997). N uptake and distribution in plant
canopies. In: Lemaire G. (ed.) Diagnosis of the Nitrogen Status in
Crops. Springer, Berlin.

Lemaire, G., Jeuffroy, M.-H., Gastal, F. (2008). Diagnosis tool for
plant and crop N status in vegetative stage: theory and practices for
crop N management. Eur. J. Agron. 28, 614-624.

## Examples

``` r
if (FALSE) { # \dontrun{
# Scalar: wheat at GS30, N% = 3.2, biomass = 2.5 t/ha
compute_NNI(N_content = 3.2, biomass = 2.5, crop = "wheat",
            is_percent = TRUE)
# ~ 0.94 -> slightly deficient

# Field-average maize at V8, N% = 2.8, biomass = 4 t/ha
compute_NNI(2.8, 4, crop = "maize", is_percent = TRUE)
# ~ 1.52 -> luxury consumption

# Raster (pixel-wise): N_content and biomass as SpatRasters
nni_map <- compute_NNI(N_content = n_map, biomass = w_map,
                       crop = "wheat", is_percent = TRUE)
} # }
```
