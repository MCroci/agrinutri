# NFert News

## Version 0.14.1 (2026-06-30) — Robust QUEFTS optimisation + cleaner build

### Fixes

* `optimize_VR_DPI()` no longer aborts the whole field prescription when the
  optional QUEFTS economic optimiser (`Rquefts::optApp()`, solved via
  **limSolve**) fails on an individual cell. Each cell's optimisation is now
  evaluated defensively; cells that cannot be solved fall back to the DPI
  regulatory balance cap (with a single summarising warning) so the returned
  rasters stay complete and mass-balanced. This also fixes the CI test
  `test-optimize_VR_DPI.R`, which runs the optimiser only on macOS/Linux
  (it is skipped on Windows because some `Rquefts::optApp` builds segfault
  there), where a per-cell solver failure was failing `R-CMD-check` and
  `test-coverage` on the Unix runners while Windows stayed green.

### Build

* `.Rbuildignore` now excludes stray top-level `*.pdf` files (e.g. the bundled
  reprint `1-s2.0-S2772375526002674-main.pdf`) from the package tarball,
  removing the "non-standard files at top level" `R CMD check` NOTE and trimming
  the build size.

## Version 0.13.3 (2026-05-09) — Forg aligned with DPI when texture omitted

### Fixes

* `N_balance()` now passes **computed soil texture** (`soil.group` from sand/clay)
  and defaults **`distribution_efficiency = "medium"`** to `organic_fertilization()`
  when those arguments are omitted. Current-year organic N (**Forg**) therefore uses
  the DPI path (N content × efficiency) like Fert_Office **Apporti al terreno**, instead
  of the legacy `f.table` shortcut `value * quantity / 100` that produced unrealistically
  small **Forg** (e.g. 154 m³/ha → ~0.46 kg N/ha). Standalone `organic_fertilization()`
  behaviour is unchanged when `soil_group` is NULL.

### farm_balance

* Reads optional column **`organic_previous_year_N`** (kg N ha⁻¹, DPI term **F**) and passes it to `N_balance()`. **`farm_balance()` documentation** for **`forg_quantity`** now matches **`N_balance()`** (current-year organic material dose, m³/ha or t/ha — not kg N/ha).

## Version 0.13.2 (2026-05-09) - Leaching C1/C2 vs Fert_Office C&D

### Fixes

* `leaching_loss()` now follows DPI 2026 Allegato 2 / Fert_Office v1.26
  foglio `C&D`: **C1** (`C_a`) is the rainfall-dependent fraction of
  readily available N (`b_1`), not the constant tabular column
  `cb.table$C`. **C2** (`C_b`) is only the February contribution on the
  residual `b_1 - C_1`. Thus `C_1 + C_2 <= b_1` and `N_balance()`
  matches the spreadsheet for scenarios such as winter rain exactly 150 mm
  (previously `C1` could wrongly stay at the tabular maximum).
  New regression tests in `tests/testthat/test-leaching_loss.R`.

## Version 0.13.1 (2026-04-24) - Strip-prescription builder + demo Shiny

### New features

* `build_strip_prescription()` tiles a field polygon with
  machine-width strips along an A-B line (or the longest side by
  default) and assigns a per-strip dose using one of four variability
  methods: \code{"uniform"}, \code{"calibration"} (VI curve),
  \code{"nni"} (NNI zones), \code{"classes"} (VI quantile classes).
  The area-weighted mean dose is optionally rescaled to match the
  field-level target, preserving the mass-balance constraint.
  Output is a ready-to-export \code{sf} object consumed natively by
  `export_prescription()`.

* New Shiny sub-tab "Strip prescription (machine width)" inside the
  Precision N tab. Controls: plot selector from the demo farm, machine
  width slider, A-B source (long side / upload LINESTRING),
  variability method, min/max/N-target sliders, \emph{Load demo NDVI}
  and \emph{Load demo NNI} buttons that synthesise plausible rasters
  programmatically. Download bundles all requested formats as a zip.

