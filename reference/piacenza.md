# Piacenza plain example datasets (four fields, 2019-2026)

A small farm of the Po plain near Piacenza (Italy), used in the
vignettes and in the SoftwareX article on agrinutri. The four fields
were delineated from Sentinel-2; their crops were estimated from
satellite data for every year from 2019 to 2026 (2026 provisional). The
files are stored under `inst/extdata` and accessed with
[`system.file()`](https://rdrr.io/r/base/system.file.html):

## Details

- `extdata/piacenza_farm.geojson`: four fields (plots `P01` to `P04`,
  46.7 ha, EPSG:32632) with the crop class of each year (`c2019` to
  `c2026`), field-mean soil from the regional maps (`clay`, `sand` in
  percent; `olsen_value`, Olsen P in mg/kg with `olsen_unit = "P"`, and
  `k_value`, exchangeable K in mg/kg with `k_unit = "K"`, ready for
  `farm_balance(p_balance = TRUE, k_balance = TRUE)`) and every input of
  [`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md)
  for crop year 2024 (`crop`, `ccp`, `expected_yield_tons_ha`,
  `prev_crop`, `Ntot` in g/kg, `SOM` in percent, `CN`, rainfall from
  ERA5, no organic fertilisation).

- `extdata/piacenza_p01_rotation.csv`: the yearly inputs of plot `P01`
  from 2019 to 2026 (crop, crop-cycle class, previous crop, expected
  yield, October-January and February rainfall), to run the balance year
  by year.

- `extdata/sentinel-2/S2_piacenza_P01_20240813.tif`: Sentinel-2 Level-2A
  surface reflectance over plot `P01` on 13 August 2024 (10 bands, B02,
  B03, B04, B05, B06, B07, B08, B8A, B11, B12, 10 m; reflectance scaled
  by 10000, harmonised for processing baseline 04.00; pixels outside SCL
  classes 4-5 set to 0).

- `extdata/rer_soil_piacenza.tif`: the regional soil maps 0-30 cm on
  their 100 m grid (EPSG:7791) over the farm and 1.5 km around it, one
  layer each for `clay` and `sand` (percent), `corg` (organic carbon,
  percent), `ntot` (total N, g/kg), `olsen_p` (mg/kg P) and `k_exch`
  (mg/kg K).

## Sources

Soil maps: Regione Emilia-Romagna, Area Geologia, Suoli e Sismica, carte
dei suoli della Regione Emilia-Romagna, strato 0-30 cm (tessitura, 2nd
edition; dotazione in sostanza organica, 3rd edition; azoto totale,
fosforo assimilabile, potassio scambiabile), released under CC BY 4.0.
Sentinel-2: Copernicus Sentinel data 2024, processed by ESA, read from
the Microsoft Planetary Computer. Rainfall: ERA5 (Hersbach et al.,
2020). Yields: ISTAT, provincial statistics of Piacenza, or the
reference yields of the guidelines where missing.

## See also

[`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md),
[`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md),
[`estimate_biophysical()`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md),
[`build_strip_prescription()`](https://mcroci.github.io/agrinutri/reference/build_strip_prescription.md),
[`vignette("farm-and-prescription-map")`](https://mcroci.github.io/agrinutri/articles/farm-and-prescription-map.md)

## Examples

``` r
if (FALSE) { # \dontrun{
farm <- sf::st_read(system.file("extdata/piacenza_farm.geojson",
                                package = "agrinutri"), quiet = TRUE)
farm_balance(farm)[, c("plot", "crop", "N_target", "MAS_ok")]

soil <- terra::rast(system.file("extdata/rer_soil_piacenza.tif", package = "agrinutri"))
terra::plot(soil[["clay"]])
} # }
```
