# Spatially-explicit Nitrogen Balance

Applies
[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
pixel-by-pixel to a set of soil-property rasters, returning one or more
raster layers with the spatially-resolved balance terms.

## Usage

``` r
spatial_N_balance(
  soil_stack,
  expected_yield_tons_ha,
  crop,
  ccp,
  oxygen_availability = "Normal",
  winter_rain,
  start_spring_rain,
  prev_crop,
  source = "Cattle slurry",
  fertorg_frequency = "every year",
  location = "Plain adjacent to urbanized areas",
  forg_quantity = 0,
  terms = c("A", "B", "C1", "C2", "D", "E", "F", "Forg", "G", "N_to_apply"),
  ...
)
```

## Arguments

- soil_stack:

  A
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
  whose layers encode the soil properties that vary in space (a legacy
  `raster` object is accepted and converted with
  [`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html)).
  Required layers (matched by name, case-insensitive):

  TN

  :   Total soil nitrogen, pct

  SOM

  :   Soil organic matter, pct

  Clay

  :   Clay content, pct

  Sand

  :   Sand content, pct

  CNratio

  :   Carbon-to-nitrogen ratio (dimensionless)

- expected_yield_tons_ha:

  Numeric scalar. Expected crop yield (t ha\\^{-1}\\).

- crop:

  Character. Crop name (Italian or English, see
  [`resolve_crop()`](https://mcroci.github.io/agrinutri/reference/resolve_crop.md)).

- ccp:

  Character. Crop calendar period.

- oxygen_availability:

  Character. Oxygen availability class (default `"Normal"`).

- winter_rain, start_spring_rain:

  Numeric scalars. Rainfall (mm).

- prev_crop:

  Character. Previous crop.

- source, fertorg_frequency, location, forg_quantity:

  Organic-fertilization parameters (see
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)).

- terms:

  Character vector of balance terms to return as layers in the output
  [`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html).
  Default
  `c("A", "B", "C1", "C2", "D", "E", "F", "Forg", "G", "N_to_apply")`.
  Use `"all"` to return every column of the
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
  output.

- ...:

  Additional arguments passed to
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md).

## Value

A
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
with one layer per requested balance term, at the same resolution,
extent and CRS as `soil_stack`.

## Details

Agronomic and climatic parameters that do not depend on location within
the field (yield target, crop, rainfall, previous crop, organic history)
are treated as scalars: the spatial variability of the balance is driven
exclusively by the soil-property rasters.

The function iterates over all non-NA cells. For a 96 \\\times\\ 101
raster (~10 000 pixels) the computation takes approximately one second
on a modern laptop.

## See also

[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md),
[`estimate_N_rate_from_holland_schepers()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_holland_schepers.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(terra)
ext <- system.file("extdata", package = "agrinutri")
soil <- terra::rast(c(
  file.path(ext, "Cremonesi_TN.tif"),
  file.path(ext, "Cremonesi_SOM.tif"),
  file.path(ext, "Cremonesi_Clay.tif"),
  file.path(ext, "Cremonesi_Sand.tif"),
  file.path(ext, "Cremonesi_CNratio.tif")
))
names(soil) <- c("TN", "SOM", "Clay", "Sand", "CNratio")

n_map <- spatial_N_balance(
  soil_stack = soil,
  expected_yield_tons_ha = 60,
  crop = "Mais trinciato (classe 700)",
  ccp  = "Spring-summer crop 100-130 days",
  oxygen_availability = "Normal",
  winter_rain = 160, start_spring_rain = 40,
  prev_crop = "Winter cereals straw removal",
  source = "Cattle slurry", fertorg_frequency = "every year",
  location = "Plain adjacent to urbanized areas",
  forg_quantity = 100
)
terra::plot(n_map[["N_to_apply"]])
} # }
```
