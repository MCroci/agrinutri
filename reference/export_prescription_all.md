# Export a prescription map in many formats at once

Convenience wrapper around
[`export_prescription`](https://mcroci.github.io/agrinutri/reference/export_prescription.md)
that writes several formats side-by-side into the same output directory.

## Usage

``` r
export_prescription_all(
  x,
  output_dir,
  basename = "prescription",
  formats = c("shp", "geojson", "kml", "gpkg", "johndeere", "trimble", "isoxml"),
  dose_field = NULL,
  area_min = 1,
  isoxml_opts = list()
)
```

## Arguments

- x:

  Input map (`sf` or raster, see
  [`export_prescription`](https://mcroci.github.io/agrinutri/reference/export_prescription.md)).

- output_dir:

  Directory where the files are written (created if missing).

- basename:

  File name stem (without extension); defaults to `"prescription"`.

- formats:

  Character vector. Any subset of
  `c("shp", "geojson", "kml", "gpkg", "johndeere", "trimble", "isoxml")`.
  Default: all seven.

- dose_field, area_min, isoxml_opts:

  Passed through to
  [`export_prescription`](https://mcroci.github.io/agrinutri/reference/export_prescription.md).

## Value

Invisibly, a named list of file paths written (one entry per format).

## See also

[`export_prescription`](https://mcroci.github.io/agrinutri/reference/export_prescription.md)

## Examples

``` r
if (FALSE) { # \dontrun{
farm <- agrinutri::farm_balance(
  system.file("extdata/example_farm.geojson", package = "agrinutri"))
export_prescription_all(farm, "rx_maps", "farm_2026",
  formats = c("shp", "geojson", "isoxml", "johndeere"))
} # }
```
