# Annotated outline (v3): NFert, an open, uncertainty-aware, multi-scale nitrogen tool, for Smart Agricultural Technology

Status: v3, revised after the multi-lens review. Supersedes v2. Target: Smart
Agricultural Technology (Elsevier, ISSN 2772-3755, Gold Open Access, APC to confirm,
roughly 2050 USD). Article type: full-length research article, tool-first (model:
Hamie et al. 2026, "AgroSat", same journal), nitrogen only.

Decisions locked (author):
- Tool-first (NFert is the protagonist); stay with SAT.
- The soil machine-learning spatialization is a CITED INPUT LAYER, not an in-paper
  method (descoped, per the review). It may become its own paper.
- Uncertainty propagation uses CORRELATED soil draws and leads with the hold-out
  (LOPO) RMSE, not the bootstrap.
- The cross-scale result is a soil-error CORRELATION-LENGTH model, not an assumed
  independent-vs-systematic contrast.
- Claims carry no yield or profit gain over uniform management.

Conventions: no em or en dashes (ranges as "X to Y"); colon separators; literal
accents; SI units. Integrity: numbers are `[confirm]` (from code/data) or `[to
produce]`; sources are verified bib keys or `[CITATION NEEDED: ...]` (no invented
DOI). The prose is in the methods draft (paper/NFert_SAT_methods_draft.md v2); this
file is the plan.

---

## The contribution (the spine)

The regulatory nitrogen mass balance is scale invariant: the same open, auditable
computation runs from the pixel to the territory. Because the implementation is open
and scriptable, the uncertainty of its soil inputs is propagated through it
explicitly, and the confidence in an aggregate nitrogen total is shown to depend on
the SPATIAL CORRELATION LENGTH of the soil error, averaging out across parcels under
short-range error and persisting under long-range error. This is the unifying,
policy-relevant result and makes the uncertainty and multi-scale angles one
contribution.

One-liner: NFert, an open, uncertainty-aware implementation of the regulatory
nitrogen balance that runs the same auditable computation from field variable-rate
prescription to territorial accounting, with the confidence in the nitrogen total a
function of the soil-error correlation length.

## Title (recommendation first)

1. NFert: an open, uncertainty-aware nitrogen-balance tool from field variable-rate
   prescription to territorial accounting.
2. From the field prescription to the territory: propagating soil uncertainty
   through the regulatory nitrogen balance with an open tool (NFert).

## Highlights (3 to 5, each <= 85 characters; drafts)

- Open R tool runs the regulatory N balance from pixel to territory
- Validated soil maps and their uncertainty give the prescription a credible band
- The confidence in the N total depends on the soil-error correlation length
- Field, farm and territory N accounting from one auditable computation
- Which soil property to sample better follows from a variance decomposition

## Abstract (<= 250 words; skeleton)

Context: matching nitrogen supply to demand under agronomic, economic and regulatory
constraints; operational tools give a deterministic rate, at one scale, in closed
spreadsheets, ignoring soil-input uncertainty. NFert: an open R package (v0.14.0,
MIT, GitHub with CI and a DOI) implementing the DPI 2026 balance, an in-season
Sentinel-2 NNI diagnosis, a mass-balance-constrained variable-rate module and an
optional economic optimum, run from pixel to territory. New: it propagates
soil-property uncertainty (texture, organic carbon, total nitrogen) through the
balance by Monte Carlo, and reports the rate and its confidence at field, farm and
territory scale. Application: on the CERZOO farm (silage maize and wheat, Po Valley,
[confirm 8] fields, [confirm 32] ha) the soil maps and their validated estimation
uncertainty, from an external spatialization, give a variable-rate prescription with
a credible band and a per-crop variance decomposition of the soil sources of
uncertainty; the same computation gives farm and (from LPIS parcels and regional
maps) territorial accounting. Key result: the confidence in the nitrogen total
depends on the spatial correlation length of the soil error, from negligible under
short-range error to [confirm]% under long-range error. Impact: a transparent,
uncertainty-aware, multi-scale alternative to closed tools, for agronomists,
advisers and regulators, claiming a compliant and auditable accounting rather than a
yield or profit gain. Code and data are openly available.

Keywords: precision agriculture; variable-rate nitrogen; nutrient balance;
uncertainty propagation; multi-scale nutrient accounting; Sentinel-2; reproducible
research.

---

## Section plan (prose in the methods draft; results and framing here)

### 1. Introduction (1200 to 1600 words)
Stakes of the N rate; the method families condensed (anchor on Corti et al. 2022,
defer the full survey to the companion review); three gaps NFert closes:
(i) integration (balance and sensor rarely coupled), (ii) openness and
reproducibility (closed regional spreadsheets), (iii) deterministic and single scale
(a point rate at one scale, ignoring soil uncertainty). Aim and contribution.

### 2. NFert: methods and architecture (2000 to 2600 words)
Follows the methods draft v2: 2.1 design and openness; 2.2 soil properties and their
uncertainty AS A CITED INPUT LAYER (one to two paragraphs, cite the spatialization,
report AoA and hold-out RMSE, lead with LOPO uncertainty, state the ~20-point
limitation, gate the prescription by the AoA); 2.3 the DPI balance; 2.4 in-season
NNI diagnosis; 2.5 variable-rate step and the economic optimum (EONR reported over a
price range, calibration checked); 2.6 uncertainty propagation with CORRELATED draws
(texture closure, organic-C to total-N co-variation) leading with LOPO RMSE; 2.7
multi-scale aggregation and the correlation-length model; 2.8 CERZOO data.
Figures: architecture, N-balance scheme, critical-N curves, VRT response.

