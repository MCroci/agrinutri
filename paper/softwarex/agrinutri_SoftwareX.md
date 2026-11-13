---
title: "agrinutri: an R package for regulatory nutrient balances and variable-rate nitrogen prescriptions"
bibliography: references.bib
link-citations: true
---

**Michele Croci**^a,\*^, **Giorgio Impollonia**^a^, **Andrea Ferrarini**^a^, **Andrea Fiorini**^a^, **Manuele Ragazzi**^a^, **Nicolaj Franceschi**^a^, **Vincenzo Tabaglio**^a^, **Stefano Amaducci**^a^

^a^ Department of Sustainable Crop Production (DI.PRO.VE.S.), Università Cattolica del Sacro Cuore, via Emilia Parmense 84, 29122 Piacenza, Italy

^\*^ Corresponding author: michele.croci@unicatt.it

# Abstract

Regional nitrogen balances set legal fertiliser doses but are distributed as closed spreadsheets that compute one field at a time. agrinutri is an open-source R package that implements the nitrogen, phosphorus and potassium balance of the Emilia-Romagna Integrated Production Guidelines (DPI 2026), returns every balance term so that a dose can be audited, and keeps all coefficients as editable data. The balance runs per plot or per soil-map pixel, and a Sentinel-2 module turns the Nitrogen Nutrition Index into variable-rate prescriptions whose field mean equals the balance dose. In a Monte Carlo analysis on a real farm, soil-map error made the farm nitrogen total uncertain by less than 1 percent.

# Keywords

R package; Nutrient balance; Fertilisation planning; Regulatory compliance; Precision agriculture; Sentinel-2

# Code metadata

| Nr | Code metadata description | Metadata |
|----|-----------------------|--------------------------------------|
| C1 | Current code version | v1.0.1 |
| C2 | Permanent link to code/repository used for this code version | https://github.com/mcroci/agrinutri |
| C3 | Permanent link to reproducible capsule | https://doi.org/10.5281/zenodo.24202414 |
| C4 | Legal code license | MIT License |
| C5 | Code versioning system used | git |
| C6 | Software code languages, tools and services used | R |
| C7 | Compilation requirements, operating environments and dependencies | R ≥ 4.0; imports terra; optional (Suggests): sf, jsonlite, xml2, Rquefts, geodata, shiny, shinyjs, DT, ggplot2, patchwork, leaflet; tested on Windows, macOS and Linux |
| C8 | If available, link to developer documentation/manual | https://mcroci.github.io/agrinutri/ |
| C9 | Support email for questions | michele.croci@unicatt.it |

# 1. Motivation and significance

Nitrogen fertilisation plans in the European Union are written under two sets of rules. The Nitrates Directive caps livestock manure at 170 kg N ha^−1^ in Nitrate Vulnerable Zones [@nitrates1991], and regional integrated-production schemes set crop-specific maximum allowed doses (MAS) and require the dose to be justified by a nutrient balance. Balance methods are well established [@oenema2003], but in practice they reach farms through regional software. In Emilia-Romagna (Italy) the Integrated Production Guidelines (Disciplinari di Produzione Integrata, DPI 2026) [@dpi2026; @guida2026] and the maximum doses of Regional Regulation 2/2024 [@rr2_2024] are applied with Fert_Office, an Excel workbook distributed by the Region [@fertoffice2026]. A plan is computed one field at a time by filling in input cells, and the result is what an inspection checks against.

A spreadsheet of this kind serves its purpose for one advisor and one field. It does not serve three other uses. The first is batch computation, over every plot of a farm, over several years or over a grid of soil-map pixels. The second is linking the regulatory dose to in-season information, such as satellite estimates of crop nitrogen status, and to variable-rate equipment, while staying within the dose that the plan justifies. The third is inspection: the formulas are spread over about 40 linked sheets, so it is hard to see why a dose has a given value, to change a coefficient, or to reproduce a plan independently.

Open tools exist around this gap, but none of them fills it. Soil-test databases such as FRST make calibration data public but do not compute plans [@lyons2020]. Process-based crop models such as DSSAT, APSIM and STICS simulate nitrogen dynamics in detail [@jones2003; @keating2003; @brisson2003], but they need calibration and are not the method that a regulation prescribes. Nutrient-balance software for other regulations, such as webBESyD for the German rules, is offered as a web service rather than as a library [@donauer2025]. Sentinel-2 tools for variable-rate nitrogen, such as AgroSat and the simplified prescriptions tested on Italian wheat, set rates from canopy reflectance but do not compute the regulatory balance [@hamie2026; @vizzari2019; @santaga2021]. The evidence that sensor-based rates improve management also varies with context [@holland2010; @diacono2013; @colaco2018; @basso2016]. What is missing is an open implementation of the regulatory balance itself that remote-sensing and variable-rate methods can build on. Compatibility with compliance demands is one of the factors that decide whether farmers and advisors adopt a decision-support tool [@rose2016], and the Common Agricultural Policy now requires Member States to offer farmers a digital Farm Sustainability Tool for Nutrients [@eu2021_2115], which such an engine could serve.

