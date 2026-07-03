# NFert

<!-- badges: start -->
[![R-CMD-check](https://github.com/mcroci/NFert/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mcroci/NFert/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/mcroci/NFert/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/mcroci/NFert/actions/workflows/pkgdown.yaml)
[![Coverage](https://github.com/mcroci/NFert/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/mcroci/NFert/actions/workflows/test-coverage.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**N, P and K fertilization following Emilia-Romagna DPI 2026**

## Overview

`NFert` is an R package for calculating nitrogen, phosphorus and potassium
fertilization requirements in field and tree crops following the
**Disciplinari di Produzione Integrata (DPI) Emilia-Romagna** (ed. 2026). It
implements both the **method of the balance** (Allegato 2) and the
**Scheda a dose Standard** method, mirroring the official Fert_Office tool
(v1.26, Febbraio 2026). It supports maximum allowed doses (MAS), soil texture
grouping, Olsen P and exchangeable K availability, fertilization distribution
planning (organic + mineral), end-of-cycle soil P and K estimation and
precision agriculture (NDVI-based variable rate).

## Normative reference

- **DPI Emilia-Romagna** (2025–2026) – Norme Generali; Allegato 2 (metodo del bilancio), Allegati 3, 4, 6, 7, 9; *Guida alla Fertilizzazione Minerale e Organica* (N, P, K)
- **FertDPI / Fert_Office** – strumento regionale; NFert riproduce la logica del bilancio azotato per uso in R
- **Reg. reg. 2/2024** – limiti MAS (Allegato 9); **Reg. reg. 3/2017** – utilizzazione agronomica degli effluenti e del digestato
- **Direttiva Nitrati (91/676/CEE)** – in ZVN limite 170 kg N/ha/anno da effluenti zootecnici; Reg. UE 2021/2115 (soglie minime efficienza)

## Features

- **Nitrogen balance (Allegato 2)**: `N_balance()` with A (crop demand),
  B1/B2 (soil fertility), C1/C2 (leaching), D (immobilization), E (previous
  crop residues), F (previous years' organics), Forg (current year organics),
  G (natural deposition). Supports `soil_seeding = "no-till"` (−3 kg/ha on
  b1), `greenhouse = TRUE` (+2 on D), automatic fold of negative E into D.
- **Phosphorus balance**: `P_balance()` with Olsen P classification
  (`classify_P_olsen()`), Arricchimento / Mantenimento / Riduzione strategy,
  texture-dependent weight at 30 cm and P immobilisation factor 1.6.
- **Potassium balance**: `K_balance()` with K availability class by texture
  (`classify_K()`), clay-driven leaching (`K_leaching_by_clay()`).
- **Scheda a dose Standard**: `scheda_N()` and `scheda_PK()` with the DPI 2026
  catalogue of decrements and increments and MAS cap on N.
- **Fertilization distribution plan**: `plan_distribution()` combines organic
  matrices (with DPI 2026 N efficiency by soil × dose × sector) and mineral
  fertilisers (146-entry `concimi.table`), returns Eccesso/Deficit alerts and
  ZVN 170 kg N/ha check.
- **End-of-cycle soil dotation**: `estimate_soil_P_end_of_cycle()` and
  `estimate_soil_K_end_of_cycle()` for next-year planning.
- **Soil chemistry**: `classify_pH()`, `classify_carbonate_tot()`,
  `classify_carbonate_att()`, `classify_CEC()`, `ratio_Mg_K()`,
  `ratio_K_CEC()`, `classify_SOM()`, `max_SO_input()`.
- **MAS (Massimali)**: `get_MAS()` and `check_MAS()` for maximum allowed N
  per crop (DPI 2026, RR 2/2024).
- **Precision agriculture**: NDVI-based variable rate (calibration curve and
  Holland & Schepers).

## Installation

```r
# install.packages("remotes")
remotes::install_github("mcroci/NFert")
```

See also the [pkgdown site](https://mcroci.github.io/NFert/).

## Course lab workflow (companion teaching repo)

If you use the **lab-agricoltura-di-precisione** exercise scripts together with this package, the mapping is:

| Exercise script | Main NFert entry points |
|-------------------|-------------------------|
| `01_bilancio_N.R` | `farm_balance()`, `N_balance()` |
| `02_suolo_IDW.R` | interpolation outputs feed `spatial_N_balance()` via rasters |
| `03_bilancio_spaziale.R` | `spatial_N_balance()` |
| `04_NDVI_calibrazione.R` | `compute_vi()` |
| `05_NNI_singolo_scena.R` | `estimate_biophysical()`, `compute_NNI_from_S2()` |
| `06_NNI_serie_temporale.R` | `estimate_biophysical()`, `crop_params_NNI()`, NNI helpers |
| `07_prescrizione_VRT.R` | `build_strip_prescription()` |
| `08_export_macchine.R` | `export_prescription_all()` |
| `09_figure_prescrizioni_metodi.R` | reads grids from step 07 (no new NFert calls) |
| `10_biophysical_mean_vs_pixel.R` | `estimate_biophysical()` |

Install course dependencies once with `source("esercitazioni/00_install_packages.R")` from the lab repository root.

## Quick Start

```r
library(NFert)

# Calculate nitrogen balance for a maize crop
maize_n_balance <- N_balance(
  expected_yield_tons_ha = 15,
  crop = "Mais trinciato (classe 700)",
  ccp = "Spring-summer crop 100–130 days",
  sand = 50,
  clay = 35,
  Ntot = 1.2,
  SOM = 1.2,
  CN = 9.5,
  oxygen_availability = "Normal",
  winter_rain = 160,
  start_spring_rain = 40,
  prev_crop = "Winter cereals straw removal",
  source = "Cattle slurry",
  fertorg_frequency = "every year",
  location = "Plain adjacent to urbanized areas",
  forg_quantity = 100
)

print(maize_n_balance)
```

## Main Functions

- `N_balance()`: Main function for calculating comprehensive nitrogen balance
- `calc_crop_N_demand()`: Calculate crop nitrogen requirements
- `soil_fertility()`: Estimate soil nitrogen availability
- `leaching_loss()`: Calculate nitrogen leaching losses
- `calc_N_immobilization_loss()`: Estimate nitrogen immobilization
- `organic_fertilization()`: Calculate nitrogen from organic fertilizers
- `natural_contribution()`: Estimate natural nitrogen deposition
- `tri2()` and `tri3()`: Soil texture classification (USDA; tri3 maps to DPI groupings)
- `get_MAS()` and `check_MAS()`: Maximum allowed doses (MAS) per crop (DPI 2026)
- `calculate_N_fertilization()`: Final N dose from balance result
- `estimate_N_rate_from_calibration_curve()`: NDVI-based rate estimation (calibration method)
- `estimate_N_rate_from_holland_schepers()`: NDVI-based rate estimation (H&S method)

## Nitrogen balance (DPI Allegato 2)

N da apportare = **A** + **C** + **D** − **B** − **E** − **F** − **G**

- **A**: Fabbisogno della coltura (resa × coefficiente asportazione)
- **B**: Fertilità del suolo (N mineralizzabile dalla S.O. + N pronto)
- **C**: Perdite per lisciviazione (C1 autunno-inverno, C2 fine inverno)
- **D**: Immobilizzazione e dispersione
- **E**: N da precessione colturale (residui, leguminose, paglie)
- **F**: N da fertilizzazione organiche anni precedenti
- **G**: Apporti naturali (precipitazioni)

NFert computes the balance and then subtracts current-year organic N (Forg) to give the mineral N to apply. In Nitrate Vulnerable Zones (ZVN), the 170 kg N/ha/year limit from livestock effluents applies at farm level.

## Documentation

See the package vignette for detailed examples and usage:

```r
vignette("NFert")
```

## Authors

- Michele Croci (maintainer)
- Manuele Ragazzi
- Stefano Amaducci

## Citation

To cite this package in publications, use:

```r
citation("NFert")
```

## License

This package is licensed under the MIT License. See `LICENSE` file for details.

## Contact

For questions or issues, please contact:
- Email: michele.croci@unicatt.it
- Department: Department of Sustainable Plant Productions (DI.PRO.VE.S), Catholic University of the Sacred Heart
