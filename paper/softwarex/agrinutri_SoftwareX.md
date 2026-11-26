---
title: "agrinutri: an R package for nutrient balances and variable-rate fertiliser prescriptions from Sentinel-2"
bibliography: references.bib
link-citations: true
---

**Michele Croci**^a,\*^, **Giorgio Impollonia**^a^, **Andrea Ferrarini**^a^, **Andrea Fiorini**^a^, **Manuele Ragazzi**^a^, **Nicolaj Franceschi**^a^, **Vincenzo Tabaglio**^a^, **Stefano Amaducci**^a^

^a^ Department of Sustainable Crop Production (DI.PRO.VE.S.), Università Cattolica del Sacro Cuore, via Emilia Parmense 84, 29122 Piacenza, Italy

^\*^ Corresponding author: michele.croci@unicatt.it

# Abstract

Fertiliser doses are often set with a predictive nutrient balance, but most balance tools compute one field at a time and are not designed for scripted batch use. agrinutri is an open-source R package that computes the nitrogen, phosphorus and potassium balance for any number of fields, years or soil-map pixels, reports every term and keeps the coefficients as replaceable tables. A Sentinel-2 module redistributes the balance dose with the Nitrogen Nutrition Index into variable-rate prescriptions that keep its field mean. Advisors can thus produce traceable plans in batch, and researchers can use the recommended dose inside larger analyses. Examples follow one field from eight years of balances to an ISOXML prescription.

# Keywords

R package; Nutrient balance; Fertilisation planning; Nitrogen; Precision agriculture; Sentinel-2

```{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
```

# Code metadata

| Nr | Code metadata description | Metadata |
|----|-----------------------|--------------------------------------|
| C1 | Current code version | v1.2.2 |
| C2 | Permanent link to code/repository used for this code version | https://github.com/mcroci/agrinutri |
| C3 | Permanent link to reproducible capsule | https://doi.org/10.5281/zenodo.24562266 |
| C4 | Legal code license | MIT License |
| C5 | Code versioning system used | git |
| C6 | Software code languages, tools and services used | R |
| C7 | Compilation requirements, operating environments and dependencies | R ≥ 4.0; imports terra; optional (Suggests): sf, jsonlite, xml2, Rquefts, geodata, shiny, shinyjs, DT, ggplot2, patchwork, leaflet; tested on Windows, macOS and Linux |
| C8 | If available, link to developer documentation/manual | https://mcroci.github.io/agrinutri/ |
| C9 | Support email for questions | michele.croci@unicatt.it |

# 1. Motivation and significance

Most nitrogen fertiliser recommendations rest on a predictive balance: the crop demand for an expected yield, minus the nitrogen the soil supplies, plus the losses, minus the credits from the previous crop, past manure and atmospheric inputs. The method was formulated independently in the United States and in France [@stanford1973; @meynard1981], was later made dynamic in decision tools such as AzoFert [@machet2017] and extends to phosphorus and potassium. Its known weak point is the expected yield, which the user must set in advance [@lory2003; @ravier2016].

The method is also the reference structure of European fertilisation schemes. The Nitrates Directive requires fertiliser limits based on a balance between the foreseeable crop requirement and the nitrogen supplied by soil and fertilisers [@nitrates1991], and the Common Agricultural Policy requires Member States to offer farmers a digital tool that computes a nutrient balance at field scale [@eu2021_2115]. Countries fill this structure with their own coefficients. A comparison of ten European schemes found that France, Italy and Spain use an explicit balance, whereas Germany, the Netherlands, the United Kingdom and Ireland use corrected standards or soil indices; for the same wheat field the recommended doses differed by about 100 kg N ha^−1^, mostly because of the reference values rather than the equations [@jordanmeille2023]. The same seven-term equation is written in several Italian regional guidelines [@lazio2025; @dpi2026]. Outside Europe, balance-based plans coexist with response-curve methods and with standards for whole N, P and K budgets [@morris2018; @nafziger2022; @nrcs590].

