---
title: "NFert: an R package for regulatory nutrient balances and variable-rate nitrogen prescriptions"
bibliography: references.bib
link-citations: true
---

**Michele Croci**^a,\*^, **Giorgio Impollonia**^a^ [confirm affiliation], **Andrea Ferrarini**^a^, **Andrea Fiorini**^a^, **Manuele Ragazzi**^a^, **Nicolaj Franceschi**^a^, **Vincenzo Tabaglio**^a^, **Stefano Amaducci**^a^

^a^ Department of Sustainable Crop Production (DI.PRO.VE.S.), Università Cattolica del Sacro Cuore, via Emilia Parmense 84, 29122 Piacenza, Italy

^\*^ Corresponding author: michele.croci@unicatt.it

# Abstract

Regional nitrogen balances set legal fertiliser doses but are distributed as closed spreadsheets that compute one field at a time. NFert is an open-source R package that implements the nitrogen, phosphorus and potassium balance of the Emilia-Romagna Integrated Production Guidelines (DPI 2026), returns every balance term so that a dose can be audited, and keeps all coefficients as editable data. The balance runs per plot or per soil-map pixel, and a Sentinel-2 module turns the Nitrogen Nutrition Index into variable-rate prescriptions whose field mean equals the balance dose. In a Monte Carlo analysis on a real farm, soil-map error made the farm nitrogen total uncertain by less than 1 percent.

# Keywords

R package; Nutrient balance; Fertilisation planning; Regulatory compliance; Precision agriculture; Sentinel-2

# Code metadata

| Nr | Code metadata description | Metadata |
|----|-----------------------|--------------------------------------|
| C1 | Current code version | v1.0.0 |
| C2 | Permanent link to code/repository used for this code version | https://github.com/mcroci/NFert |
| C3 | Permanent link to reproducible capsule | [Zenodo DOI of the v1.0.0 release, to be added] |
| C4 | Legal code license | MIT License |
| C5 | Code versioning system used | git |
| C6 | Software code languages, tools and services used | R |
| C7 | Compilation requirements, operating environments and dependencies | R ≥ 4.0; imports terra; optional (Suggests): sf, jsonlite, xml2, Rquefts, geodata, shiny, shinyjs, DT, ggplot2, patchwork, leaflet; tested on Windows, macOS and Linux |
| C8 | If available, link to developer documentation/manual | https://mcroci.github.io/NFert/ |
| C9 | Support email for questions | michele.croci@unicatt.it |

# 1. Motivation and significance

Nitrogen fertilisation plans in the European Union are written under two sets of rules. The Nitrates Directive caps livestock manure at 170 kg N ha^−1^ in Nitrate Vulnerable Zones [@nitrates1991], and regional integrated-production schemes set crop-specific maximum allowed doses (MAS) and require the dose to be justified by a nutrient balance. Balance methods are well established [@oenema2003], but in practice they reach farms through regional software. In Emilia-Romagna (Italy) the Integrated Production Guidelines (Disciplinari di Produzione Integrata, DPI 2026) [@dpi2026; @guida2026] and the maximum doses of Regional Regulation 2/2024 [@rr2_2024] are applied with Fert_Office, an Excel workbook distributed by the Region [@fertoffice2026]. A plan is computed one field at a time by filling in input cells, and the result is what an inspection checks against.

A spreadsheet of this kind serves its purpose for one advisor and one field. It does not serve three other uses. The first is batch computation, over every plot of a farm, over several years or over a grid of soil-map pixels. The second is linking the regulatory dose to in-season information, such as satellite estimates of crop nitrogen status, and to variable-rate equipment, while staying within the dose that the plan justifies. The third is inspection: the formulas are spread over about 40 linked sheets, so it is hard to see why a dose has a given value, to change a coefficient, or to reproduce a plan independently.

Open tools exist around this gap, but none of them fills it. Soil-test databases such as FRST make calibration data public but do not compute plans [@lyons2020]. Process-based crop models such as DSSAT, APSIM and STICS simulate nitrogen dynamics in detail [@jones2003; @keating2003; @brisson2003], but they need calibration and are not the method that a regulation prescribes. Nutrient-balance software for other regulations, such as webBESyD for the German rules, is offered as a web service rather than as a library [@donauer2025]. Sentinel-2 tools for variable-rate nitrogen, such as AgroSat and the simplified prescriptions tested on Italian wheat, set rates from canopy reflectance but do not compute the regulatory balance [@hamie2026; @vizzari2019; @santaga2021]. The evidence that sensor-based rates improve management also varies with context [@holland2010; @diacono2013; @colaco2018; @basso2016]. What is missing is an open implementation of the regulatory balance itself that remote-sensing and variable-rate methods can build on. Compatibility with compliance demands is one of the factors that decide whether farmers and advisors adopt a decision-support tool [@rose2016], and the Common Agricultural Policy now requires Member States to offer farmers a digital Farm Sustainability Tool for Nutrients [@eu2021_2115], which such an engine could serve.