* Demo loaders in the VRT sub-tab as well: "Load synthetic demo NDVI"
  button bypasses the file-upload step so users can explore the
  pipeline without having a real raster at hand.

### Fixes

* `resolve_crop()` now searches three columns (`crop`, `crop_it`,
  `crop_en`) so legacy Italian strings keep working after the 0.12.0
  English-canonical rebuild.
* Vignette `NFert.Rmd` and test `test-dpi2026-benchmark.R` updated to
  use the English canonical crop names that match the rebuilt tables.
* New vignette `farm-and-prescription-map.Rmd` walks through the
  end-to-end flow from farm GeoJSON to strip export.

### Article

* `NFert_SoftwareX_article_v12.docx` bumps the code metadata to
  v0.13.0 and updates Fig. 1 with the Precision-agriculture module
  listing `estimate_biophysical()`, `compute_NNI_from_S2()`,
  `variable_rate_N()`, `build_strip_prescription()`,
  `farm_balance()` and `export_prescription()`.

## Version 0.13.0 (2026-04-24) - Prescription-map export + legume fix

### New features

* New `export_prescription()` writes a variable-rate prescription layer
  (an `sf` object from `farm_balance()` or a raster from
  `variable_rate_N()`) in one of the seven formats accepted by the
  on-board monitors of modern tractors: Shapefile, GeoJSON, KML,
  GeoPackage, \emph{John Deere-ready} Shapefile (integer `RATE`),
  \emph{Trimble-ready} Shapefile (`TGT_RATE`), and ISOXML
  (ISOBUS ISO 11783-10 `TASKDATA.XML`). Rasters are polygonised
  on-the-fly; output is always reprojected to WGS84, validated,
  sliver-cleaned, and the dose field is renamed to the convention of
  the target format.

* New `export_prescription_all()` convenience wrapper writes several
  formats side-by-side into the same output folder. The Shiny "Farm /
  Azienda" tab exposes it through a "Download prescription bundle"
  button that produces a zip of the selected formats ready to be
  loaded into the farm monitor.

### Fixes

* `calc_crop_N_demand()` now applies the biological N-fixation
  correction for legumes, reducing the gross demand by
  `n_fixation_pct` read from `NFert::crops.table`. Soybean (-90 %),
  alfalfa (-100 %), faba bean / pea / lupin (-85 %), polyphytic legume
  meadows (-50 %) are handled transparently. Non-legume crops are
  unaffected. Set `apply_n_fixation = FALSE` to recover the pre-0.12.1
  behaviour.

* `farm_balance()` now accepts the legacy `oxygen_availability`
  aliases `"Low"` / `"High"` / `"Reduced"` / `"Poor"` / `"Good"` and
  translates them to the canonical `ca.table$availability` keys
  (`"Slow"` / `"Normal"` / `"Fast"`), avoiding the "list cannot be
  converted to double" crash on legacy GeoJSON files.

### Dependencies

* Added `xml2` to Suggests for the ISOXML writer.

## Version 0.12.0 (2026-04-24) - English-only user-facing API

### Breaking change: reference tables are now English-canonical

* All bundled reference tables (`uptake_table`, `mas.table`,
  `crops.table`, `e.table`, `organic_fertilizers.table`,
  `distribution_modalities.table`, `cycle_modality.table`,
  `cycles.table`, `cycle_phases.table`, `fertilizer_types.table`) now
  use the English name in their primary lookup column (`crop`,
  `previous_crop`, `fertilizer`, `modality_epoch`, `level`, `cycle`,
  `type`, `phase_duration`). The Italian translation of each row is
  kept in a secondary `*_it` column for reference.
* `data-raw/build-rda.R` has been extended to swap `crop` and
  `crop_en` columns in the three tables where Italian was still
  primary, and the 182 Italian crop names in the source CSVs have
  been filled in with their English translations. Re-run
  `source("data-raw/build-rda.R")` once in R to regenerate the
  `.rda` files.

### New helpers

