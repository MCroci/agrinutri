# Nitrogen Rate Estimation from NDVI using Calibration

This function estimates nitrogen (N) application rates based on NDVI
values using either a two-point or three-point calibration method.

## Usage

``` r
estimate_N_rate_from_calibration_curve(
  raster,
  minN,
  maxN,
  meanN = NULL,
  calibration_type = "two-point",
  plot = FALSE
)
```

## Arguments

- raster:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  with NDVI values (the layer named `NDVI` is used if present, otherwise
  the first layer). Legacy `raster` objects are accepted and converted
  with
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html).

- minN:

  The minimum N rate (kg/ha) corresponding to the minimum NDVI.

- maxN:

  The maximum N rate (kg/ha) corresponding to the maximum NDVI.

- meanN:

  The mean N rate (kg/ha) corresponding to the mean NDVI (only used for
  three-point calibration).

- calibration_type:

  The type of calibration to perform: "two-point" or "three-point".
  Default is "two-point".

- plot:

  A logical value indicating whether to create plots (default is FALSE).

## Value

A single-layer
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with the estimated N rates based on the chosen calibration method.

## Examples

``` r
# Load example NDVI raster (replace with your own)
# ndvi_raster <- terra::rast(system.file("extdata/s2.tif", package = "agrinutri"))

# Two-point calibration
# n_rate_raster_2pt <- estimate_N_rate_from_calibration_curve(ndvi_raster, minN = 40, maxN = 60)

# Three-point calibration
# n_rate_raster_3pt <- estimate_N_rate_from_calibration_curve(ndvi_raster, minN = 40, meanN = 50,
# maxN = 60, calibration_type = "three-point")
```
