# CERZOO example datasets (real field, ready to test the functions)

agrinutri ships a small, real-world example from the CERZOO experimental
farm of the Universita Cattolica del Sacro Cuore (Po Valley, Piacenza,
Italy) so that users can run the full pipeline on actual data out of the
box. The files are stored under `inst/extdata` and accessed with
[`system.file()`](https://rdrr.io/r/base/system.file.html):

## Details

- `extdata/cerzoo_field.geojson`: field boundaries of the CERZOO farm
  with the agronomic attributes used by
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
  and
  [`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)
  (crop, expected yield, sand, clay, SOM, C/N, previous crop). Field
  `id = 3` is the case-study silage-maize plot (3.24 ha, 37 percent
  clay, 16.8 percent sand, 1.74 percent organic matter, C/N 8.84).

- `extdata/sentinel-2/S2_cerzoo_field3_20240813.tif`: Sentinel-2
  Level-2A surface-reflectance subset (10 bands, canonical order B02,
  B03, B04, B05, B06, B07, B08, B8A, B11, B12) cropped and masked to
  CERZOO Field 3 for the acquisition of 13 August 2024.

The raster stores digital-number reflectance scaled by 10000 (use
`scale_factor = 10000` in
[`compute_vi()`](https://mcroci.github.io/agrinutri/reference/compute_vi.md)).

## See also

[`compute_vi()`](https://mcroci.github.io/agrinutri/reference/compute_vi.md),
[`build_strip_prescription()`](https://mcroci.github.io/agrinutri/reference/build_strip_prescription.md),
[`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md),
[`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)

## Examples

``` r
if (FALSE) { # \dontrun{
field <- sf::st_read(system.file("extdata/cerzoo_field.geojson",
                                 package = "agrinutri"), quiet = TRUE)
field3 <- field[field$id == 3, ]

s2   <- terra::rast(system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif",
                                package = "agrinutri"))
ndvi <- compute_vi(s2, "NDVI", scale_factor = 10000)

rx <- build_strip_prescription(
  field3, machine_width = 24, cell_length = 30,
  variability = "calibration", vi_raster = ndvi,
  vi_low = 0.35, vi_high = 0.80,
  n_target = 200, min_dose = 165, max_dose = 235)
} # }
```