The tools that compute such balances are web services or spreadsheets, such as webBESyD [@donauer2025] and AzoFert [@machet2017], or national algorithms run as services of the FaST platform [@fastplatform; @villalobos2020]. Process-based crop models simulate nitrogen in detail but need calibration and are not the method that recommendations prescribe [@jones2003; @keating2003; @brisson2003]. Sensor-based variable-rate methods modulate a dose that comes from elsewhere but do not compute it [@holland2010; @vizzari2019; @santaga2021]. Three uses therefore remain poorly served: computing the balance in batch over fields, years or soil-map pixels; linking the balance dose to satellite diagnosis and to variable-rate machinery without changing the total that the plan justifies; and inspecting every term and coefficient. The 2021 review of OVERSEER in New Zealand shows the cost of a nutrient budget model that users cannot inspect [@pce2021], and compatibility with the schemes advisors already use is one factor in whether they adopt a decision tool [@rose2016].

agrinutri addresses these uses as an open R package [@rcore2025]. Each balance term has its own function, each coefficient table is a replaceable dataset, and the same balance runs per field, per year or per pixel and feeds Nitrogen Nutrition Index (NNI) prescriptions exported in ISOXML. The default coefficients are those of the integrated production guidelines of Emilia-Romagna (Italy) [@dpi2026]; replacing the tables adapts the engine to another scheme without changing the code. Advisors can compute traceable plans for every field of a farm in one run, researchers can embed the recommended dose in multi-year or spatial analyses, and teachers can show how each term moves the dose.

# 2. Software description

## 2.1. Software architecture

agrinutri is a pure-R package whose only hard dependency is terra [@terra2024]; spatial vectors (sf), the Gaussian-process models (which need jsonlite) and the Shiny interface are optional. It exports 77 functions and 38 lazy-loaded datasets (Fig. 1).

![Fig. 1. agrinutri architecture. Inputs (top) feed the nutrient balance, built from one function per balance term and checked against crop maximum doses; the same balance runs per plot, per year or per pixel. The remote-sensing module derives canopy traits and the Nitrogen Nutrition Index from Sentinel-2 or unmanned aerial vehicle (UAV) imagery (GPR: Gaussian-process regression; LAI: leaf area index; Cm: leaf dry matter; CNC: canopy N content). The variable-rate functions redistribute the balance dose N\* in space while keeping its field mean, and export machine files. All coefficients are editable R tables (dashed).](figures/fig1_architecture.pdf){width=16cm}

The nitrogen balance is N = A − B + C + D − E − F − G, where A is crop demand (unit uptake × expected yield), B the soil supply from organic-matter mineralisation and readily available N, C the leaching losses in autumn–winter and at the end of winter, D immobilisation and dispersion, E the residues of the previous crop, F the residual effect of organic fertilisation in previous years and G atmospheric deposition plus biological fixation. Each term has its own exported function (`calc_crop_N_demand()`, `soil_fertility()`, `leaching_loss()`, `calc_N_immobilization_loss()`, `nitrogen_from_previous_crop_residues()`, `organic_previous_years_N()`, `natural_contribution()`). `N_balance()` composes them and returns every term, so a dose can be traced line by line. `calculate_N_fertilization()` then applies the share of the balance admitted for the crop phase and a crop ceiling (zero for legumes), and subtracts the current-year organic N. The residues of the previous crop enter E as a credit, except maize stalks, whose immobilisation is counted in D. The coefficients sit in datasets such as `uptake_table` (unit uptake, 234 crop entries), `coef_time` (time coefficients by crop phase), `mas.table` (crop maximum doses), `cb.table` (immobilisation factors) and `e.table` (previous-crop effects).

## 2.2. Software functionalities

The main functionalities are grouped in Table 1.

Table: Table 1. Main functionalities of agrinutri 1.2.2.

