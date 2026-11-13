# Methodological review (with tool): outline and plan

Working genre: a critical / methodological review of nitrogen recommendation
systems in precision agriculture, from regulatory balance methods to
sensor-driven variable rate, organized around the integration and
reproducibility gap, with NFert and the CERZOO case study as the open, worked
implementation. This is a "review + framework/tool" paper, not a software
paper and not a pure literature survey.

Integrity note: every reference below tagged [VERIFIED] has been checked
against a real source. Entries tagged [TO FIND] mark literature the review
needs but that the authors must curate; I will help find and verify them but
will not invent citations or claims.

---

## Candidate titles

1. From regulatory nitrogen balances to sensor-driven variable rate:
   a methodological review of nitrogen recommendation systems in precision
   agriculture, and an open, reproducible implementation.
2. Bridging the balance and the sensor: methods, tools and the reproducibility
   gap in precision nitrogen management.
3. Nitrogen recommendation systems for precision agriculture: a critical review
   of balance-based, sensor-based and model-based methods and their integration.

## Contribution (what makes it a review, not a software paper)

- A structured taxonomy of N recommendation methods and a critical comparison
  across operational dimensions (data needs, spatio-temporal resolution,
  regulatory compliance, openness, reproducibility).
- An explicit argument that the families are complementary and can be unified
  by a single mass-balance constraint linking a field budget to a spatial
  prescription.
- Identification of the openness/reproducibility gap (closed regional
  spreadsheets vs versioned open tools) and the integration gap (balance and
  remote sensing rarely coupled in one reproducible workflow).
- A demonstrably open implementation (NFert) and a real, reproducible case
  study (CERZOO) that instantiate the proposed integrated framework.

## Abstract sketch (~150-200 words; to refine)

Precision nitrogen management must match supply to crop demand in space and
time while respecting environmental regulation. The methods proposed for this
fall into a few families: regulatory nutrient balances, soil-test and
standard-dose schemes, crop-growth models, sensor-based empirical algorithms,
and biophysical diagnosis through the Nitrogen Nutrition Index. [REVIEW:
summarize the relative diffusion of these families, anchored on Corti et al.
2022: 76% empirical/VI-based, 21% mechanistic, 3% machine learning, of 151
systems.] This review compares the families across operational dimensions,
argues that they are complementary rather than competing, and shows that a
single field-level mass-balance constraint can unify a regulation-compliant
budget with an in-season, remote-sensing-driven variable-rate prescription. It
further identifies a reproducibility and integration gap: the regulatory
methods are typically locked in closed spreadsheets, and remote-sensing
diagnosis is rarely coupled to them in a versioned, open workflow. We
illustrate an open, reproducible implementation of the integrated framework
(the NFert R package) on a real maize field, comparing prescription methods
under the shared constraint, and we outline the research gaps that remain in
calibration transfer, operational NNI retrieval, validation and economics.

---

## Section-by-section outline

### 1. Introduction
- The agronomic, environmental and regulatory stakes of N management
  [@oenema2003; @nitrates1991].
- The spectrum of recommendation approaches and the central question of the
  review: how do the families compare, can they be integrated, and why is
  reproducibility a problem?
- Scope and structure of the review. State it is a methodological/critical
  review with an open worked implementation, not a systematic review.

### 2. A taxonomy of nitrogen recommendation methods
Anchor the taxonomy on the scoping review of Corti, Fassa and Bechini (2022)
[VERIFIED], then expand each family with method detail and key references.
- 2.1 Balance-based and regulatory methods. Mass-balance budgets; the DPI
  Allegato 2 terms; strengths (regulatory defensibility, transparency) and
  limits (static, coarse, calibration-bound) [@dpi2026; @guida2026].
- 2.2 Soil-test and standard-dose methods [@lyons2020]. [TO FIND: soil-test
  calibration reviews.]