* Exported `crop_en2it`, `prev_crop_en2it`, `source_en2it`,
  `modality_epoch_en2it`, `level_en2it` dictionaries plus
  `nfert_en2it()` / `nfert_it2en()` translators. They are now a pure
  convenience for users migrating legacy scripts that still pass
  Italian strings; no code inside NFert depends on them any longer.

### User-facing updates

* `inst/extdata/example_farm.geojson` carries English-only values that
  match the canonical `crop_en` / `previous_crop` / `fertilizer`
  entries of the rebuilt tables (`Silage maize (class 700)`, `Dairy
  cattle slurry`, `Maize stalks removed`, ...).
* The bundled Shiny app (tabs N balance, P/K balance, Distribution
  plan, Precision N, Spatial balance, Farm / Azienda) is now
  English-only: both labels and values passed to the internal
  functions are English strings, matching the tables.
* `farm_balance()` no longer translates its input; it simply routes
  Italian legacy strings through `nfert_it2en()` so users do not
  have to rewrite historical GeoJSONs.

## Version 0.11.0 (2026-04-24) - Farm-level GeoJSON workflow

### New features

* `farm_balance()` reads a vector layer (GeoJSON, Shapefile, GeoPackage
  or an in-memory `sf` object) where every feature is an agronomic plot
  and runs `N_balance()` on each row, using the attributes as arguments.
  Returns an enriched `sf` object with columns `N_target`, `MAS_cap`,
  `MAS_ok`, `N_total_kg` and an optional `balance_error` message. When
  `p_balance = TRUE` or `k_balance = TRUE` the P2O5 and K2O balances
  are computed too (using `olsen_value` and `k_value` columns).
  Italian and English aliases for crops and categorical inputs are both
  accepted. An `output` path writes the enriched layer back to disk.

* New Shiny tab "Farm / Azienda" shows an interactive Leaflet map of
  the plots coloured by N target, KPIs for total ha / total kg N /
  MAS breaches, a per-plot N* bar chart with the ZVN 170 kg/ha
  reference, and the enriched layer can be downloaded as GeoJSON or
  a summary CSV.

* New runnable example `system.file("extdata/example_farm.geojson",
  package = "NFert")`: a 35.5 ha fictitious farm with 8 plots in the
  Pianura Padana, carrying all the columns needed by `N_balance()` so
  the workflow can be exercised end-to-end without external data.

### Dependencies

* Added `sf` and `leaflet` to Suggests (lazy-loaded by
  `farm_balance()` and the Shiny tab only).

## Version 0.10.0 (2026-04-24) - Shiny web interface

### New features

* `run_app()` launches a full-featured Shiny interface that exposes the
  balance, distribution, precision and spatial modules of NFert through
  interactive forms and maps. The app ships with six tabs (Welcome, N
  balance, P & K balance, Distribution plan, Precision N, Spatial
  balance), live MAS and 170 kg N ha-1 ZVN validation, per-pixel VRT
  map preview and a one-click Sentinel-2 -> NNI pipeline driven by
  `compute_NNI_from_S2()`. A dedicated "Research mode" toggle in the
  navbar exposes coefficient overrides and intermediate balance terms
  for advanced users.

* Shiny module layout under `inst/shinyapp/`, with one file per module
  in `modules/` and shared assets in `www/` (custom.css follows the
  same colour palette as the scientific article).

### Dependencies

* Added `shiny (>= 1.7.0)`, `shinyjs`, `DT` and `ggplot2` to Suggests
  (lazy-loaded by `run_app()` only).

## Version 0.9.0 (2026-04-24) - Crop-aware S2->NNI pipeline

### New features

* New `compute_NNI_from_S2()` end-to-end pipeline: takes the LAI, Cm and
  canopy-N rasters returned by `estimate_biophysical()`, looks up the
  crop-specific parameters with `crop_params_NNI()`, applies the leaf-to-
  total biomass partitioning, the N:Chl conversion (or the direct
  protein path), the FVC + SCL masking and the critical-N dilution
  curve, and returns a list of SpatRasters with W, N_actual, N_crit,
  NNI and a categorical zone map (1 deficient / 2 optimal / 3
  excessive). A single call goes from Sentinel-2 traits to an actionable
  zone map.