| Area | Functions |
|------------|------------------------------------|
| Nitrogen balance | `N_balance()`, `calculate_N_fertilization()` and one function per term |
| P~2~O~5~ and K~2~O balances | `P_balance()`, `K_balance()`, availability classes, end-of-cycle soil P and K |
| Standard-dose scheme | `dose_standard_N()`, `dose_standard_PK()` |
| Limits and plan | `get_MAS()`, `check_MAS()` (crop maximum dose), `plan_distribution()` (organic and mineral fertilisers, organic N limit of 170 kg N ha^−1^ by default) |
| Soil | texture triangle and texture groups, pH, carbonates, CEC, organic matter; `soilgrids_input()` for SoilGrids 2.0 layers [@poggio2021] |
| Scale | `farm_balance()` (one row per plot or year), `spatial_N_balance()` (one balance per pixel) |
| Remote sensing | `compute_vi()` (six indices), `estimate_biophysical()`, `compute_NNI_from_S2()`, `diagnose_N_status()` |
| Variable rate | `variable_rate_N()`, `build_strip_prescription()` |
| Coefficient tables | 38 datasets; `agrinutri_tables()` replaces any of them for the session |
| Export and interface | `export_prescription()` (ISOXML, Shapefile, GeoJSON, KML, GeoPackage, John Deere, Trimble), `run_app()` |

`run_app()` opens a Shiny interface that runs the same functions without code, from the balance of one field to the farm map and the prescription (Fig. 2).

![Fig. 2. The Shiny interface (`run_app()`), nitrogen balance tab with the inputs of plot P01 in 2024 (left) and the balance as a waterfall from crop demand A to the net mineral N dose of 175 kg N ha^−1^ (Section 3.2), with the crop maximum dose (dashed).](figures/fig2_app.png){width=16cm}

The P~2~O~5~ and K~2~O balances follow the same structure. Their doses depend on the availability class of Olsen P and exchangeable K for the texture group: enrichment, maintenance or reduction, with a carbonate-dependent P immobilisation factor and a clay-dependent K leaching term.

The remote-sensing module goes from a Sentinel-2 Level-2A scene to a nitrogen diagnosis. `estimate_biophysical()` is an R port of the Sentinel-2 Level-2A Gaussian-process regression models of the pyeogpr library [@kovacs2025; @estevez2022], a retrieval approach reviewed by Verrelst et al. [-@verrelst2015]. It estimates leaf area index, leaf dry matter, chlorophyll and canopy nitrogen content, and processes rasters in blocks so that whole tiles fit in memory. `compute_NNI_from_S2()` combines these traits into the NNI, the ratio of actual to critical N concentration along the critical dilution curve of the species [@lemaire1997; @plenet1999]. The same call classes the map into deficient (< 0.9), optimal and luxury (> 1.1) zones [@houles2007]; `diagnose_N_status()` does the same from measured N content and biomass.

The variable-rate functions turn a vegetation index, such as the normalised difference vegetation index (NDVI), or an NNI map into rates with a calibration ramp, the sufficiency index of Holland and Schepers [-@holland2010], quantile classes or NNI zones. Whatever the method, the rates are rescaled so that their area-weighted mean equals the balance dose N\* within user bounds: the map changes where nitrogen goes, not how much. `build_strip_prescription()` tiles a field along the A–B line of the machine, in the local UTM zone so that working width and cell length are true ground distances.

## 2.3. Quality assurance

The default coefficients follow the regional guidelines, and the documentation lists where the implementation departs from the printed text, for example in the mineralisation rates of sandy soils. The test suite (178 tests, 814 expectations, about 87 percent line coverage) covers every balance term, the crop maximum dose checks, the exact mass balance of the prescriptions and the export formats, and runs on Windows, macOS and Linux through continuous integration.

# 3. Illustrative examples

## 3.1. A field balance

A durum wheat field at 6 t ha^−1^ on a silt-loam soil with imperfect drainage, after maize with stalks removed:

