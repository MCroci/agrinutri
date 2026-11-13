# Build an agrinutri soil input stack from SoilGrids (open global default)

Downloads the soil properties that the agrinutri nitrogen balance
consumes from the ISRIC SoilGrids 2.0 service and returns them as a
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with the layer names, units and shape that
[`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md)
and
[`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)
expect. It is the open, global fallback soil layer: with it the whole
agrinutri pipeline (balance, prescription mean and uncertainty) runs end
to end on freely licensed data (CC-BY 4.0) anywhere on Earth, without a
proprietary local soil map.

## Usage

``` r
soilgrids_input(
  aoi,
  depths = c("0-5", "5-15", "15-30"),
  crs_out = NULL,
  template = NULL,
  uncertainty = FALSE,
  buffer = 500
)
```

## Arguments

- aoi:

  Area of interest: an `sf`/`sfc` object, a
  [`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html),
  or a path to a vector file readable by
  [`terra::vect`](https://rspatial.github.io/terra/reference/vect.html).
  Its extent (buffered) is downloaded.

- depths:

  Character vector of SoilGrids depth intervals to combine into a
  thickness-weighted topsoil value. Defaults to the 0 to 30 cm topsoil
  (`c("0-5", "5-15", "15-30")`). Accepted: "0-5", "5-15", "15-30",
  "30-60", "60-100", "100-200".

- crs_out:

  Target coordinate reference system for the returned stack (anything
  [`terra::crs`](https://rspatial.github.io/terra/reference/crs.html)
  accepts). Defaults to the CRS of `aoi` (or of `template` when
  supplied).

- template:

  Optional
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  whose grid the output is resampled to (for alignment with a field
  raster). Note that resampling a 250 m product to a finer grid does not
  add spatial detail.

- uncertainty:

  Logical; if `TRUE`, also download the Q0.05 and Q0.95 quantiles and
  append per-property standard-deviation layers
  (`Clay_sd, Sand_sd, TN_sd, SOM_sd`, approximated as (Q0.95 - Q0.05) /
  3.29 in converted units) for use as the input error of a Monte-Carlo
  propagation.

- buffer:

  Numeric buffer (in metres) added around the AOI extent before
  cropping, so edge pixels are not lost. Default 500.

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with layers `TN` (g/kg), `SOM` (percent), `Clay` (percent), `Sand`
(percent) and `CNratio` (dimensionless), masked to `aoi` and in
`crs_out`; plus the four `*_sd` layers when `uncertainty = TRUE`. The
result is ready to pass as the `soil_stack` argument of
[`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md).

## Details

SoilGrids is a 250 m global product with modest local accuracy (global
cross-validation model efficiency about 0.5 for total nitrogen and 0.65
for organic carbon), so it drives the field-mean regulatory dose and the
farm total, not the within-field 10 m pattern. Treat it as an open
default and a benchmark for the value of local sampling, not as a
validated field input.

Unit conversions applied to the raw SoilGrids values (as returned by
`geodata`): clay and sand from g/kg to percent (divide by 10); total
nitrogen from cg/kg to g/kg (divide by 100); organic carbon from dg/kg
to g/kg (divide by 10); soil organic matter as organic-carbon percent
times 1.724; the carbon-to-nitrogen ratio as organic carbon over total
nitrogen (both in g/kg).

## Attribution

SoilGrids data are released under CC-BY 4.0. Cite Poggio et al. (2021),
SoilGrids 2.0, SOIL 7, 217-240,
[doi:10.5194/soil-7-217-2021](https://doi.org/10.5194/soil-7-217-2021) .

## See also

[`spatial_N_balance`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md),
[`farm_balance`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)

## Examples

``` r
if (FALSE) { # requireNamespace("geodata", quietly = TRUE) && interactive()
aoi <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "agrinutri"))
soil <- soilgrids_input(aoi, crs_out = 32632)
n <- spatial_N_balance(soil, expected_yield_tons_ha = 9,
                       crop = "Grano tenero FF (granella)",
                       ccp = "Spring-summer crop 100-130 days",
                       winter_rain = 150, start_spring_rain = 0,
                       prev_crop = "Maize stalks buried")
}
```