agrinutri provides that implementation in R [@rcore2025]. It computes the Emilia-Romagna balance for nitrogen, phosphorus and potassium as Fert_Office does, keeps every coefficient table as an editable R dataset, and adds the spatial and remote-sensing steps that Fert_Office lacks. The intended users are farm advisors producing plans in batch, researchers who need the regulatory dose as a model component, and teachers of nutrient management.

# 2. Software description

## 2.1. Software architecture

agrinutri is a pure-R package whose only hard dependency is terra [@terra2024]; spatial vectors (sf), the Gaussian-process models (which need jsonlite), the QUEFTS economic optimum (Rquefts) and the Shiny interface are optional. It exports 76 functions and 38 lazy-loaded datasets. The design follows the structure of the regulation (Fig. 1).

![Fig. 1. agrinutri architecture. Inputs (top) feed the DPI 2026 balance, built from one function per balance term and checked against the regulatory limits; the same balance is applied per plot or per pixel. The remote-sensing module derives canopy traits and the Nitrogen Nutrition Index from Sentinel-2 or UAV imagery. The variable-rate functions redistribute the balance dose N* in space under a mass-balance constraint and export machine files. All coefficients are editable R datasets (dashed).](figures/fig1_architecture.pdf){width=100%}

The nitrogen balance is N = A − B + C + D − E − F − G, where A is crop demand (unit uptake × expected yield), B the soil supply from organic-matter mineralisation and readily available N, C the leaching losses in autumn–winter and at the end of winter, D immobilisation and dispersion, E the residues of the previous crop, F the residual effect of organic fertilisation in previous years and G atmospheric deposition plus biological fixation. Each term has its own exported function (`calc_crop_N_demand()`, `soil_fertility()`, `leaching_loss()`, `calc_N_immobilization_loss()`, `nitrogen_from_previous_crop_residues()`, `organic_previous_years_N()`, `natural_contribution()`). `N_balance()` composes them and returns every term, so a dose can be audited line by line. `calculate_N_fertilization()` then applies the share of the balance admitted for the crop phase and the crop ceiling, and subtracts the current-year organic N. The coefficients sit in datasets such as `uptake_table` (unit uptake, 235 crop entries), `coef_time` (time coefficients by crop phase), `mas.table` (maximum allowed doses), `cb.table` (immobilisation factors) and `e.table` (previous-crop effects). Replacing a table re-parameterises the balance for another guideline without touching the code.

## 2.2. Software functionalities

The main functionalities are grouped in Table 1.

Table: Table 1. Main functionalities of agrinutri 1.0.0.

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

Where the printed tables of the guidelines (Norme Generali, Annex 2, 2024/25 edition) and Fert_Office differ, for example in the mineralisation rates of sandy soils and the immobilisation factors of poorly drained soils, agrinutri follows Fert_Office, the tool that inspections use, and its documentation lists the differences. The test suite (169 tests, 773 expectations, about 87 percent line coverage) covers every balance term, the regulatory checks, the exact mass balance of the prescriptions and the export formats, and runs on Windows, macOS and Linux through continuous integration.

# 3. Illustrative examples

## 3.1. A field balance

The sample field of Fert_Office is durum wheat at 6 t ha^−1^ on a silt-loam soil with imperfect drainage, after maize with stalks removed:

```r
library(agrinutri)
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

`farm_balance()` applies the balance to every plot of a vector layer whose columns carry the inputs, and appends the dose, the MAS check and the total nitrogen per plot. The example farm is made of eight neighbouring fields of the Piacenza plain delineated from Sentinel-2 (57.5 ha), with the crop of 2024 and of 2023 (the previous crop) estimated from satellite data, soil inputs from the regional soil maps, the October–January rainfall from ERA5 and the provincial yields of 2024, as in Section 3.5. The farm needs 9.7 t of nitrogen before any organic fertiliser (Fig. 2). The per-plot terms show where the dose comes from: the soybean plot needs no mineral N because fixation covers its demand; the durum wheat after processing tomato gets a residue credit of 30 kg N ha^−1^ and needs 110 kg N ha^−1^ against 179 after maize; and the autumn–winter leaching adds about 60 kg N ha^−1^ to every plot. The soft wheat plot reaches 213 kg N ha^−1^, above its 180 kg ha^−1^ maximum, and is flagged.

![Fig. 2. Balance of a farm of eight satellite-delineated fields of the Piacenza plain, crop year 2024. (a) Mineral N dose per plot; the outlined plot exceeds its maximum allowed dose; grey: neighbouring fields. (b) Balance terms per plot: demand and losses (A, C, D) to the right, supplies (B, E, F, G) to the left; diamonds mark the dose. Plot P01 is the field of Fig. 3.](figures/fig2_farm.pdf){width=100%}

## 3.3. From a satellite image to a machine file

Plot P01 of the farm in Fig. 2, a maize field of 10.2 ha delineated from Sentinel-2 with Fields of The World [@kerner2024ftw], illustrates the remote-sensing chain on the Level-2A scene of 13 August 2024. A few calls go from the image to an ISOXML task file; the target is the balance dose of the plot, N\* = 189 kg N ha^−1^ (Section 3.2), and the cell doses may range between 80 and 120 percent of it:

```r
bio   <- estimate_biophysical("s2_20240813.tif", output_dir = tempdir(),
                              variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni   <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                             crop = "maize", fvc = bio$FVC)
