# agrinutri

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24202414.svg)](https://doi.org/10.5281/zenodo.24202414)

**Nutrient balances and variable-rate fertilisation planning, from the
field to the farm**

## Overview

`agrinutri` is an R package for nitrogen, phosphorus and potassium
fertilisation planning of field and tree crops with nutrient balance
methods. Every coefficient is an editable data table, so the balance can
be re-parameterised for other regional guidelines. The default
parameterisation implements the balance method (Annex 2) and the
standard-dose method of the Emilia-Romagna Integrated Production
Guidelines (*Disciplinari di Produzione Integrata*, DPI 2026) and
follows the regional reference tool **Fert_Office v1.26**. On top of the
regulatory balance it provides farm and pixel-level balances, a
Sentinel-2 remote-sensing diagnosis (vegetation indices,
Gaussian-process canopy traits, Nitrogen Nutrition Index) and
variable-rate prescriptions that keep the field mean equal to the
compliant balance dose, exported to tractor formats.

All coefficient tables are ordinary R datasets (`uptake_table`,
`mas.table`, `coef_time`, …), so the balance can be inspected, versioned
and re-parameterized for other guidelines.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("mcroci/agrinutri")
```

R \>= 4.0. The only hard dependency is `terra`; spatial, remote-sensing,
QUEFTS and Shiny features use optional packages (`sf`, `jsonlite`,
`Rquefts`, `shiny`, …).

## Quick start

Durum wheat, 6 t/ha, on a silt-loam soil (the sample field of
Fert_Office v1.26):

``` r

library(agrinutri)

bal <- N_balance(
  expected_yield_tons_ha = 6, crop = "Grano duro (pianta intera)",
  ccp = "Spring-summer crop 100-130 days",
  sand = 15.5, clay = 18.5, Ntot = 1.5, SOM = 2, CN = 7.73,
  oxygen_availability = "Slow", winter_rain = 150, start_spring_rain = 0,
  prev_crop = "Maize stalks removed", source = "None",
  location = "Isolated plain", forg_quantity = 0)

bal[c("A", "B", "C1", "C2", "D", "E", "F", "G")]   # every balance term
calculate_N_fertilization(bal)                      # 142.246 kg N/ha
check_MAS("Grano duro (pianta intera)", 142)        # MAS 190 kg N/ha: ok

P_balance(6, "Grano duro (pianta intera)", olsen_value = 15, olsen_unit = "P2O5",
          clay = 18.5, sand = 15.5, total_carbonate = 15)$P2O5_required  # 112.9
K_balance(6, "Grano duro (pianta intera)", k_value = 150, k_unit = "K2O",
          clay = 18.5, sand = 15.5)$K2O_required                         # 139.4
```

Crop names are accepted in Italian (Fert_Office labels) or English
([`list_crops()`](https://mcroci.github.io/agrinutri/reference/list_crops.md)).

A whole farm, from a vector layer with one row per plot:

``` r

farm <- sf::st_read(system.file("extdata/example_farm.geojson", package = "agrinutri"))
farm_balance(farm)[, c("plot_id", "crop", "N_target", "MAS_ok", "N_total_kg")]
```

From a Sentinel-2 Level-2A scene to a variable-rate map:

``` r

s2   <- system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif", package = "agrinutri")
bio  <- estimate_biophysical(s2, output_dir = tempdir(),
                             variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni  <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                            crop = "maize", fvc = bio$FVC)
field <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "agrinutri"))
rx   <- build_strip_prescription(field[field$id == 3, ], machine_width = 24,
                                 variability = "nni", nni_raster = nni$NNI,
                                 n_target = 200, min_dose = 160, max_dose = 240)