* New `crop_params_NNI()` exposes the first-guess defaults for eight
  crops (wheat, maize, rice, barley, rapeseed, sorghum, sunflower,
  soybean) with all seven parameters needed by the pipeline: dilution
  coefficients a/b, biomass lower bound w_min, leaf allocation
  alpha_leaf, N:Chl ratio k_NChl and FVC cutoff fvc_min. The function
  accepts Italian aliases ("frumento", "mais", "orzo", ...) and
  documents the literature sources and the calibration caveats (15-30\%
  bias if alpha_leaf and k_NChl are not locally calibrated).

### Changes

* `biophysical_to_NNI_inputs()` now accepts `alpha_leaf` and `k_NChl`
  arguments so the leaf-to-total partitioning and the chlorophyll path
  are explicit; the previous version conflated leaf and total biomass.
  Most users should migrate to the higher-level
  `compute_NNI_from_S2()`.

## Version 0.8.0 (2026-04-24) - GPR biophysical retrieval from Sentinel-2

### New features

* New `estimate_biophysical()` applies pre-trained Gaussian Process
  Regression (GPR) models to a 10-band Sentinel-2 L2A surface-reflectance
  raster (B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12) and returns
  canopy-level biophysical maps: leaf area index `LAI`, leaf dry-matter
  content `Cm`, canopy water content `Cw`, fractional vegetation cover
  `FVC`, leaf chlorophyll `Cab`, the classic pyeogpr `laiCab` product
  and two canopy-N products `CNC_Cab` / `CNC_Cprot`. The implementation
  is a pure-R port of the `pyeogpr` inference pipeline (Estevez et al.,
  2022) validated at correlation 1.0 against the reference Python code
  on a 200-pixel benchmark (relative error < 1.4e-8). Depends only on
  `terra` and `jsonlite`. Models are loaded from user-supplied JSON
  files, so the module can be used with any additional PROSAIL-trained
  GPR variable without touching the source.

* New `biophysical_to_NNI_inputs()` helper converts the GPR outputs
  (`LAI`, `Cm`, `CNC_Cprot`) into the two layers required by
  `compute_NNI()` (aboveground dry biomass `W` and plant N concentration
  `N_actual`), closing the pipeline
  Sentinel-2 -> canopy traits -> NNI map -> VRT modifier.

### Dependencies

* Added `terra` and `jsonlite` to `Suggests` (loaded on demand by
  `estimate_biophysical()` via `requireNamespace()`).

## Version 0.7.0 (2026-04-19) - Remote sensing diagnosis

### New features

* New `compute_vi()` multi-index engine: computes NDVI, NDRE, GNDVI,
  CIred-edge, MCARI and MSAVI2 from a multi-band `RasterStack`
  (Sentinel-2 L2A or UAV multispectral) with configurable band mapping
  and optional integer-DN rescaling (`scale_factor`). All existing
  variable-rate functions (`variable_rate_N()`,
  `estimate_N_rate_from_calibration_curve()`,
  `estimate_N_rate_from_holland_schepers()`) now accept any
  normalised index on a 0-1 scale, so users can switch from NDVI to
  red-edge indices transparently in mid- to late-vegetative stages
  where NDVI saturates (Clarke 2001; Li 2014; Cao 2015).

* New `compute_NNI()` implements the Nitrogen Nutrition Index of
  Lemaire & Gastal (1997): NNI = N_actual / N_c, where
  N_c = a * W^(-b) is the species-specific critical N dilution curve.
  Curves bundled for wheat (Justes 1994), maize (Plenet & Lemaire
  2000), rice (Sheehy 1998), rapeseed (Colnenne 1998), grass (Duru
  1997), sorghum (van Oosterom 2010) and sunflower (Debaeke 2012).
  Accepts scalar/vector/`RasterLayer` inputs and returns the matching
  output type.