NFert provides that implementation in R [@rcore2025]. It computes the Emilia-Romagna balance for nitrogen, phosphorus and potassium as Fert_Office does, keeps every coefficient table as an editable R dataset, and adds the spatial and remote-sensing steps that Fert_Office lacks. The intended users are farm advisors producing plans in batch, researchers who need the regulatory dose as a model component, and teachers of nutrient management.

# 2. Software description

## 2.1. Software architecture

NFert is a pure-R package whose only hard dependency is terra [@terra2024]; spatial vectors (sf), the Gaussian-process models (which need jsonlite), the QUEFTS economic optimum (Rquefts) and the Shiny interface are optional. It exports 76 functions and 38 lazy-loaded datasets. The design follows the structure of the regulation (Fig. 1).

![Fig. 1. NFert architecture. Inputs (top) feed the DPI 2026 balance, built from one function per balance term and checked against the regulatory limits; the same balance is applied per plot or per pixel. The remote-sensing module derives canopy traits and the Nitrogen Nutrition Index from Sentinel-2 or UAV imagery. The variable-rate functions redistribute the balance dose N* in space under a mass-balance constraint and export machine files. All coefficients are editable R datasets (dashed).](figures/fig1_architecture.pdf){width=100%}

The nitrogen balance is N = A − B + C + D − E − F − G, where A is crop demand (unit uptake × expected yield), B the soil supply from organic-matter mineralisation and readily available N, C the leaching losses in autumn–winter and at the end of winter, D immobilisation and dispersion, E the residues of the previous crop, F the residual effect of organic fertilisation in previous years and G atmospheric deposition plus biological fixation. Each term has its own exported function (`calc_crop_N_demand()`, `soil_fertility()`, `leaching_loss()`, `calc_N_immobilization_loss()`, `nitrogen_from_previous_crop_residues()`, `organic_previous_years_N()`, `natural_contribution()`). `N_balance()` composes them and returns every term, so a dose can be audited line by line. `calculate_N_fertilization()` then applies the share of the balance admitted for the crop phase and the crop ceiling, and subtracts the current-year organic N. The coefficients sit in datasets such as `uptake_table` (unit uptake, 235 crop entries), `coef_time` (time coefficients by crop phase), `mas.table` (maximum allowed doses), `cb.table` (immobilisation factors) and `e.table` (previous-crop effects). Replacing a table re-parameterises the balance for another guideline without touching the code.

## 2.2. Software functionalities

The main functionalities are grouped in Table 1.

Table: Table 1. Main functionalities of NFert 1.0.0.

| Area | Functions |
|------------|------------------------------------|
| Nitrogen balance (DPI Annex 2) | `N_balance()`, `calculate_N_fertilization()` and one function per term |
| P~2~O~5~ and K~2~O balances | `P_balance()`, `K_balance()`, availability classes, end-of-cycle soil P and K |
| Standard-dose scheme | `scheda_N()`, `scheda_PK()` |
| Regulatory checks and plan | `get_MAS()`, `check_MAS()`, `plan_distribution()` (organic and mineral fertilisers, 170 kg N ha^−1^ check) |
| Soil | texture triangle and DPI groups, pH, carbonates, CEC, organic matter; `soilgrids_input()` for SoilGrids 2.0 layers [@poggio2021] |
| Scale | `farm_balance()` (one row per plot), `spatial_N_balance()` (one balance per pixel) |
| Remote sensing | `compute_vi()` (six indices), `estimate_biophysical()`, `compute_NNI_from_S2()`, `diagnose_N_status()` |
| Variable rate | `variable_rate_N()`, `build_strip_prescription()`, `optimize_VR_DPI()` |
| Export and interface | `export_prescription()` (ISOXML, Shapefile, GeoJSON, KML, GeoPackage, John Deere, Trimble), `run_app()` |