- 2.3 Crop-growth and process models (DSSAT, APSIM, STICS) for N
  recommendation. [TO FIND: model-based N recommendation refs; Corti 2022 for
  the 21% share.]
- 2.4 Sensor-based empirical methods: canopy-reflectance indices, the
  calibration-curve approach, and the Holland and Schepers sufficiency index
  [@holland2010]. NDVI saturation and the red-edge alternative. [TO FIND:
  active-sensor / GreenSeeker references; red-edge index reviews.]
- 2.5 Critical-N dilution and the Nitrogen Nutrition Index as a
  biomass-normalised diagnosis [@lemaire1997; @houles2007]. [TO FIND:
  species-specific critical-N curve refs already used in the package: Justes
  1994, Plenet & Lemaire 2000, etc.]
- 2.6 Biophysical retrieval (PROSAIL inversion, Gaussian-process regression)
  as the bridge from reflectance to NNI [@estevez2022]. [TO FIND: hybrid
  retrieval reviews.]
- 2.7 Machine-learning approaches (the 3% in Corti 2022) and their data needs.
  [TO FIND.]

### 3. Integration: from the field budget to the variable-rate prescription
- The mass-balance constraint as the unifying device: the field budget sets the
  ceiling, the sensor sets the spatial pattern, the two reconciled by rescaling
  to the field mean.
- Pre-sowing vs in-season coupling; the post-season feedback loop to refine the
  balance coefficients. (Reuse the "From the field balance to the prescription"
  text already written.)
- Why integration is rare in practice and what it requires.

### 4. The reproducibility and openness gap
- Closed, region-specific spreadsheets vs open, versioned tools; the cost to
  replication and to cross-region transfer [@seibold2021].
- FAIR principles for agronomic decision-support. [TO FIND: FAIR / open-science
  in agronomy refs.]
- The case for coefficient tables as editable, inspectable objects.

### 5. An open, integrated implementation: NFert (+ CERZOO case study)
- NFert as an instantiation of the integrated framework (balance + standard
  dose + plan + spatial balance + VI engine + NNI + GPR + mass-balance VRT).
  (Reuse the Software-description prose, condensed; cite the architecture and
  the N-balance scheme figures.)
- CERZOO worked example: in-season NNI-against-LAI diagnosis and the comparison
  of prescription methods under the shared constraint (reuse the case-study
  text, the biophysical, NNI+LAI, response and prescription figures, Table 2).

### 6. Comparative discussion
- Present Table A (method families) and Table B (tools) below.
- Critical analysis: when to use which family; the evidence on variable-rate N
  effectiveness and on NUE gains. [TO FIND: meta-analyses / field-trial
  syntheses on VRA-N effectiveness and NUE.]
- Trade-offs: data and calibration cost vs spatial resolution vs regulatory
  compliance vs reproducibility.

### 7. Research gaps and outlook
- Calibration transfer (alpha_leaf, k, critical-N curves) across sites
  [@houles2007].
- Operationalising NNI retrieval (clouds, revisit, phenological windows).
- Independent validation and the economics of variable-rate N.
- Coupling balance methods with models and ML; multi-nutrient and multi-year.

### 8. Conclusions

Declarations, funding (EOAGRITWIN), references.

---

## Table A. Families of nitrogen recommendation methods (the review backbone)

Dimensions to fill per family (rows = families of section 2; the NFert column
shows which families the package implements):

| Family | Data required | Spatial res. | Timing | Regulatory fit | Openness/repro | Implemented in NFert |
|---|---|---|---|---|---|---|
| Regulatory balance | soil analysis, crop, climate, history | field | pre-sowing | high (by design) | usually closed spreadsheets | yes (N/P/K) |
| Soil-test / standard dose | soil test, crop | field | pre-sowing | high | mostly closed | yes |
| Crop-growth models | weather, soil, mgmt, params | field/zone | pre-sowing + in-season | medium | open models exist, heavy | partial (QUEFTS coupling) |
| Sensor-based empirical (VI, H&S) | canopy imagery + reference | pixel/zone | in-season | needs a balance ceiling | mixed; commercial often closed | yes |
| NNI / critical-N diagnosis | biomass + plant N (or proxies) | plot/pixel | in-season | diagnostic, not a dose | conceptual; few open tools | yes |
| Biophysical retrieval (PROSAIL/GPR) | multispectral (Sentinel-2) | pixel | in-season | input to NNI | research code, often Python/GEE | yes (pure-R) |
| Machine learning | large labelled datasets | pixel/zone | in-season | opaque | varies | no |

