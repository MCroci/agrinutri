# Materials and methods (draft v2) : NFert SAT paper

Draft of Section 2, revised after the multi-lens review. Decisions applied: the
soil machine-learning spatialization is DESCOPED to a cited input layer (not a full
in-paper method); the uncertainty propagation uses CORRELATED draws and leads with
the hold-out (LOPO) RMSE rather than the optimistic bootstrap; the cross-scale
result is a spatial-correlation model rather than an assumed independent-vs-systematic
contrast. Conventions: no em or en dashes (ranges as "X to Y"); colon separators;
literal accents; SI units. Integrity: numbers tagged `[confirm]` come from code or
data and must be checked; `[CITATION NEEDED: ...]` marks a real source the co-authors
must supply (no DOI is invented here).

---

## 2. Materials and methods

### 2.1 Overview

NFert is an open-source R package (version 0.14.0, MIT license) that implements the
Emilia-Romagna Integrated Production regulation (Disciplinari di Produzione
Integrata, DPI 2026, Allegato 2) nitrogen balance and couples it, under a single
field-level mass-balance constraint, to a Sentinel-2 diagnosis of crop nitrogen
status and to a variable-rate prescription. The same balance is evaluated at three
nested scales, from the pixel to the territory, and the uncertainty of its soil
inputs is propagated through it by Monte Carlo. The workflow has four stages: (i)
the soil properties and their uncertainty, taken as an input layer (Section 2.2);
(ii) the regulatory nitrogen balance that returns a compliant field dose (Section
2.3); (iii) an in-season diagnosis of nitrogen status and a mass-balance-constrained
variable-rate step (Sections 2.4 and 2.5); and (iv) the propagation of the soil
uncertainty and the aggregation of the balance across scales (Sections 2.6 and 2.7).
All computations are scripted against the package public functions and are
reproducible from the archived code and data (Section 2.8).

### 2.2 Soil properties and their uncertainty (input layer)

The nitrogen balance is a function of soil texture and of soil carbon and nitrogen,
so a spatially explicit and uncertainty-aware estimate of these properties is the
first input to the workflow. For the case study, clay, sand, organic carbon and
total nitrogen and their per-pixel uncertainty were estimated from [confirm 20]
georeferenced soil samples and a bare-soil Sentinel-2 Level-2A composite by a
validated multi-model machine-learning spatialization (gradient-boosting and
random-forest regressors, selected by spatial leave-one-point-out cross-validation,
with a bootstrap estimate of the per-pixel prediction uncertainty and an
area-of-applicability mask) [CITATION NEEDED: the soil-spatialization method,
companion work]. This estimation is a separate contribution and is not the subject
of this paper: here the prediction and uncertainty rasters are taken as the soil
input layer, and NFert propagates their uncertainty through the balance (Section
2.6). The maps used have hold-out errors within the laboratory range and an
area-of-applicability covering [confirm 80 to 91] percent of the mapped area; the
prescription is reported only within the area of applicability, and the fraction of
each field and of the territory lying outside it is stated, since the estimate is
extrapolated there.

Because a bootstrap standard deviation can understate the total prediction error,
the hold-out (leave-one-point-out) RMSE of each soil property was used as the
primary, more conservative soil-input uncertainty, and the bootstrap raster was
propagated as a lower bound for comparison (Section 2.6). The small sample size
([confirm 20] points) is a limitation of the input layer and is carried through as
uncertainty rather than hidden.

### 2.3 The regulatory nitrogen balance

The field nitrogen dose is computed by the DPI 2026 Allegato 2 balance, which
reconciles crop demand with soil supply and losses. The balance sums crop nitrogen
demand (term A) and subtracts the soil supply of readily available and mineralisable
nitrogen (term B), then adds leaching and immobilization terms (C and D) and
subtracts the credits from the previous crop, from organic and mineral inputs and
from atmospheric deposition (terms E, F and G), returning the mineral nitrogen to
apply. Soil texture, organic matter, total nitrogen (as a mass fraction, in g per
kg) and the carbon to nitrogen ratio enter the supply and loss terms, which is why
their uncertainty propagates to the dose. The dose is capped by the crop maximum
admissible dose (MAS) and, in nitrate-vulnerable zones, by the territorial ceiling,
so the output is compliant by construction [@dpi2026; @rr2_2024; @oenema2003]. The
balance reproduces the regional decision tool Fert_Office version 1.26
[@fertoffice2026].

### 2.4 In-season diagnosis of nitrogen status

