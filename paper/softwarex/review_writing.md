# Writing Quality Review: NFert_SoftwareX.md (SoftwareX, OSP template v4)

Reviewed against the SoftwareX template (abstract about 100 words, body up to 3000 words,
Impact as the main section) and general conventions. Line numbers refer to
`paper/softwarex/NFert_SoftwareX.md` as of 2026-11-13. Numbers checked against the code
(76 exports, 38 datasets, 235 `uptake_table` entries, six indices in `compute_vi()`, 169 tests,
773 expectations) and against the outputs of `fig2_data.R`, `fig3_data.R` and `paper/sat/data/`.

## Summary

The manuscript is clear, concrete and within the limits (abstract 89 words, body 2264). Its
numbers agree with the code. The main problems are: one claim left without evidence after the
verification section was removed ("exact enough to be used in place of the official tool");
five names for the regional tool; an Italian false friend ("precession") and two undefined
abbreviations (MAS, N*); two overloaded sentences in Sections 1 and 4; and an abstract that
describes the package but states no result.

---

## Pass 1: Clutter (2 findings)

**[MINOR] Promotional tail** (line 41)
- "which needs exactly such an engine" → "which such an engine could serve".

**[MINOR] Unlabelled limitations paragraph** (line 146)
- Start with "**Limitations.**" so it reads as part of the Impact structure.

## Pass 2: Voice and verbs

No problems worth reporting; passives are confined to settled background (line 37).

## Pass 3: Sentence and paragraph architecture (3 findings)

**[MAJOR] Overloaded sentence** (line 41)
- Original: "Sentinel-2 tools for variable-rate nitrogen, such as AgroSat and the simplified prescriptions tested on Italian wheat, set rates from canopy reflectance [...], but they do not compute the regulatory balance, and the evidence that sensor-based rates improve management varies with context [...]."
- Revision: "Sentinel-2 tools for variable-rate nitrogen, such as AgroSat and the simplified prescriptions tested on Italian wheat, set rates from canopy reflectance but do not compute the regulatory balance [@hamie2026; @vizzari2019; @santaga2021]. The evidence that sensor-based rates improve management also varies with context [@holland2010; @diacono2013; @colaco2018; @basso2016]."
- Why: three ideas in one sentence; the second citation group belongs to a different claim.

**[MAJOR] Overloaded sentence with buried result** (line 136, about 75 words)
- Original: "On the CERZOO farm (...), a correlated Monte Carlo of the clay, sand, organic carbon and total nitrogen map errors (...) through `N_balance()` gave a per-pixel dose uncertainty of 3.3 percent, 95 percent (maize) and 96 percent (wheat) of it from soil texture, and, because the map residuals showed no detectable spatial structure, a standard deviation of the farm nitrogen total of at most about 0.6 percent."
- Revision: "On the CERZOO farm (eight maize and wheat fields, 32 ha), we propagated the errors of the clay, sand, organic carbon and total nitrogen maps through `N_balance()` by correlated Monte Carlo (100 draws on 866 pixels of 20 m). The per-pixel dose uncertainty was 3.3 percent, 95 percent (maize) and 96 percent (wheat) of it from soil texture. Because the map residuals showed no detectable spatial structure, the standard deviation of the farm nitrogen total was at most about 0.6 percent."
- Why: the subject ("a correlated Monte Carlo") is separated from its verb by 30 words and three results share one sentence.

**[MINOR] Vague opener** (line 73)
- "Phosphorus and potassium follow the same source." → "The P~2~O~5~ and K~2~O balances follow the same guidelines."

## Pass 4: Terminology (4 findings)

**[MAJOR] Italian false friend: "precession"** (line 53)
- "`e.table` (precession effects)" → "`e.table` (previous-crop effects)". In English "precession" is an astronomical term; the Italian *precessione* means the preceding crop.

**[MAJOR] One tool, five names** (lines 37 to 142)
- "Fert_Office", "the official tool", "the regional tool", "the workbook", "the spreadsheet", "the official workbook", "the closed workbook".
- Revision: define once at line 37 ("Fert_Office, an Excel workbook distributed by the Region") and then use "Fert_Office" for the tool and "spreadsheet" only for the generic class (line 39). E.g. line 81 "the regional tool" → "Fert_Office"; line 102 "as in the workbook" → "as in Fert_Office"; line 136 "the official workbook" → "Fert_Office"; line 140 "the closed workbook" → "Fert_Office".