The P~2~O~5~ and K~2~O balances follow the same guidelines. Their doses depend on the availability class of Olsen P and exchangeable K for the texture group: enrichment, maintenance or reduction, with a carbonate-dependent P immobilisation factor and a clay-dependent K leaching term.

The remote-sensing module goes from a Sentinel-2 Level-2A scene to a nitrogen diagnosis. `estimate_biophysical()` is an R port of the Sentinel-2 Level-2A Gaussian-process regression models of the pyeogpr library [@estevez2022] [authors: confirm the reference for the L2A and canopy-N models], a retrieval approach reviewed by Verrelst et al. [-@verrelst2015]. It estimates leaf area index, leaf dry matter, chlorophyll and canopy nitrogen content, and processes rasters in blocks so that whole tiles fit in memory. `compute_NNI_from_S2()` combines these traits into the Nitrogen Nutrition Index, the ratio of actual to critical N concentration along the critical dilution curve of the species [@lemaire1997; @plenet1999]. The same call classes the map into deficient (< 0.9), optimal and excessive (> 1.1, luxury consumption) zones [@houles2007]; `diagnose_N_status()` does the same from measured N content and biomass.

The variable-rate functions turn a vegetation index or NNI map into rates with a calibration ramp, the sufficiency index of Holland and Schepers [-@holland2010], quantile classes or NNI zones. Whatever the method, the rates are rescaled so that their area-weighted mean equals the balance dose N\* within user bounds: the map changes where nitrogen goes, not how much. `build_strip_prescription()` tiles a field along the A–B line of the machine, in the local UTM zone so that working width and cell length are true ground distances. As an alternative, `optimize_VR_DPI()` sets the field level at the economic optimum computed with the QUEFTS model [@janssen1990] (through the Rquefts package) when this is below the regulatory ceiling.

## 2.3. Quality assurance

Where the printed tables of the guidelines (Norme Generali, Annex 2, 2024/25 edition) and Fert_Office differ, for example in the mineralisation rates of sandy soils and the immobilisation factors of poorly drained soils, NFert follows Fert_Office, the tool that inspections use, and its documentation lists the differences. The test suite (169 tests, 773 expectations, about 87 percent line coverage) covers every balance term, the regulatory checks, the exact mass balance of the prescriptions and the export formats, and runs on Windows, macOS and Linux through continuous integration.

# 3. Illustrative examples

## 3.1. A field balance

The sample field of Fert_Office is durum wheat at 6 t ha^−1^ on a silt-loam soil with imperfect drainage, after maize with stalks removed:

```r
library(NFert)
bal <- N_balance(expected_yield_tons_ha = 6, crop = "Grano duro (pianta intera)",
  ccp = "Spring-summer crop 100-130 days", sand = 15.5, clay = 18.5,
  Ntot = 1.5, SOM = 2, CN = 7.73, oxygen_availability = "Slow",
  winter_rain = 150, start_spring_rain = 0, prev_crop = "Maize stalks removed",
  source = "None", location = "Isolated plain", forg_quantity = 0)
calculate_N_fertilization(bal)                # 142.2 kg N/ha
check_MAS("Grano duro (pianta intera)", 142)  # MAS 190 kg N/ha: compliant
P_balance(6, "Grano duro (pianta intera)", olsen_value = 15, olsen_unit = "P2O5",
          clay = 18.5, sand = 15.5, total_carbonate = 15)   # 112.9 kg P2O5/ha
```

The returned object lists A = 186.6, B = 73.8, C = 0, D = 39.5 (including the −10 kg ha^−1^ of the maize stalks) and G = 10.1 kg ha^−1^. Crop names are accepted in Italian, as in Fert_Office, or in English.

## 3.2. A farm

`farm_balance()` applies the balance to every plot of a vector layer whose columns carry the inputs, and appends the dose, the MAS check and the total nitrogen per plot. For the demonstration farm shipped with the package (eight plots, 35.5 ha), the farm needs 2156 kg of mineral N (Fig. 2). The per-plot terms show where the dose comes from: legumes need no mineral N because fixation covers their demand, and slurry on the maize plots replaces most of it. The soft wheat plot reaches 190.2 kg N ha^−1^, just above its 190 kg ha^−1^ maximum, and is flagged.

![Fig. 2. Balance of the demonstration farm. (a) Mineral N dose per plot; the hatched plot exceeds its maximum allowed dose. (b) Balance terms per plot: demand and losses (A, C, D) to the right, supplies (B, E, F, G) and current-year organic N (F~org~) to the left; diamonds mark the mineral N dose.](figures/fig2_farm.pdf){width=100%}