```r
library(agrinutri)
bal <- N_balance(expected_yield_tons_ha = 6, crop = "Durum wheat (grain)",
  ccp = "Autumn-winter crop >150 days", sand = 15.5, clay = 18.5,
  Ntot = 1.5, SOM = 2, CN = 7.73, oxygen_availability = "Slow",
  winter_rain = 150, start_spring_rain = 0, prev_crop = "Maize stalks removed",
  source = "None", location = "Isolated plain", forg_quantity = 0)
calculate_N_fertilization(bal)            # 145.5 kg N/ha
check_MAS("Durum wheat (grain)", 145)     # crop maximum dose 190 kg N/ha
P_balance(6, "Durum wheat (grain)", olsen_value = 15, olsen_unit = "P2O5",
          clay = 18.5, sand = 15.5, total_carbonate = 15)   # 100.3 kg P2O5/ha
```

The returned object lists A = 186.6, B = 70.2, C = 0, D = 38.1, E = F = 0 (stalks removed) and G = 9.0 kg N ha^−1^, so that N = 186.6 − 70.2 + 38.1 − 9.0 = 145.5.

## 3.2. A farm

`farm_balance()` applies the balance to every plot of a vector layer whose columns carry the inputs, and appends the dose, the check against the crop maximum dose and the total nitrogen per plot. The illustrative farm is made of four neighbouring fields (46.7 ha) of the Po plain near Piacenza (Italy), delineated from Sentinel-2 with Fields of The World [@kerner2024ftw], one for each crop of 2024. The crops of 2024 and of 2023 (the previous crop) were estimated from AlphaEarth satellite embeddings [@brown2025alphaearth]; soil inputs are field means of the regional 0–30 cm maps of clay, sand, organic carbon, total nitrogen, Olsen P and exchangeable K [@rer_soil; @ungaro2025]; rainfall from October to January and in February comes from the ERA5 reanalysis [@hersbach2020]; and expected yields are the provincial yields of 2024 [@istat_coltivazioni], or reference yields where these are missing. The farm needs 6.8 t of nitrogen before any organic fertiliser and before the crop maximum doses are applied (Fig. 3). The terms show where each dose comes from: after processing tomato, soft and durum wheat receive a residue credit of 30 kg N ha^−1^ (term E) and need 134 and 105 kg N ha^−1^, and leaching adds about 60 kg N ha^−1^ to every plot. The processing tomato reaches 193 kg N ha^−1^, above its crop maximum dose of 180 kg N ha^−1^, and is flagged. The standard-dose scheme (`dose_standard_N()`) gives one value per crop instead: 240 kg N ha^−1^ for maize against a balance of 175, 130 for processing tomato against 193.

![Fig. 3. Nitrogen balance of a farm of four satellite-delineated fields in the Po plain, crop year 2024. (a) Mineral N dose per plot; the outlined plot exceeds its crop maximum dose. (b) Balance terms per plot, demand and losses to the right (A crop demand, C leaching, D immobilisation) and supplies to the left (B soil supply, E previous crop, F past organic inputs, G deposition and fixation), with the balance dose and the standard dose. Plot P01 is the field of Figs. 4–7.](figures/fig3_farm.pdf){width=16cm}

## 3.3. Nitrogen in one field through the rotation

The balance runs over years as easily as over plots. Plot P01 follows a wheat–processing tomato rotation typical of the plain, with maize in 2024 and, in 2026, a summer crop computed as soybean (Fig. 4). The inputs are those of Section 3.2 for each year; 2025 and 2026 use reference yields because provincial statistics are not yet published, and the crop of 2026 is provisional. With the soil fixed, the balance dose of the non-legume crops ranged from 131 to 220 kg N ha^−1^. Besides the crop and its expected yield, two terms drive the change. The October–January and February rainfall set a leaching term C of 40 to 62 kg N ha^−1^. The previous crop sets the credits and losses: wheat after tomato receives a residue credit of 30 kg N ha^−1^ (term E), whereas durum wheat after maize in 2025 carries 40 kg N ha^−1^ more immobilisation (term D) and, after 445 mm of October–January rain, reaches 220 kg N ha^−1^. That dose, the 195 kg N ha^−1^ of durum wheat in the wet winter of 2021 and the 187 of processing tomato in 2020 exceed the crop maximum dose, which then sets the plan. In 2026 biological fixation (term G) supplies most of the demand of the legume, and its crop ceiling of zero means that no mineral N is prescribed.