### 3. Application: field and farm (1600 to 2000 words)
Real results (see "Analyses" below): the per-pixel prescription and its credible
band within the AoA; the per-crop variance decomposition (texture vs carbon-nitrogen)
identifying which soil property to sample better; the per-field and farm nitrogen
accounting with uncertainty. Territory scale (3.x): LPIS parcels plus regional soil
maps, a surplus or MAS-ZVN compliance map and a regional total, with the regional-map
uncertainty. Figures: CERZOO biophysical time series, NNI vs LAI, prescription
strategies, prescription-with-uncertainty band, variance decomposition, territorial
map.

### 4. Cross-scale synthesis (900 to 1200 words)
The core result: farm and territorial nitrogen-total uncertainty as a function of the
soil-error correlation length (the modelled curve). Provisional numbers from the
corrected run: farm total [confirm 6.6] t N; SD from [confirm ~0]% (short-range) to
[confirm ~3.5]% (long-range). No variable-rate-vs-uniform yield claim.

### 5. Impact and perspectives (900 to 1200 words)
One computation for agronomist (field VRT), adviser (farm accounting), regulator
(territorial compliance and surplus); openness as the enabler of the uncertainty
propagation; policy relevance (Nitrates Directive, nutrient surplus); limitations
(no independent agronomic validation, single site and season, ~20-point soil maps,
assumed error-correlation structure, coarse territory); outlook (P and K, seasons,
full-chain uncertainty). Cite the companion cross-nutrient review.

Back matter: CRediT; competing interest; funding (EOAGRITWIN); data and code
availability (GitHub + DOI; the soil input maps' access and credit stated honestly);
references (numbered).

---

## Analyses (the computational engine; state provisional vs final)

1. Corrected propagation (script mc_farm_v2.R): CORRELATED per-pixel draws (empirical
   rho clay-sand [confirm -0.64], TOC-TN [confirm 0.90]) with LOPO-RMSE magnitudes,
   per crop, giving N mean and SD rasters (the credible band) and per-crop variance
   decomposition (texture vs carbon-nitrogen). Provisional (independent-draw) numbers
   to be replaced by this run.
2. Correlation-length model: farm-total N SD as a function of the soil-error
   correlation length (the cross-scale curve). [running]
3. AoA gating: mask out-of-AoA pixels; report the fraction of each field and of the
   territory outside the AoA. [to produce]
4. Territory: per-parcel balance over LPIS with regional soil maps; farm and regional
   totals with uncertainty. [to produce, needs the regional data]
5. Figures via the scientific-figures pipeline (not improvised).

## Figure and table plan

Existing and reusable (paper/figures): architecture, nbalance_scheme,
critical_n_curves, cerzoo_vrt_response, cerzoo_biophysical_ts, cerzoo_nni_ts,
cerzoo_prescription_strategies. To produce: prescription-with-uncertainty band;
variance decomposition (texture vs C-N, per crop); correlation-length curve
(farm-total SD vs L); territorial compliance/surplus map; AoA coverage. Tables:
NFert modules; per-field/farm accounting; validation summary of the input maps
(cited). Keep the main text to a manageable figure count; move detail to
supplementary material.

## References plan

Reuse the verified keys in paper/references.bib and paper/references_review.bib
(nitrogen subset, ~45 to 60). Add after DOI confirmation: Hamie et al. 2026
(AgroSat). New sources to verify (do not invent): the soil-spatialization method
(companion/external); QUEFTS (Janssen et al. 1990); a geostatistics/spatial-
correlation reference for the correlation-length model; Area of Applicability
(Meyer and Pebesma 2021); a Monte Carlo uncertainty-propagation reference.

## Risks and honesty (guardrails from the review)

- Do NOT claim a yield or profit gain; the claim is a compliant, transparent,
  uncertainty-aware accounting and prescription.
- The soil maps rest on ~20 points and optimistic leave-one-point-out CV: report the
  RMSE with its uncertainty, gate by the AoA, and state the limitation wherever the
  maps are used.
- The uncertainty draws must be correlated (texture closure, organic-C to total-N);
  independent draws corrupt the variance decomposition.
- The cross-scale result must be the correlation-length model, not the tautological
  independent-vs-systematic contrast.
- The EONR is below the regulatory dose and price-sensitive: report over a price
  range, check the QUEFTS soil-supply calibration, and do not imply the regulation
  over-fertilises without support.
- Reconcile the TN unit (g per kg) and remove every stale "kriging" reference.

## Pre-submission checklist

- [ ] Merge the CI fix (branch fix/optimize-vr-dpi-ci); the repo must be green.
- [ ] Tagged release plus Zenodo DOI for the code and case-study data.
- [ ] Soil input maps: state access and credit; resolve the BioDroneConsulting/client
      IP and authorship before submission (the "open" claim must be honest).
- [ ] Package counts current (v0.14.0, 75 functions).
- [ ] Highlights (3 to 5, <= 85 char); abstract <= 250 words; keywords 1 to 7.
- [ ] CRediT; competing-interest, funding and data-availability statements.
- [ ] Confirm every bracketed number against the final corrected run.
- [ ] Confirm the AgroSat, QUEFTS, AoA and geostatistics citations.
- [ ] Confirm the live SAT Guide for Authors (reference style, limits, APC).
- [ ] AI-use disclosure per Elsevier policy if required.
- [ ] Overlap control: cite the companion cross-nutrient review and the N-focused
      NFert review rather than repeating their text.

## Overlap and salami control

This SAT paper absorbs the N-focused NFert_review.Rmd and the SoftwareX draft (not
submitted separately). The cross-nutrient review stays standalone and cites this
paper. The soil-spatialization method is a cited input layer here and may become its
own paper; keep the boundary clean.