In-season nitrogen status is diagnosed from Sentinel-2 imagery through the Nitrogen
Nutrition Index (NNI), the ratio of the actual to the critical nitrogen
concentration along the species-specific critical-nitrogen dilution curve
[@lemaire1997; @justes1994]. The canopy variables that the index requires, the green
biomass and the canopy nitrogen, are retrieved from Sentinel-2 Level-2A reflectance
by a hybrid Gaussian-process regression trained on radiative-transfer simulations
[@estevez2022; @verrelst2015]. A multi-index vegetation engine (including red-edge
chlorophyll indices, which remain sensitive once the canopy closes) provides the
empirical alternative where a full retrieval is not warranted [@gitelson2005;
@clevers2013].

### 2.5 The variable-rate step and the economic optimum

The spatial prescription follows the mass-balance constraint: the balance sets the
field mean dose, the nitrogen-status pattern (from the NNI or a vegetation index)
sets the relative distribution, and the two are reconciled by rescaling so that the
area-weighted mean equals the field target, keeping the prescription compliant while
redistributing nitrogen within the field [@holland2010; @raun2002]. An optional
economic-optimum module couples the balance to the QUEFTS crop model [CITATION
NEEDED: Janssen et al. 1990 QUEFTS] through the Rquefts package: QUEFTS returns a
per-cell economic optimum nitrogen rate from the soil supply implied by the balance
and a grain price, the economic optimum sets the applied field level, and the
regulatory budget acts as a ceiling rather than a target. The economic optimum is
reported across a range of grain to nitrogen price ratios rather than at a single
price, and its calibration against the balance soil-supply term is checked, because
the optimum is sensitive to both.

### 2.6 Propagation of the soil uncertainty

The balance is a deterministic function of the soil inputs, so their uncertainty
maps onto the dose. The soil uncertainty was propagated by Monte Carlo, with draws
correlated to respect the structure of the soil data rather than drawn independently:
the particle-size fractions were drawn under the closure constraint that clay, silt
and sand sum to 100 percent, and organic carbon and total nitrogen were drawn with
their empirical co-variation so that the carbon to nitrogen ratio stays physically
plausible. For each of [confirm N] draws the balance was evaluated per pixel and the
per-pixel mean and standard deviation of the resulting dose were accumulated. A
variance decomposition, drawing one property or one constrained group at a time,
attributed the dose uncertainty to each soil input. The primary propagation used the
hold-out RMSE of the soil maps as the input uncertainty; the bootstrap raster was
propagated as a lower bound.

The dependence of the aggregate uncertainty on the spatial structure of the soil
error was modelled, not assumed. The soil error was given a spatial correlation
length, and the standard deviation of the field, farm and territorial nitrogen
totals was computed as a function of that correlation length, spanning the
short-range regime in which per-parcel errors average out and the long-range regime
in which a systematic error persists on aggregation. The two limiting cases,
spatially independent and fully systematic error, bound this curve. Because it is
scriptable against an open function, this propagation is a few lines of code, which
is not possible with a closed spreadsheet.

### 2.7 Multi-scale aggregation

The same balance was evaluated at three nested scales. At the field scale the
per-pixel prescription and its uncertainty band were produced on the 10 m grid
within the area of applicability. At the farm scale the balance was run per field
with the field crop and yield, and the per-field dose, the field nitrogen total and
the farm nitrogen total were aggregated, each with the propagated uncertainty. At
the territory scale the same per-parcel balance was applied to the parcels of a
land-parcel identification system (LPIS) with the declared crops and a regional
soil-property map, giving a nitrogen recommendation, a surplus or compliance map and
a regional total, with the uncertainty of the regional map propagated as above. The
farm total is a strict sub-aggregation of the territorial set (the parcels of a
single holding), so the two scales share one computation and are not double-counted.
The dependence of the aggregate uncertainty on the soil-error correlation length is
the cross-scale result (Section 4).

### 2.8 Case study and data

The field and farm scales are demonstrated on the CERZOO experimental farm of the
Universita Cattolica del Sacro Cuore, in the Po Valley near Piacenza. The farm
comprises [confirm 8] fields with the crops declared for 2025 (silage maize, a grass
plus second-crop silage maize rotation and soft wheat), covering [confirm 32.1] ha
of mapped soil. Soil properties were taken from the input layer of Section 2.2;
in-season nitrogen status used a Sentinel-2 Level-2A time series for 2024 to 2025.
The territory scale uses [confirm: region] LPIS parcels and regional soil-property
maps [confirm: source and access].

All analyses were run in R version 4.5.1 [@rcore2025] with the terra package for
raster handling [@terra2024] and NFert for the balance, diagnosis and prescription.
The package, the case-study data and the analysis scripts are openly available
[confirm: GitHub repository and archived DOI]; the soil input maps of Section 2.2
are available from [CITATION NEEDED: companion work / data availability of the
soil-spatialization pipeline], and their access status is stated so that the
open-tool claim of this paper is not overstated.