![Fig. 4. Nitrogen balance of plot P01 through the rotation 2019–2026: balance terms per year, balance dose and crop maximum dose. Under each crop: October–January + February rainfall (ERA5). The axis is cut at −130; the 2026 deposition and fixation term G is −208 kg N ha^−1^. The crop of 2026 (other summer crops, computed as soybean) is provisional.](figures/fig4_p01_years.pdf){width=16cm}

## 3.4. Organic and mineral fertilisers

`plan_distribution()` splits a dose between organic and mineral fertilisers. For P01 in 2024 (N\* = 175 kg N ha^−1^), 30 t ha^−1^ of dairy slurry bring 153 kg N ha^−1^, below the organic N limit of 170. The distribution efficiency sets how much of it counts: 26, 41 or 55 percent (40, 62 or 85 kg N ha^−1^), so urea makes up 135, 113 or 90 kg N ha^−1^.

## 3.5. Phosphorus and potassium

The P~2~O~5~ and K~2~O balances run on the same inputs and depend on soil availability (Fig. 5). Around the farm the regional maps classify Olsen P as high or very high on 71 percent of the pixels and exchangeable K as low or very low on 81 percent. Plot P01 follows the same pattern. Its field-mean Olsen P of 17 mg kg^−1^ (as P) is in the high class, for which the strategy is maintenance, a dose equal to crop removal, from 39 to 91 kg P~2~O~5~ ha^−1^ across the rotation. Its 88 mg kg^−1^ of exchangeable K (as K) on a loamy soil is in the low class, for which the strategy is enrichment, from 118 to 164 kg K~2~O ha^−1^ and up to 300 kg ha^−1^ for processing tomato.

![Fig. 5. Phosphorus and potassium. (a) P~2~O~5~ and K~2~O doses of plot P01 through the rotation 2019–2026. (b) Olsen P and (c) exchangeable K availability classes on the regional 100 m soil maps (0–30 cm) around the farm of Fig. 3, with the four plots outlined and P01 in bold.](figures/fig5_pk.pdf){width=16cm}

## 3.6. From a satellite image to a machine file

In 2024 plot P01, the 8.6 ha maize field of Fig. 3, illustrates the remote-sensing chain on the Sentinel-2 Level-2A scene of 21 July 2024, with the maize at about the tenth leaf, in the top-dressing window. A few calls go from the image to an ISOXML task file; the target is the balance dose of the plot, N\* = 175 kg N ha^−1^ (Section 3.2), and the cell doses may range between 80 and 120 percent of it:

```r
bio   <- estimate_biophysical("s2_20240721.tif", output_dir = tempdir(),
                              variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni   <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                             crop = "maize", fvc = bio$FVC)
field <- sf::st_read("field.geojson")
rx    <- build_strip_prescription(field, machine_width = 24, cell_length = 30,
                                  variability = "nni", nni_raster = nni$NNI,
                                  n_target = 175, min_dose = 140, max_dose = 210,
                                  edge_buffer = 10)
export_prescription(rx, "TASKDATA", format = "isoxml")
```

The median leaf area index is 2.4 and the median NNI 1.11. Of 733 pixels with a valid NNI (biomass of at least 1 t ha^−1^), 408 are in luxury consumption, 239 optimal and 86 deficient (Fig. 6); `edge_buffer = 10` excludes the boundary pixels, which mix crop and margin. Low NNI and leaf area index still reach about 30 m into the headlands, whether from crop status or edge effects; a 20 or 30 m buffer leaves 8 or 3 cells at the upper bound instead of 12. After the mass balance, 12 deficient cells receive 210, 49 optimal cells (and 38 without a valid NNI) 190.3 and 53 luxury cells 152.2 kg N ha^−1^; the area-weighted mean of the 152 cells is 175.0 kg N ha^−1^, so the map follows the diagnosis while the field total stays at the balance dose (Fig. 6, steps 6–8). Two days earlier, from another orbit, the median NNI was 0.91: the retrieved NNI is better read as a map of relative status within the field than as an absolute diagnosis.

