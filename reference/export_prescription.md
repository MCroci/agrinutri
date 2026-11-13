# Export a variable-rate prescription map for farm machinery

Writes a prescription layer (an `sf` polygons object or a raster from
[`variable_rate_N`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md)
/
[`farm_balance`](https://mcroci.github.io/agrinutri/reference/farm_balance.md))
in one of the formats accepted by the on-board monitors of modern
tractors and sprayers. Supported formats: plain Shapefile, GeoJSON, KML,
GeoPackage, *John Deere-ready* Shapefile, *Trimble- ready* Shapefile and
ISOXML TASKDATA (ISOBUS ISO 11783-10).

## Usage

``` r
export_prescription(
  x,
  path,
  format = NULL,
  dose_field = NULL,
  area_min = 1,
  isoxml_opts = list()
)
```

## Arguments

- x:

  Input map. Either an `sf` polygons object (as returned by
  [`farm_balance`](https://mcroci.github.io/agrinutri/reference/farm_balance.md))
  or a `RasterLayer` / `SpatRaster` (as returned by
  [`variable_rate_N`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md)).
  Rasters are polygonised via
  [`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html)
  before export.

- path:

  For single-file formats, the output path (with the proper extension:
  `.shp`, `.geojson`, `.kml`, `.gpkg`). For ISOXML, the output
  **directory** (the `TASKDATA.XML` file will be created inside).

- format:

  Character. One of `"shp"`, `"geojson"`, `"kml"`, `"gpkg"`,
  `"johndeere"`, `"trimble"`, `"isoxml"`. Case-insensitive; if `NULL`,
  inferred from the file extension.

- dose_field:

  Character. Name of the numeric column carrying the N rate (kg N
  ha\\^{-1}\\). Defaults try `"N_target"`, `"dose"`, `"rate"` in that
  order.

- area_min:

  Numeric. Drop polygon slivers smaller than this area in square metres
  (default `1`).

- isoxml_opts:

  Named list with metadata used by `format = "isoxml"`: `task_name`,
  `field_name`, `crop`, `product`, `unit`, `ddi_code`. All optional,
  sensible defaults are applied.

## Value

Invisibly, the `sf` object actually written to disk (after projection to
WGS84, validity cleaning, field renaming and sliver removal).

## Manufacturer-specific conventions

- **John Deere**:

  WGS84 CRS, integer rate field named `RATE`, 8.3 DOS-safe file names.

- **Trimble**:

  WGS84 CRS, rate field named `TGT_RATE`, unique feature `ID`.

- **ISOXML**:

  Directory containing `TASKDATA.XML` following the ISOBUS ISO 11783-10
  standard (VRT zones with DDI 0006 = *application rate, mass per
  area*).

## See also

[`export_prescription_all`](https://mcroci.github.io/agrinutri/reference/export_prescription_all.md),
[`variable_rate_N`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md),
[`farm_balance`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)

## Examples

``` r
if (FALSE) { # \dontrun{
farm <- agrinutri::farm_balance(
  system.file("extdata/example_farm.geojson", package = "agrinutri"))

# Universal Shapefile
export_prescription(farm, "field_rx.shp")

# John Deere-ready Shapefile (integer RATE)
export_prescription(farm, "JD/field_rx.shp", format = "johndeere")

# ISOXML directory
export_prescription(farm, "TASKDATA", format = "isoxml",
  isoxml_opts = list(task_name = "N top-dress",
                      product = "Urea 46 pct",
                      unit = "kg/ha"))
} # }
```
