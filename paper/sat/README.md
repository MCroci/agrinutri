# SAT manuscript: NFert, uncertainty-aware nitrogen balance from field to farm

One Smart Agricultural Technology article that merges the earlier SAT draft (soil-input
uncertainty, correlation length) with the SoftwareX manuscript (verification against Fert_Office,
NFert 1.0.0). The SoftwareX material stays in `../softwarex/` as the source of the validation
figure and data.

| File | Content |
|---|---|
| `NFert_SAT.md` | manuscript (Markdown, pandoc citations); `sh render.sh` makes `NFert_SAT.docx` |
| `00_config.R` | paths, soil run, scenario, balance and perturbation functions |
| `cerzoo_field_inputs.csv` | management inputs of the main case study (DPI reference weather) |
| `cerzoo_field_inputs_season.csv` | sensitivity run: rainfall measured in 2024 to 2025, recorded previous crops |
| `01_balance.R` | balance on the 10 m soil maps, Table 2 (`data/farm_accounting.csv`) |
| `02_uncertainty.R` | per-pixel Monte Carlo (20 m, K = 100) and variance decomposition |
| `02b_correlation_length.R` | farm-total SD versus soil-error correlation length |
| `03_diagnosis.R` | peak-canopy Sentinel-2 scene per field, NDVI and NNI |
| `04_prescriptions.R` | five strategies, 24 m strips, machine geometries, cell-size fidelity |
| `06_timeseries.R` | Sentinel-2 canopy trajectories per field (Figure 3) |
| `07_extra_analyses.R` | residual variogram (bound on the correlation length), mean shift, RMSE sensitivity, area of applicability, strategy metrics |
| `05_figures.R` | Figures 2 to 7 and Supplementary S1, S2 (run last) |
| `fig1_architecture.py`, `figures/` | Figure 1 and the figure files of the manuscript |
| `data/validation_fertoffice.csv` | package documentation only, not used in the manuscript |

Figure 1 comes from `fig1_architecture.py`; every other figure is produced by `05_figures.R`
from the outputs of scripts 01 to 07.

## Run

From the package root, in this order (about 1 hour in total on 8 cores):

```sh
Rscript paper/sat/01_balance.R
Rscript paper/sat/02_uncertainty.R
Rscript paper/sat/02b_correlation_length.R
Rscript paper/sat/03_diagnosis.R
Rscript paper/sat/04_prescriptions.R
Rscript paper/sat/06_timeseries.R
Rscript paper/sat/07_extra_analyses.R
Rscript paper/sat/05_figures.R
```

Environment variables: `PRESTO_DEPLOY` (root of the soil and Sentinel-2 data; default
`C:/Users/michele.croci/Desktop/presto-deploy`), `SAT_SCENARIO` (`reference` or `season`),
`SAT_SOIL_RUN` (`definitive` or `run1`). Sensitivity runs write to `out/season`, `out/run1`
and `data/season`, `data/run1`.

## Choices to confirm

The scripts of the earlier SAT draft were lost; the pipeline was rebuilt and the old inputs were
reconstructed. Confirm these before submission.

- **Weather.** The old analysis used the DPI reference weather (150 mm from October to January,
  no February rain, so no leaching term), which the 0.14.2 code reproduces on the old Table 2 to within
  a few kg N per ha. The measured 2024 to 2025 rainfall (301 and 98 mm, in the bundled
  `cerzoo_field.geojson`) raises the farm total from 6.9 to 8.7 t N and puts four fields above the MAS.
  The reference weather is the main case; the measured season is the sensitivity run.
- **Phases and previous crop.** Second-crop maize is modelled as a spring-summer crop of 100 to 130 days
  (the geojson label "Summer 90-110 days" is not a DPI phase); the previous crop is maize stalks buried
  for all fields in the main case.
- **Soil run.** The earlier draft mixed two model runs: maps of `0_RISULTATI_DEFINITIVI` with the
  leave-one-field-out RMSE (3.25, 4.44 percent, 0.100, 0.015) of `1_spazializzazione`. The main case uses
  the final maps with their own leave-one-point-out RMSE (2.90, 3.47, 0.103, 0.013); `SAT_SOIL_RUN=run1`
  uses the other run.
- **Area of applicability.** It exists only for the preceding run (84 to 91 percent of the area) and is
  not applied to the prescription.