## 3.3. From a satellite image to a machine file

The package also ships a Sentinel-2 Level-2A scene of a 3.2 ha silage maize field at the CERZOO experimental farm near Piacenza (13 August 2024). A few calls go from the image to an ISOXML task file; here the target dose is set to 200 kg N ha^−1^, whereas in practice it is the balance dose of the field (`calculate_N_fertilization()`):

```r
s2   <- system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif", package = "NFert")
bio  <- estimate_biophysical(s2, output_dir = tempdir(),
                             variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni  <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                            crop = "maize", fvc = bio$FVC)
farm <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "NFert"))
rx   <- build_strip_prescription(farm[farm$id == 3, ], machine_width = 24,
                                 cell_length = 30, variability = "nni",
                                 nni_raster = nni$NNI, n_target = 200,
                                 min_dose = 160, max_dose = 240)
export_prescription(rx, "TASKDATA", format = "isoxml")
```

The median leaf area index is 3.6 and the median NNI 1.12. Of 329 pixels, 236 are in luxury consumption, 84 optimal and 9 deficient (Fig. 3). The NNI zones first set the cells to the upper bound (deficient), the target (optimal) or the lower bound (excessive). Because most of the field is in the excessive zone, the mass-balance step then raises the free cells: 5 deficient cells receive 240, 21 optimal cells (and 2 cells without a valid NNI) 230.4 and 36 excessive cells 184.3 kg N ha^−1^. The area-weighted mean of the 64 cells of 24 m × 30 m is 200.0 kg ha^−1^ (doses are rounded to 0.1 kg), so the redistribution follows the diagnosis while the field total stays at the target dose.

![Fig. 3. From a Sentinel-2 scene to a prescription for a 3.2 ha silage maize field (13 August 2024): (a) leaf area index retrieved by Gaussian-process regression, (b) Nitrogen Nutrition Index (dashed lines on the colour bar: optimal band 0.9–1.1), (c) prescription on 24 m × 30 m cells driven by the NNI zones, with area-weighted mean equal to the 200 kg N ha^−1^ target.](figures/fig3_rs_prescription.pdf){width=100%}

## 3.4. A province, year by year

Because every input is a column, the same balance scales from one field to a province. For the Po plain of the province of Piacenza we took 17,332 fields delineated from Sentinel-2 with Fields of The World [@kerner2024ftw], each with a crop class estimated for every year from 2019 to 2026 from AlphaEarth satellite embeddings [@brown2025alphaearth], provisional for 2026. Soil inputs came from the regional 0–30 cm maps of clay, sand, organic carbon and total nitrogen [@rer_soil], averaged per field; rainfall from October to January and in February of each crop year from the ERA5 reanalysis [@hersbach2020]; expected yields from the provincial statistics of the year [@istat_coltivazioni]; and the previous crop from the class of the year before. Each estimated class was linked to a DPI crop, and maize was computed both as grain and as silage maize and weighted by their provincial areas of the year. The 126,667 field-year balances (`paper/softwarex/piacenza/`) take about five minutes on eight cores.

The nitrogen requirement of the mapped fields, before any credit for current-year organic fertilisers, ranged from 8.2 to 11.4 kt N per year over 56,000 to 72,000 ha with a known crop (Fig. 4). It followed the autumn–winter rainfall of the leaching terms (correlation 0.93 between the mean dose and the October–January rainfall): in the wet winters of 2020 and 2021 the mean dose rose to 164 and 183 kg N ha^−1^, against 137 in the dry winter of 2019, and in 2021 the balance exceeded the crop MAS on 44 percent of the area. Multiplying the mean dose of each crop by its provincial area gives 9.1 to 12.8 kt N per year for the province. ERA5 overestimates local rainfall (463 mm from October 2024 to January 2025 against 301 mm measured at a station of the plain), so these totals are an upper bound of the leaching effect.

![Fig. 4. Regulatory nitrogen requirement of the Piacenza plain, 2019–2026. (a) Requirement of the mapped fields by crop group (bars) and October–January ERA5 rainfall (line, right axis); 2026 is provisional. (b) Field dose in 2025; grey: no crop estimate or crop outside the balance (vineyards, vegetables, fallow).](figures/fig4_piacenza.pdf){width=100%}