(Fill the empty/qualitative cells with cited evidence during drafting.)

## Table B. Tools / software landscape

| Tool | Type | Open? | Versioned? | Balance | Sensor/VRT | NNI/GPR | Notes |
|---|---|---|---|---|---|---|---|
| FertDPI / Fert_Office | regional spreadsheet | no | no | yes | no | no | reference for NFert |
| FRST | soil-test database | partly | n/a | soil-test | no | no | US [@lyons2020] |
| commercial sensor platforms | service | no | no | no | yes | partial | [TO FIND examples] |
| crop models (DSSAT/APSIM) | model | yes | yes | indirect | indirect | no | heavy, not regulatory |
| NFert | R package | yes (MIT) | yes (git) | yes (N/P/K) | yes | yes | this work |

---

## Reuse map (from the current manuscript to the review)

- Motivation gap framing -> Introduction + Section 4.
- Software-description method detail (balance terms, P/K, H&S, calibration,
  NNI, GPR) -> Section 2 (recast as a comparative taxonomy, not a feature list).
- "From the field balance to the prescription" -> Section 3 (the integration
  argument, the methodological core).
- CERZOO case study + figures (biophysical, NNI+LAI, response, prescriptions)
  -> Section 5 (the worked implementation).
- N-balance scheme and critical-N curve figures -> Sections 2.1 and 2.5.
- Impact (three communities) -> Section 7 / Conclusions.

## Verified seed references (real; checked)

- Corti M, Fassa V, Bechini L. A scoping review of side-dress nitrogen
  recommendation systems and their perspectives in precision agriculture.
  Italian Journal of Agronomy 2022;17(1):1951. doi:10.4081/ija.2021.1951.
  [VERIFIED] (151 systems; 76% empirical/VI-based, 21% mechanistic, 3% ML).
- Remote Monitoring of Crop Nitrogen Nutrition to Adjust Crop Models: A Review.
  Agriculture (MDPI) 2023;13(4):835. doi:10.3390/agriculture13040835.
  [VERIFIED title/venue; confirm authors when adding to the bib].
- Plus the 16 already-verified references in references.bib (Oenema 2003;
  Johnston 2009; DPI 2026; Fert_Office; Lyons/FRST 2020; Seibold 2021; R Core;
  Guida 2026; Nitrates Directive 1991; RR 2/2024; RR 3/2017; Holland & Schepers
  2010; terra; Estevez 2022; Lemaire & Gastal 1997; Houles 2007).

## Literature still to add (the real review work; authors to curate)

- Per-family method reviews: active optical sensors; red-edge indices;
  crop-model-based N recommendation; ML-based N recommendation.
- Evidence base on variable-rate N effectiveness and nitrogen use efficiency
  (field trials, meta-analyses).
- Species-specific critical-N curve sources (Justes 1994; Plenet & Lemaire
  2000; Sheehy 1998; Colnenne 1998; Duru 1997; van Oosterom 2010; Debaeke 2012).
- FAIR / open-science and reproducibility in agronomy.
- Regional/European integrated-production and Nitrates-Directive implementation
  studies for the regulatory framing.

Target length for a methodological review of this kind: 6000 to 9000 words,
50 to 100 references. Suggested venues: Computers and Electronics in
Agriculture; Precision Agriculture; European Journal of Agronomy; Agronomy
(review).