* New `diagnose_N_status()` wraps `compute_NNI()` and turns continuous
  NNI into three interpretable classes (deficient / optimal /
  excessive) with user-configurable thresholds. Returns per-pixel
  class raster and aggregated counts for diagnostic maps.

* New `critical_N_curve()` returns the `(a, b, W_min)` coefficients of
  the critical-N dilution curve for a given crop, supporting both
  English and Italian synonyms (frumento, mais, colza, riso, sorgo,
  girasole, prato).

* New vignette `remote-sensing-diagnosis` walking through the full
  diagnosis-to-prescription loop: multi-band stack -> multi-index
  comparison -> NNI diagnosis -> variable-rate prescription guided by
  the NNI classes.

## Version 0.6.0 (2026-04-18) - Spatial nitrogen balance

### New features

* New `spatial_N_balance()` applies `N_balance()` pixel-by-pixel to
  a `RasterStack` of soil properties (TN, SOM, Clay, Sand, CNratio),
  returning a `RasterStack` of spatially-resolved balance terms
  (A, B, C1, C2, D, E, F, Forg, G, N_to_apply).
* Bundled real soil-property rasters for a 12-ha arable field near
  Cremona (Northern Italy) in `inst/extdata/`:
  `Cremonesi_TN.tif`, `Cremonesi_SOM.tif`, `Cremonesi_Clay.tif`,
  `Cremonesi_Sand.tif`, `Cremonesi_Silt.tif`, `Cremonesi_CNratio.tif`
  (~3.5 m resolution, EPSG:4326).
* New vignette `spatial-balance` demonstrating the full workflow:
  load rasters -> `spatial_N_balance()` -> synthetic NDVI ->
  `variable_rate_N(method = "holland")` -> VRT prescription.

## Version 0.5.1 (2026-04-16) - Shiny dashboard removed

### Removed

* `run_NFert_app()` and the bundled Shiny dashboard (`inst/shiny/app.R`)
  have been removed. The package is now a scripting-only R API.
* `shiny`, `bslib`, `DT`, `plotly` and `leaflet` removed from
  Suggests. The core NFert API keeps a single hard dependency
  (`raster`), and Suggests are now limited to `testthat`, `knitr`
  and `rmarkdown`.

## Version 0.5.0 (2026-04-15) - Precision fertilization wrapper

### New features

* New `variable_rate_N()` wrapper that accepts an NDVI `RasterLayer`
  plus a whole-field N dose and returns a spatial prescription under
  a mass-balance constraint (mean rate = `n_dose`, bounded by
  `minN` / `maxN`). Supported methods: `"calibration"` (two- or
  three-point linear regression between user-defined N rates and
  reference NDVI) and `"holland"` (Holland & Schepers
  sufficiency-index redistribution, default
  `NDVI_ref = quantile(ndvi, 0.95)`).

## Version 0.4.0 (2026-04-15) - English-only naming (BREAKING)

* Italian column names and dataset names renamed to English
  equivalents. Italian originals are preserved in `_it` companion
  columns where helpful.
* Crops are now bilingual: new `crop_en` column (54 curated English
  translations, fallback to Italian for the remaining DPI 2026
  entries) plus a `resolve_crop()` helper that accepts either form
  (case-insensitive). `list_crops()` returns the mapping.
* Italian function names kept as backward-compatible aliases
  (`scheda_N()` / `scheda_PK()`).

## Version 0.3.0 (2026-02) - Full P+K + scheda

* Full P2O5 and K2O balance (`P_balance()`, `K_balance()`).
* Scheda a dose Standard for N and PK.
* Fertilization distribution plan (`plan_distribution()`) with organic
  and mineral fertilisers, DPI 2026 efficiency matrix and ZVN 170
  kg N/ha check.
* End-of-cycle soil P and K estimation.
* Soil chemistry classifiers: pH, carbonate, CEC, Mg/K, K/CEC, SOM,
  maximum SO input.
* Alignment with Fert_Office v1.26 (Febbraio 2026).

## Version 0.1.0

* Initial release: N balance following DPI Emilia-Romagna 2018/2020.