# 4. Impact

NFert makes the Emilia-Romagna balance a reusable component instead of an end product.

**New research questions.** Because the balance is a function rather than a set of spreadsheet cells, it can be called hundreds of thousands of times inside other analyses, which opens questions that cannot be asked of Fert_Office. One is how reliable a regulatory dose is when its soil inputs come from digital soil maps. On the CERZOO experimental farm, a different farm (eight maize and wheat fields, 32 ha), we propagated the errors of the clay, sand, organic carbon and total nitrogen maps through `N_balance()` by correlated Monte Carlo (100 draws on 866 pixels of 20 m). The per-pixel dose uncertainty was 3.3 percent, 95 percent (maize) and 96 percent (wheat) of it from soil texture. Because the map residuals showed no detectable spatial structure, the standard deviation of the farm nitrogen total was at most about 0.6 percent. Under the rainfall measured in 2024 to 2025, instead, the farm dose rose by 26 percent. The scripts of this analysis are in the repository (`paper/sat/`). Other questions of the same kind are how prescription methods compare when the field total is held constant, or how much variable-rate application can redistribute nitrogen without exceeding the plan.

**Existing questions, pursued better.** The balance can be computed for every plot of a farm, for several years or per pixel of soil maps, including the open SoilGrids layers [@poggio2021], in one script that can be re-run and shared. The regulatory dose is linked to in-season Sentinel-2 diagnosis and to variable-rate equipment under an explicit mass-balance constraint, so a sensor-driven map never changes the nitrogen total that the plan justifies. Since the coefficient tables are data, the machinery can be re-parameterised for other regional guidelines that use balance methods.

**Daily practice.** For advisors, a plan becomes a script: a file of soil analyses and a field layer give the N, P and K balances, the MAS checks and the distribution plan for every plot in one run, and the version history records how each recommendation was obtained. For teaching, the package and its Shiny interface support the exercises of a precision-agriculture course [author to confirm course name, year and number of students], which go from the field balance to the export of a prescription map; students can see and change every term, which Fert_Office does not allow.

**Quality of the reference itself.** Writing the balance as code brought to light differences between the printed tables of the guidelines and Fert_Office (Section 2.3), now documented, and the Monte Carlo stress test above found a cell of the texture triangle coded with a non-existent class, which is fixed in version 1.0.0 and covered by a test. An open, tested implementation thus also serves as a check on the regulatory scheme.

**Use.** NFert is public on GitHub with a documentation website and continuous integration on three operating systems, and passes the CRAN checks [author to add download or user figures, other publications or projects that use the package, and any commercial use, if available].

**Limitations.** NFert is an R package rather than a web service, and its default parameterisation is that of one region. The balance terms of other guidelines differ in detail, and adapting them means editing the tables and, where the rules differ, the term functions. Users outside Emilia-Romagna should treat the bundled values as an example.

# 5. Conclusions

NFert is an open R implementation of the Emilia-Romagna DPI 2026 nutrient balance for nitrogen, phosphorus and potassium. It extends the balance to farms, soil maps, satellite diagnosis and variable-rate prescriptions whose field mean equals the compliant dose. Planned work covers a CRAN release, other regional parameterisations and the coupling of P and K balances with sensor data.

# Declaration of competing interest

[Author to complete. Declare any relationship with providers of the soil or remote-sensing data used with the package.]

# CRediT authorship contribution statement

[Author to complete.]

# Declaration of generative AI and AI-assisted technologies in the writing process

[Author to complete, as required by the journal: state whether and how AI-assisted tools were used in preparing the software or the manuscript.]

# Data availability

The code, the bundled example data and the scripts that produce the figures of this article (`paper/softwarex/`) and the uncertainty analysis of Section 4 (`paper/sat/`) and the provincial application of Section 3.4 (`paper/softwarex/piacenza/`) are available at https://github.com/mcroci/NFert under the MIT License [@nfert2026]. The CERZOO soil maps used in Section 4 come from a separate, proprietary mapping pipeline [author to state access conditions and credit]. The field boundaries and crop classes of Section 3.4 are distributed as aggregated results only; the regional soil maps, ERA5 and ISTAT data are public.

# Acknowledgements

The authors thank the Servizio Agricoltura Sostenibile of Regione Emilia-Romagna for publishing the DPI 2026 guidelines and the Fert_Office tool.

# Funding

This work was supported by the EOAGRITWIN project [grant number to be added].

# References