![Fig. 6. How the prescription of plot P01 is built (Sentinel-2 Level-2A, 21 July 2024; N\* = 175 kg N ha^−1^, bounds 140–210): (1) the scene; (2) leaf area index retrieved by Gaussian-process regression; (3) Nitrogen Nutrition Index; (4) NNI zones (deficient < 0.9, optimal, luxury > 1.1; dashed: the 10 m inward buffer); (5) the 24 m × 30 m machine grid along the A–B line; (6) first dose of each cell from its zone; (7) doses after the mass balance, field mean 175.0; (8) the ISOXML task file written by `export_prescription()`.](figures/fig6_prescription.pdf){width=16cm}

## 3.7. Precision-agriculture methods

The main ways of distributing a dose inside a field can be compared on the same cells (Fig. 7). Each method maps a sensed layer to cell doses, then rescales them so that the field mean stays at N\* = 175 kg N ha^−1^ within 140 to 210 kg N ha^−1^. The uniform rate ignores the sensed layers. The two calibration ramps of `build_strip_prescription()` move nitrogen towards low-vigour or high-vigour areas: a line between two anchors (NDVI 0.60 and 0.90, as far apart as the 5th and 95th percentiles of the cell NDVI), flat at the dose bounds beyond them, placed so that its field mean is the balance dose; the quantile classes turn the NDVI into five steps; the NNI management zones change mainly the deficient and luxury cells, and the optimal cells move (190.3) to keep the mean; the Holland–Schepers sufficiency index of `variable_rate_N()` follows a curve on the NDVI, with the 95th percentile of the field NDVI as the well-fertilised reference. All six maps keep the field mean at N\*.

![Fig. 7. Precision-agriculture methods on plot P01 (2024), all redistributing the balance dose N\* = 175 kg N ha^−1^ within 80 to 120 percent of it, on 24 m × 30 m cells: (a) uniform rate; (b, c) calibration ramps on the NDVI of 21 July 2024, inverse and direct; (d) five NDVI quantile classes; (e) Nitrogen Nutrition Index (NNI) zones; (f) Holland–Schepers sufficiency index, computed per pixel and averaged to the cells. Every map keeps the area-weighted mean at 175 kg N ha^−1^; all maps share the dose scale.](figures/fig7_strategies.pdf){width=16cm}

# 4. Impact

agrinutri turns a nutrient balance into a reusable component.

**New research questions.** Because the balance is a function rather than a set of spreadsheet cells, it can be called more than 100,000 times inside other analyses. One example is how the nitrogen requirement of a whole plain changes from year to year with the rainfall of the leaching terms. With the inputs of Section 3.2 we ran 126,667 field-year balances for the 17,332 fields of the Po plain in the province of Piacenza from 2019 to 2026, in about five minutes on eight cores. The requirement of the mapped fields, before any credit for current-year organic fertilisers, ranged from 8.2 to 11.4 kt N per year over 56,000 to 72,000 ha with a known crop. It followed the October–January rainfall (correlation 0.93 with the mean dose; n = 8 years), and in the wet winter of 2021 the balance exceeded the crop maximum dose on 44 percent of the area. ERA5 rainfall exceeded a station record of the plain (463 against 301 mm, October 2024 to January 2025), so these totals are likely an upper bound. Other questions are how much of the dose uncertainty comes from the soil maps, and how prescription methods compare when the field total is held constant.

**Existing questions, pursued better.** The balance can be computed for every plot of a farm, for several years or per pixel of soil maps, including the open SoilGrids layers [@poggio2021], in one script that can be re-run and shared. A sensor-driven map never changes the nitrogen total that the plan justifies.