export_prescription(rx, file.path(tempdir(), "rx.shp"), format = "shp")
```

[`run_app()`](https://mcroci.github.io/agrinutri/reference/run_app.md)
opens a Shiny interface with the same workflow.

## What is in the package

| Area | Main functions |
|----|----|
| Nitrogen balance (Allegato 2) | [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md), [`calculate_N_fertilization()`](https://mcroci.github.io/agrinutri/reference/calculate_N_fertilization.md) and one function per term: [`calc_crop_N_demand()`](https://mcroci.github.io/agrinutri/reference/calc_crop_N_demand.md), [`soil_fertility()`](https://mcroci.github.io/agrinutri/reference/soil_fertility.md), [`leaching_loss()`](https://mcroci.github.io/agrinutri/reference/leaching_loss.md), [`calc_N_immobilization_loss()`](https://mcroci.github.io/agrinutri/reference/calc_N_immobilization_loss.md), [`nitrogen_from_previous_crop_residues()`](https://mcroci.github.io/agrinutri/reference/nitrogen_from_previous_crop_residues.md), [`organic_previous_years_N()`](https://mcroci.github.io/agrinutri/reference/organic_previous_years_N.md), [`organic_fertilization()`](https://mcroci.github.io/agrinutri/reference/organic_fertilization.md), [`natural_contribution()`](https://mcroci.github.io/agrinutri/reference/natural_contribution.md) |
| P and K balances | [`P_balance()`](https://mcroci.github.io/agrinutri/reference/P_balance.md), [`K_balance()`](https://mcroci.github.io/agrinutri/reference/K_balance.md), [`classify_P_olsen()`](https://mcroci.github.io/agrinutri/reference/classify_P_olsen.md), [`classify_K()`](https://mcroci.github.io/agrinutri/reference/classify_K.md), [`estimate_soil_P_end_of_cycle()`](https://mcroci.github.io/agrinutri/reference/estimate_soil_P_end_of_cycle.md), [`estimate_soil_K_end_of_cycle()`](https://mcroci.github.io/agrinutri/reference/estimate_soil_K_end_of_cycle.md) |
| Standard-dose scheme | [`scheda_N()`](https://mcroci.github.io/agrinutri/reference/dose_standard_N.md), [`scheda_PK()`](https://mcroci.github.io/agrinutri/reference/dose_standard_PK.md), [`dose_standard_N()`](https://mcroci.github.io/agrinutri/reference/dose_standard_N.md), [`dose_standard_PK()`](https://mcroci.github.io/agrinutri/reference/dose_standard_PK.md) |
| Regulatory limits and plan | [`get_MAS()`](https://mcroci.github.io/agrinutri/reference/get_MAS.md), [`check_MAS()`](https://mcroci.github.io/agrinutri/reference/check_MAS.md) (Reg. reg. 2/2024), [`plan_distribution()`](https://mcroci.github.io/agrinutri/reference/plan_distribution.md) (organic + mineral, 170 kg N/ha ZVN check), [`max_SO_input()`](https://mcroci.github.io/agrinutri/reference/max_SO_input.md) |
| Soil | [`tri2()`](https://mcroci.github.io/agrinutri/reference/tri2.md), [`tri3()`](https://mcroci.github.io/agrinutri/reference/tri3.md), [`calc_soil_group_and_id_rag()`](https://mcroci.github.io/agrinutri/reference/calc_soil_group_and_id_rag.md), [`classify_pH()`](https://mcroci.github.io/agrinutri/reference/classify_pH.md), [`classify_SOM()`](https://mcroci.github.io/agrinutri/reference/classify_SOM.md), [`classify_CEC()`](https://mcroci.github.io/agrinutri/reference/classify_CEC.md), carbonate classes, [`soilgrids_input()`](https://mcroci.github.io/agrinutri/reference/soilgrids_input.md) |
| Farm and spatial balance | [`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md), [`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md) |
| Remote sensing | [`compute_vi()`](https://mcroci.github.io/agrinutri/reference/compute_vi.md) (NDVI, NDRE, GNDVI, CIred-edge, MCARI, MSAVI2), [`estimate_biophysical()`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md) (Gaussian-process retrieval from Sentinel-2 L2A), [`compute_NNI()`](https://mcroci.github.io/agrinutri/reference/compute_NNI.md), [`compute_NNI_from_S2()`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md), [`diagnose_N_status()`](https://mcroci.github.io/agrinutri/reference/diagnose_N_status.md) |
| Variable rate | [`variable_rate_N()`](https://mcroci.github.io/agrinutri/reference/variable_rate_N.md), [`estimate_N_rate_from_calibration_curve()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_calibration_curve.md), [`estimate_N_rate_from_holland_schepers()`](https://mcroci.github.io/agrinutri/reference/estimate_N_rate_from_holland_schepers.md), [`build_strip_prescription()`](https://mcroci.github.io/agrinutri/reference/build_strip_prescription.md), [`optimize_VR_DPI()`](https://mcroci.github.io/agrinutri/reference/optimize_VR_DPI.md) (optional QUEFTS economic optimum) |
| Export | [`export_prescription()`](https://mcroci.github.io/agrinutri/reference/export_prescription.md), [`export_prescription_all()`](https://mcroci.github.io/agrinutri/reference/export_prescription_all.md) (Shapefile, GeoJSON, KML, GeoPackage, ISOXML, John Deere, Trimble) |

## The nitrogen balance

N = **A** − **B** + **C** + **D** − **E** − **F** − **G**

| Term | Meaning |
|----|----|
| A | crop demand: unit uptake (Allegato 6) × expected yield |
| B | soil supply: N mineralised from organic matter × time coefficient, plus ready N for crops with a cycle shorter than one year |
| C | leaching: autumn–winter (Ca) and end-of-winter (Cb) losses from rainfall |
| D | immobilisation and dispersion: B × correction factor by texture and drainage, plus a negative precession effect |
| E | precession residues |
| F | previous years’ organic fertilisation × recovery coefficient × time coefficient |
| G | atmospheric deposition × time coefficient, plus biological fixation of legumes |

The dose is bounded to zero and to the crop ceiling as Fert_Office
reports it; current-year organic N (`Forg`) is then subtracted to give
the mineral N.

## Validation

The test suite checks agrinutri against Fert_Office v1.26 on random
field scenarios computed by the spreadsheet itself
(`tests/testthat/fixtures/`, generated with
`data-raw/fertoffice_validation.py`): every balance term and the
reported N, P2O5 and K2O doses are compared. Where the printed tables of
the DPI Norme Generali and Fert_Office disagree, agrinutri follows
Fert_Office; the differences are listed in
[`vignette("agrinutri-PK-and-distribution")`](https://mcroci.github.io/agrinutri/articles/agrinutri-PK-and-distribution.md).

## Course lab workflow (companion teaching repo)

If you use the **lab-agricoltura-di-precisione** exercise scripts
together with this package, the mapping is:

| Exercise script | Main agrinutri entry points |
|----|----|
| `01_bilancio_N.R` | [`farm_balance()`](https://mcroci.github.io/agrinutri/reference/farm_balance.md), [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md) |
| `02_suolo_IDW.R` | interpolation outputs feed [`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md) via rasters |
| `03_bilancio_spaziale.R` | [`spatial_N_balance()`](https://mcroci.github.io/agrinutri/reference/spatial_N_balance.md) |
| `04_NDVI_calibrazione.R` | [`compute_vi()`](https://mcroci.github.io/agrinutri/reference/compute_vi.md) |
| `05_NNI_singolo_scena.R` | [`estimate_biophysical()`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md), [`compute_NNI_from_S2()`](https://mcroci.github.io/agrinutri/reference/compute_NNI_from_S2.md) |
| `06_NNI_serie_temporale.R` | [`estimate_biophysical()`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md), [`crop_params_NNI()`](https://mcroci.github.io/agrinutri/reference/crop_params_NNI.md), NNI helpers |
| `07_prescrizione_VRT.R` | [`build_strip_prescription()`](https://mcroci.github.io/agrinutri/reference/build_strip_prescription.md) |
| `08_export_macchine.R` | [`export_prescription_all()`](https://mcroci.github.io/agrinutri/reference/export_prescription_all.md) |
| `09_figure_prescrizioni_metodi.R` | reads grids from step 07 (no new agrinutri calls) |
| `10_biophysical_mean_vs_pixel.R` | [`estimate_biophysical()`](https://mcroci.github.io/agrinutri/reference/estimate_biophysical.md) |

Install course dependencies once with
`source("esercitazioni/00_install_packages.R")` from the lab repository
root.

## Documentation

- Reference and articles: <https://mcroci.github.io/agrinutri/>
- Vignettes: `browseVignettes("agrinutri")`

## Citation

``` r

citation("agrinutri")
```

## Authors

Michele Croci (maintainer), Giorgio Impollonia, Andrea Ferrarini, Andrea
Fiorini, Manuele Ragazzi, Nicolaj Franceschi, Vincenzo Tabaglio, Stefano
Amaducci — Department of Sustainable Crop Production (DI.PRO.VE.S.),
Università Cattolica del Sacro Cuore, Piacenza, Italy.

## License

MIT. See `LICENSE`.