field <- sf::st_read("field.geojson")
rx    <- build_strip_prescription(field, machine_width = 24, cell_length = 30,
                                  variability = "nni", nni_raster = nni$NNI,
                                  n_target = 189, min_dose = 151.2, max_dose = 226.8)
export_prescription(rx, "TASKDATA", format = "isoxml")
```

The median leaf area index is 3.7 and the median NNI 1.09. Of 977 pixels, 368 are in luxury consumption, 565 optimal and 44 deficient (Fig. 3). The NNI zones first set the cells to the upper bound (deficient), the target (optimal) or the lower bound (excessive). The mass-balance step then shifts the free cells so that the field mean is preserved: 8 deficient cells receive 226.8, 98 optimal cells (and 18 cells without a valid NNI) 201.3 and 50 excessive cells 161.0 kg N ha^−1^. The area-weighted mean of the 174 cells of 24 m × 30 m is 189.0 kg ha^−1^ (doses are rounded to 0.1 kg), so the redistribution follows the diagnosis while the field total stays at the balance dose.

![Fig. 3. From a Sentinel-2 scene to a prescription for plot P01 of Fig. 2, a 10.2 ha maize field (13 August 2024): (a) leaf area index retrieved by Gaussian-process regression, (b) Nitrogen Nutrition Index (dashed lines on the colour bar: optimal band 0.9–1.1), (c) prescription on 24 m × 30 m cells driven by the NNI zones, with area-weighted mean equal to the balance dose of the plot (189 kg N ha^−1^).](figures/fig3_rs_prescription.pdf){width=100%}

## 3.4. Every method on the same farm

The package offers several ways to set the rate, and on the same farm they can be compared directly (Fig. 4). At field level, the standard-dose scheme (`dose_standard_N()`) gives one value per crop, whereas the balance responds to the field: for maize the standard dose is 240 kg N ha^−1^ against a balance of 179 to 189; for durum wheat it is 160 against 179 after maize and 110 after processing tomato; for soft wheat it is 155 against a balance of 213 that exceeds the MAS. Within plot P01, the five strip strategies of `build_strip_prescription()` and the Holland–Schepers curve of `variable_rate_N()` redistribute the balance dose N\* = 189 kg N ha^−1^ within 151 to 227 kg N ha^−1^ and keep the field mean, from no contrast (uniform) to the strongest contrast of the NDVI quantile classes.

![Fig. 4. Every rate-setting method on the farm of Fig. 2 (2024). (a) Field level: balance dose and standard dose per plot; orange bars: crop MAS. (b) Within plot P01: area-weighted distribution of the cell dose for six methods that redistribute the balance dose (dotted line, 189 kg N ha^−1^; bounds 80 to 120 percent); box: quartiles, whiskers: 1.5 times the interquartile range. (c) The same prescriptions on the 24 m × 30 m cells, as difference from the balance dose, with their area-weighted mean.](figures/fig4_methods.pdf){width=100%}

## 3.5. A province, year by year

Because every input is a column, the same balance scales from one field to a province. For the Po plain of the province of Piacenza we took 17,332 fields delineated from Sentinel-2 with Fields of The World [@kerner2024ftw], each with a crop class estimated for every year from 2019 to 2026 from AlphaEarth satellite embeddings [@brown2025alphaearth], provisional for 2026. Soil inputs came from the regional 0–30 cm maps of clay, sand, organic carbon and total nitrogen [@rer_soil], averaged per field; rainfall from October to January and in February of each crop year from the ERA5 reanalysis [@hersbach2020]; expected yields from the provincial statistics of the year [@istat_coltivazioni]; and the previous crop from the class of the year before. Each estimated class was linked to a DPI crop, and maize was computed both as grain and as silage maize and weighted by their provincial areas of the year. The 126,667 field-year balances (`paper/softwarex/piacenza/`) take about five minutes on eight cores.

The nitrogen requirement of the mapped fields, before any credit for current-year organic fertilisers, ranged from 8.2 to 11.4 kt N per year over 56,000 to 72,000 ha with a known crop (Fig. 5). It followed the autumn–winter rainfall of the leaching terms (correlation 0.93 between the mean dose and the October–January rainfall): in the wet winters of 2020 and 2021 the mean dose rose to 164 and 183 kg N ha^−1^, against 137 in the dry winter of 2019, and in 2021 the balance exceeded the crop MAS on 44 percent of the area. Multiplying the mean dose of each crop by its provincial area gives 9.1 to 12.8 kt N per year for the province. ERA5 overestimates local rainfall (463 mm from October 2024 to January 2025 against 301 mm measured at a station of the plain), so these totals are an upper bound of the leaching effect.

![Fig. 5. Regulatory nitrogen requirement of the Piacenza plain, 2019–2026. (a) Requirement of the mapped fields by crop group (bars) and October–January ERA5 rainfall (line, right axis); 2026 is provisional. (b) Field dose in 2024; grey: no crop estimate or crop outside the balance (vineyards, vegetables, fallow); box: the farm of Fig. 2.](figures/fig5_piacenza.pdf){width=100%}

# 4. Impact

agrinutri makes the Emilia-Romagna balance a reusable component instead of an end product.

**New research questions.** Because the balance is a function rather than a set of spreadsheet cells, it can be called hundreds of thousands of times inside other analyses, which opens questions that cannot be asked of Fert_Office. Section 3.5 is one example: how the regulatory nitrogen requirement of a whole plain changes from year to year with the rainfall of the leaching terms, and how often the balance exceeds the crop maximum. Others are how much of the dose uncertainty comes from the soil maps that feed the balance, which can be propagated by drawing the soil inputs and re-running the balance; how prescription methods compare when the field total is held constant; or how much variable-rate application can redistribute nitrogen without exceeding the plan.

**Existing questions, pursued better.** The balance can be computed for every plot of a farm, for several years or per pixel of soil maps, including the open SoilGrids layers [@poggio2021], in one script that can be re-run and shared. The regulatory dose is linked to in-season Sentinel-2 diagnosis and to variable-rate equipment under an explicit mass-balance constraint, so a sensor-driven map never changes the nitrogen total that the plan justifies. Since the coefficient tables are data, the machinery can be re-parameterised for other regional guidelines that use balance methods.

**Daily practice.** For advisors, a plan becomes a script: a file of soil analyses and a field layer give the N, P and K balances, the MAS checks and the distribution plan for every plot in one run, and the version history records how each recommendation was obtained. For teaching, the package and its Shiny interface support the exercises of a precision-agriculture course [author to confirm course name, year and number of students], which go from the field balance to the export of a prescription map; students can see and change every term, which Fert_Office does not allow.

**Quality of the reference itself.** Writing the balance as code brought to light differences between the printed tables of the guidelines and Fert_Office (Section 2.3), now documented, and a stress test that perturbed the soil inputs found a cell of the texture triangle coded with a non-existent class, which is fixed in version 1.0.0 and covered by a test. An open, tested implementation thus also serves as a check on the regulatory scheme.

**Use.** agrinutri is public on GitHub with a documentation website and continuous integration on three operating systems, and passes the CRAN checks [author to add download or user figures, other publications or projects that use the package, and any commercial use, if available].

**Limitations.** agrinutri is an R package rather than a web service, and its default parameterisation is that of one region. The balance terms of other guidelines differ in detail, and adapting them means editing the tables and, where the rules differ, the term functions. Users outside Emilia-Romagna should treat the bundled values as an example.

# 5. Conclusions

agrinutri is an open R implementation of the Emilia-Romagna DPI 2026 nutrient balance for nitrogen, phosphorus and potassium. It extends the balance to farms, soil maps, satellite diagnosis and variable-rate prescriptions whose field mean equals the compliant dose. Planned work covers a CRAN release, other regional parameterisations and the coupling of P and K balances with sensor data.

# Declaration of competing interest

[Author to complete.]

# CRediT authorship contribution statement

[Author to complete.]

# Declaration of generative AI and AI-assisted technologies in the writing process

[Author to complete, as required by the journal: state whether and how AI-assisted tools were used in preparing the software or the manuscript.]

# Data availability

The code, the bundled example data and the scripts that produce the figures of this article (`paper/softwarex/`, including the provincial application of Section 3.5 in `paper/softwarex/piacenza/`) are available at https://github.com/mcroci/agrinutri under the MIT License [@agrinutri2026]. The field boundaries and crop classes of Sections 3.2 to 3.5 are distributed as aggregated results only; the regional soil maps [@rer_soil], Sentinel-2, ERA5 and ISTAT data are public.

# Acknowledgements

The authors thank the Servizio Agricoltura Sostenibile of Regione Emilia-Romagna for publishing the DPI 2026 guidelines and the Fert_Office tool.

# References