**Transferability.** Since the coefficient tables are data, the engine can be re-parameterised for other schemes that use the same balance structure, such as other Italian regional guidelines [@lazio2025]; schemes based on corrected standards or soil indices [@jordanmeille2023] may be adapted by editing the term functions. `agrinutri_tables()` replaces any bundled table for the session: raising the unit N uptake of `uptake_table` by 10 percent raises the doses of P01 by 15 to 22 kg N ha^−1^, while the legume of 2026 stays at zero (Fig. 8). Only the default parameter set is implemented and tested so far; a second parameter set is planned.

![Fig. 8. Re-parameterising the balance. (a) An edited copy of `uptake_table` replaces the bundled table for every later call, until `agrinutri_tables()` is called without arguments. (b) Balance doses of plot P01, 2019–2026, with the bundled table and with the unit N uptake raised by 10 percent.](figures/fig8_tables.pdf){width=16cm}

**Daily practice.** For advisors, a plan becomes a script: a file of soil analyses and a field layer give the N, P and K balances, the crop maximum dose checks and the distribution plan for every plot in one run, and the version history records how each recommendation was obtained. For teaching, the package and its Shiny interface are designed for exercises that go from the field balance to the export of a prescription map; students can see and change every term.

**Use.** agrinutri is public on GitHub with a documentation website, vignettes on bundled real data and continuous integration on three operating systems; `R CMD check` runs on each of them at every change. The package was first released publicly in October 2026, so no usage figures are available yet.

**Limitations.** agrinutri is an R package rather than a web service, and its default coefficients are those of one region. Adapting other schemes means editing the tables and, where the rules differ, the term functions.

# 5. Conclusions

agrinutri is an open-source R package for the predictive nutrient balance of nitrogen, phosphorus and potassium. It applies the balance to fields, farms, years and soil maps, returns every term, and links the balance dose to satellite diagnosis and to variable-rate prescriptions whose field mean equals that dose. Planned work covers a CRAN release, further parameter sets and the coupling of P and K balances with sensor data.

# Declaration of competing interest

The authors declare that they have no known competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.

# CRediT authorship contribution statement

**Michele Croci:** Conceptualization, Methodology, Software, Validation, Formal analysis, Data curation, Visualization, Writing – original draft, Writing – review & editing. **Giorgio Impollonia:** Methodology, Software, Writing – review & editing. **Andrea Ferrarini:** Conceptualization, Methodology, Writing – review & editing. **Andrea Fiorini:** Validation, Writing – review & editing. **Manuele Ragazzi:** Validation, Resources, Writing – review & editing. **Nicolaj Franceschi:** Data curation, Writing – review & editing. **Vincenzo Tabaglio:** Supervision, Writing – review & editing. **Stefano Amaducci:** Conceptualization, Supervision, Resources, Project administration, Writing – review & editing.

# Declaration of generative AI and AI-assisted technologies in the writing process

During the preparation of this work the authors used Claude (Anthropic) to assist with code development, figure scripts and language editing of the manuscript. After using this tool, the authors reviewed and edited the content as needed and take full responsibility for the content of the publication.

# Data availability

The code, the bundled example data and the scripts that produce the figures of this article (`paper/softwarex/`, including the provincial application of Section 4 in `paper/softwarex/piacenza/`) are available at https://github.com/mcroci/agrinutri under the MIT License [@agrinutri2026]. The four field boundaries of Sections 3.2 to 3.7, with their crop classes and balance inputs, the Sentinel-2 scene of 21 July 2024 over plot P01 and a clip of the regional soil maps are bundled with the package (`?piacenza`); the other fields of Section 4 are distributed as aggregated results only; the regional soil maps [@rer_soil], Sentinel-2, ERA5 and provincial yield statistics are public.

# Acknowledgements

The authors thank the Sustainable Agriculture Service of the Emilia-Romagna Region for publishing the integrated production guidelines.

# References