**[MINOR] Undefined abbreviations**
- MAS: first used in Table 1 (line 66), never expanded → line 37 "set crop-specific maximum allowed doses (MAS)".
- N*: appears only in the Fig. 1 caption → line 77 "equals the balance dose N\* within user bounds".
- DPI: expanded in the abstract only → line 37 "the Integrated Production Guidelines of Emilia-Romagna (DPI 2026)".
- "ready N" (line 53, from *azoto pronto*) → "readily available N".

**[MINOR] Mixed spelling (-ise/-ize)**
- -ise: mineralisation, fertilisation, fertilisers, immobilisation, parameterised (lines 53, 66, 73, 81, 138).
- -ize: fertilization (title, abstract), re-parameterizes (53), parameterizations (150).
- Pick one (Elsevier accepts either) and apply throughout; function names stay as they are.

## Pass 5: Numbers and citations (2 findings)

**[MAJOR] Claim left without evidence** (line 41)
- Original: "What is missing is an open implementation of the regulatory balance itself, exact enough to be used in place of the official tool, that remote-sensing and variable-rate methods can build on."
- Revision: "What is missing is an open implementation of the regulatory balance itself that remote-sensing and variable-rate methods can build on."
- Why: the verification against Fert_Office is no longer reported, so "exact enough to be used in place of the official tool" is now an unsupported claim.

**[MINOR] Precision** (line 106): "190.15 kg N ha^−1^" is the only value with two decimals; "190.2" still shows the plot is above 190.

## Pass 6: Summary paragraph (abstract)

Parameters: SoftwareX, about 100 words, no citations. Word count 89.

```
[1 Field / tool]   NFert is an open-source R package for N, P and K fertilization planning.
[2 Background]     It implements the crop nutrient balance and the standard-dose method of the DPI 2026 ...
[2 Background]     The same balance runs per plot ... and a Sentinel-2 module turns ... into prescriptions ...
[3 Problem ✗]      missing: why an open implementation is needed (closed regional spreadsheet)
[4 Result ✗]       missing: what the package enables or showed
```

**[CRITICAL] No problem statement and no result.** The abstract lists features but never says
why they are needed or what the package made possible. Suggested abstract (about 110 words):

"Regional nitrogen balances set the legal fertilizer dose in many European regions, but they are
distributed as closed spreadsheets that compute one field at a time. NFert is an open-source R
package that implements the nitrogen, phosphorus and potassium balance of the Emilia-Romagna
Integrated Production Guidelines (DPI 2026), returns every balance term so that a dose can be
audited, and keeps all coefficients as editable data. The same balance runs per plot of a farm
or per pixel of soil maps, and a Sentinel-2 module turns canopy traits and the Nitrogen Nutrition
Index into variable-rate prescriptions whose field mean equals the balance dose. Run per pixel
inside a Monte Carlo, it showed that soil-map error changes a farm nitrogen total by less than 1
percent."

---

## Minor edits

- 41: "which needs exactly such an engine" → "which such an engine could serve"
- 49: "the Gaussian-process models (jsonlite)" → "the Gaussian-process models (which need jsonlite)"
- 73: "Phosphorus and potassium follow the same source." → "The P~2~O~5~ and K~2~O balances follow the same guidelines."
- 106: "190.15" → "190.2"
- 146: add "**Limitations.**" at the start
- 150: "Planned work covers other regional parameterizations, a CRAN release and ..." → "Planned work covers a CRAN release, other regional parameterisations and ..."

## Content notes

1. Lines 106 and 136 both describe an eight-unit farm (the bundled demonstration farm, 35.5 ha, and CERZOO, 32 ha). A reader may take them for the same farm; one clause ("a different, real farm") avoids it.
2. The Impact section rests mostly on what the package *can* do; SoftwareX reviewers weigh evidence of use. The course details and any external users or downloads are the most valuable missing items.
3. The CERZOO uncertainty paragraph reports a research result in a software paper; keep it short, as now, and keep the scripts referenced so it is reproducible.

## Top 5 Priority Revisions

1. Rewrite the abstract with a problem statement and one result (Pass 6).
2. Remove "exact enough to be used in place of the official tool" (line 41).
3. Replace "precession" with "previous crop" (line 53).
4. One name for Fert_Office; define MAS, N\* and DPI in the body.
5. Split the two overloaded sentences (lines 41 and 136).
