# Writing Quality Review: NFert_SAT.md (Smart Agricultural Technology)

Reviewed against general conventions plus Elsevier SAT norms (abstract ≤ 250 words, no
citations in the abstract, highlights ≤ 85 characters). Line numbers refer to
`paper/sat/NFert_SAT.md` as of 2026-11-06. Numbers were checked against `paper/sat/data/*.csv`
and against the regenerated figures.

## Summary

The manuscript is technically precise and its numbers mostly agree with the data, but the prose
is heavy: many 60–90-word sentences in Methods, frequent restatement ("one computation",
"open, auditable", "transparent") and drifting names for the same quantity (dose, rate,
recommendation, requirement, balance). Two statements contradict the data (Fig. 5 caption,
maize NNI in §3.1). At section level, Results carry Methods material (strip builder, canopy
mask), and the Discussion opens with a claim of contribution and compares with no prior work.

---

## Pass 1: Clutter (4 grouped findings)

**[MAJOR] Repeated slogans** (≥ 14 instances)
- "in one computation" / "one computation": lines 41, 112, 434, 488, 559, 336–337.
- "open, auditable" / "transparent" / "auditable": lines 41, 57, 73, 95, 96, 535, 540, 562, 566, 569.
- Line 488: "The method is applied to the whole farm in one computation (Figure 6)." → delete (Figure 6 and §2.7 already say it).
- Line 534–536 and 538–541 both say the contribution is to make the scaling "computable and auditable" → keep one (see Pass 3).
- Why: repetition reads as promotional and, to reviewers, as AI-flavoured filler; each claim once is stronger.

**[MAJOR] Self-justifying asides that add no information** (5 instances)
- Line 115–116: "A key methodological point, which the open implementation makes computable in a few lines, is that the confidence…" → "The confidence in an aggregate nitrogen total is not fixed: it depends on the spatial correlation length of the soil error."
- Line 327–329: "…because it is scriptable against an open balance function, the whole propagation is a few lines of code, which a closed spreadsheet cannot express." → delete from Methods (already in §5, lines 566–568).
- Also lines 143–145 (Fig. 1 caption, "a short script on the open balance function"), 291–292 ("which is the step an adviser needs to act on the recommendation"), 611 ("which the open, scriptable design of the tool is built to support").

**[MINOR] Empty openers / dead weight** – see Minor edits.

## Pass 2: Voice and verbs (2 grouped findings)

**[MAJOR] Passive hides who produced the soil maps** (line 198–201)
- Original: "clay, sand, organic carbon and total nitrogen and their per-pixel uncertainty were estimated from 20 georeferenced soil samples … by a multi-model machine-learning spatialization [CITATION NEEDED]"
- Revision: "[Provider/companion study] estimated clay, sand, organic carbon and total nitrogen, with their per-pixel uncertainty, from 20 georeferenced soil samples and a bare-soil Sentinel-2 Level-2A composite [citation]."
- Why: the maps are not the authors' work (proprietary pipeline, line 365); the passive blurs that, which matters for the competing-interest statement.

**[MINOR] Smothered verbs** (4 instances) – lines 313, 296, 510, 307; see Minor edits.

## Pass 3: Sentence and paragraph architecture (8 findings)

**[MAJOR] Overloaded Methods sentences** (5 instances)
- Line 206–211 (≈ 85 words, predicate "was used" buried ~25 words after "the hold-out RMSE"):
  → "A bootstrap standard deviation can understate the total prediction error: for clay the mean bootstrap deviation is 0.96 percent, against a leave-one-point-out RMSE of 2.90. We therefore used the hold-out RMSE of each property as the soil-input uncertainty (clay 2.90 and sand 3.47 percent, organic carbon 0.103 percent, total nitrogen 0.013 percent). This choice is conservative and carries the small sample (20 points) through as uncertainty."
- Line 299–306 (≈ 95 words, one sentence):
  → "In each draw we added to each property a normal deviate with standard deviation equal to its hold-out RMSE (Section 2.2). Clay and sand were drawn jointly with their empirical correlation (−0.644) and constrained to sum with silt to 100 percent (silt as the residual, sand capped at 98 minus clay). Organic carbon and total nitrogen were drawn jointly with their correlation (0.904), so that the carbon-to-nitrogen ratio stays plausible, and floored at small positive values."
  (Note: the header comment forbids dashes; write the minus as "minus 0.644" or keep the hyphen-minus.)
- Line 265–270: "The prescription follows the mass-balance constraint: the balance sets … which keeps the prescription compliant while redistributing nitrogen within the field (…)" → split after "the dose bounds."; start new sentence "This rescaling keeps the prescription compliant while redistributing nitrogen within the field."
- Also lines 307–311 (variance decomposition) and 239–244 (calculate_N_fertilization + dose definition).

**[MAJOR] Methods material inside Results** (2 instances)
- Line 442–451: the A-B line logic, minimum-area rectangle and manual track options are a description of `build_strip_prescription()` → move to §2.5; leave in §3.2 only the outcome (58 passes, 359–2547 cells, export formats).
- Line 385–388: canopy-mask threshold and choice of acquisition dates → move to §2.4 or §2.8.

**[MAJOR] Methods do not define the five strategies used in Results** (line 271–274 vs 411–413, Fig. 5)
- §2.5 describes "a calibration ramp" and "the Holland and Schepers sufficiency-index curve"; Results and Fig. 5 use "Uniform, Calibration (inverse), Calibration (direct), Quantile classes, NNI zones". Inverse vs direct, the quantile classes and the NNI zones are never explained, and Holland–Schepers does not appear in the results.
- Revision: add to §2.5 one sentence per strategy, with the same five names as Fig. 5, e.g. "We compared five within-field strategies: uniform (the field target everywhere); inverse and direct calibration (dose decreasing or increasing linearly with NDVI); NDVI quantile classes; and NNI zones (…)." [author to confirm definitions]

**[MAJOR] Discussion opens with a claim, repeats itself, and cites no prior work** (lines 534–555)
- Line 534–536 states that making the behaviour "computable and auditable … is a central contribution"; line 538–541 says the same. Merge into one opening that states the finding:
  → "The confidence in a farm nitrogen total is not fixed: at CERZOO it ranges from about 0.1 to 2.5 percent depending on the correlation length of the soil error, whereas the per-pixel uncertainty is 3.3 percent. That correlated error does not cancel on aggregation is a textbook property of error propagation [citation]; what the tool adds is to compute it for a regulatory total, against an open balance, as a sensitivity envelope rather than a single assumed length."
- No paragraph compares with previous work (Section 4 has no citations). Add comparison with studies on soil-map uncertainty propagation / aggregation of spatially correlated error (e.g., Heuvelink-type work) and with Basso et al. 2016 [authors to choose sources].

**[MINOR] Results paragraphs that lead with the figure** – lines 510, 376; see Minor edits.

**[MINOR] Intro paragraph 1 opening is long and generic** (line 66–69) – see Minor edits.

## Pass 4: Terminology (4 findings)

**[CRITICAL] One quantity, five names: dose / rate / recommendation / requirement / balance**
- Line 241–243 defines "the dose of the case study" as the requirement before the organic credit. Results then use "recommendation" (lines 415–421, 466, 489), "rate" (Table 2 "Mean rate"), "requirement" (line 552) and "the balance" as a quantity (abstract line 56 "the balance rises by 26 percent", line 502 "the balance requires 8.71 t N").
- Revision: use "dose" (kg N ha⁻¹) for the per-pixel/per-field output, "farm total" (t N) for the aggregate, "balance" only for the method. E.g. line 56: "the dose rises by 26 percent and exceeds the MAS on four of the eight fields"; Table 2 header "Mean dose".
- Why: "requirement", "recommendation" and "dose" are distinct concepts in the DPI (requirement before credits vs. applied dose); switching names suggests different variables.

**[MAJOR] Crop-group names drift**
- "silage maize", "main-crop silage maize", "high-yield silage-maize fields" (416), "main-crop maize" (Fig. 3, 504), "second-crop maize", "Grass + second-crop silage maize", "soft wheat", "winter wheat" (378, 395), "wheat".
- Revision: define three labels once in §2.8 — "main-crop maize", "second-crop maize", "wheat" — and use them in text, tables and figure legends (Fig. 3 already uses them).

**[MAJOR] NNI never defined as an acronym; full name repeated ~20 times**
- Main text spells out "Nitrogen Nutrition Index" everywhere, producing forms such as "Nitrogen-Nutrition-Index-driven maps" (413) and "Nitrogen-Nutrition-Index zones" (427, 460, 651), while captions and Fig. 5 use "NNI" (158, 402, 429).
- Revision: line 77 "the Nitrogen Nutrition Index (NNI)", then "NNI" throughout; likewise "NNI zones".

**[MINOR] Undefined or Italian acronyms/terms**
- "DPI" never expanded in the main text (line 227; defined only in abstract). → "the Emilia-Romagna Integrated Production Guidelines (Disciplinari di Produzione Integrata, DPI 2026)".
- "Allegato 2" (227) → "Annex 2".
- "VRT" (Table 1) undefined → "variable-rate technology (VRT)" in the table note.
- "RMSE" (208) undefined → "root-mean-square error (RMSE)".
- "CERZOO" (52, 343) not glossed; fine as a name, but say "the CERZOO experimental farm" consistently (already done).
- Figure 1 shows "ZVN" (Italian) → "NVZ" to match "nitrate-vulnerable zones".

**[MINOR] Mixed spelling (-ise/-ize)**
- -ise: mineralisable (233), fertilisers (241, 288), realisation (319), minimises (446), summarised (510), modelled/behaviour/colour/licence are fine in Oxford spelling.
- -ize: fertilization, optimization, immobilization, spatialization, re-parameterized.
- Pick one (Elsevier accepts either; Oxford -ize with British -our is the simplest) and apply throughout.

## Pass 5: Numbers and citations (4 findings)

**[CRITICAL] Fig. 5 caption contradicts the data** (line 428–430)
- Original: "the direct calibration, the quantile classes and the NNI zones differentiate most (about 60 to 135 percent)."
- Data (`strategy_summary.csv`): direct calibration spans 60 to 109 percent, with SD 28.6 kg N ha⁻¹, lower than the inverse calibration (33.2). Quantile classes 64–135 (SD 61.3), NNI zones 62–135 (SD 50.4).
- Revision: "uniform sits at the target; the two calibrations spread it moderately (inverse 86 to 135 percent, direct 60 to 109 percent, mostly downward); the quantile classes and the NNI zones differentiate most (about 62 to 135 percent)."

**[MAJOR] "maize fields are mostly optimal" is false for two fields** (line 382–383)
- Data (`peak_scenes.csv`): optimal share F1 81, F9 78, F10 72, F2 68, F3 58, F4 39, F6 35 percent; F4 and F6 have more excess (49, 62) than optimal.
- Revision: "whereas the optimal class dominates in five of the seven maize fields (58 to 81 percent of the pixels); in the second-crop fields F4 and F6 the excess class dominates (49 and 62 percent)."

**[MINOR] Rounding** – line 502: farm mean under measured rainfall is 271.6 kg N ha⁻¹ → "272". Line 521: "0.44 and 1.50 … (0.42 and 1.44)" rounds to a 5 percent gap at two decimals; the CSV ratios are 3.0 and 3.7 percent, so write "within 4 percent" with three decimals (0.437 vs 0.424; 1.495 vs 1.442) or say "within 5 percent".

**[MINOR] Citation integrity**
- Line 78–80: the dominance of index-based methods is cited to one scoping review [@corti2022]; fine as a review claim, keep the wording "found".
- Line 258: [@estevez2022] concerns TOA retrieval, while the text says Level-2A; cite the L2A model source [CITATION NEEDED].

## Pass 6: Summary paragraph structure

Parameters: Elsevier SAT; target ≤ 250 words; citations not allowed (none present ✓).
Word count ≈ 232 ✓.

```
[1 Field intro]      Precision nitrogen management must match supply to crop demand in space and time within regulatory limits,
[3 Problem]          yet the operational tools that set the rate are closed spreadsheets that give one deterministic number at one scale and ignore the uncertainty of their soil inputs.
[— tool statement]   We present NFert, an open-source R package (version 1.0.0, MIT license) that implements the Emilia-Romagna Integrated Production nitrogen balance (DPI 2026).
[— tool statement]   NFert couples the balance … and propagates the uncertainty of the soil inputs by correlated Monte Carlo.
[5 results]          On the CERZOO experimental farm … the farm requires 6.9 t of nitrogen.
[5 results]          The per-pixel uncertainty of the dose is 3.3 percent and is driven almost entirely by soil texture (95 to 96 percent of the variance).
[4 Main result ✗]    The confidence in the farm total depends on the spatial correlation length of the soil error, from about 0.1 percent … to 2.5 percent …
[5 results]          Under the rainfall measured in 2024 to 2025 the balance rises by 26 percent and exceeds the maximum allowed dose on four of the eight fields.
[6 General context]  NFert offers a transparent, uncertainty-aware, multi-scale alternative to closed tools.
```
Moves present: 1, 3, (tool), 5, 4, 5, 6 — main result present but unmarked and placed after secondary results.

**[MAJOR] Main result not marked and out of order.** Move the correlation-length sentence up and mark it:
"We show that the confidence in the farm nitrogen total is not fixed but depends on the spatial correlation length of the soil error: on the CERZOO experimental farm (Po Valley, Italy; eight maize and wheat fields, 32 ha; 6.9 t N), its standard deviation ranges from about 0.1 percent for short-range error to 2.5 percent for systematic error, against a per-pixel uncertainty of 3.3 percent, 95 to 96 percent of which comes from soil texture."

**[MAJOR] Background move (2) missing.** One sentence linking soil maps to the balance would make the problem legible: "Regulatory nitrogen balances depend on soil texture and organic matter, which are increasingly supplied by digital soil maps with known, spatially structured errors."

**[MINOR] Non-essential numbers.** "version 1.0.0, MIT license" → cut from the abstract (it is in §2.1 and the code metadata).

Accessibility notes (advisory): "correlated Monte Carlo", "DPI 2026", "maximum allowed dose" and "soil-error correlation length" are unglossed for a non-specialist; "correlation length" is the key term and deserves a four-word gloss ("the distance over which soil-map errors stay similar").

Highlights: all ≤ 85 characters ✓; highlights 1 and 5 overlap ("pixel to farm" / "field and farm accounting… one computation") — merge and free a slot for the weather result (+26 percent, MAS exceeded).

---

## Minor edits

- 66–69: "Fertilization is among the most consequential decisions in arable cropping, and the rate of nitrogen applied is the decision that most directly determines its outcome:" → "The nitrogen rate is the fertilization decision that most directly determines"
- 86: "The second gap is openness and reproducibility. The regulatory methods are typically locked in" → "The second gap is openness: regulatory methods are typically locked in"
- 117–119: "The remainder of the paper describes…" → delete (SAT does not require a roadmap; saves 35 words)
- 147–150: "The nitrogen rate rests on a small number of functional forms that recur across recommendation methods and that NFert draws on (Figure 2):" → "NFert draws on three functional forms common to nitrogen-rate methods (Figure 2):"
- 296: "This uncertainty was propagated by Monte Carlo" → "We propagated this uncertainty by Monte Carlo"
- 307: "A separate variance decomposition perturbed" → "We decomposed the dose variance by perturbing"
- 313–314: "The dependence of the aggregate uncertainty on the spatial structure of the soil error was modelled, not assumed." → "We modelled, rather than assumed, how the aggregate uncertainty depends on the spatial structure of the soil error."
- 376: "The Sentinel-2 time series resolves the cropping calendar…" → OK, but "the two silage-maize cycles as summer canopy peaks, the second crops as a distinct later flush" is unclear (Fig. 3 shows the second-crop group peaking in April–May from the preceding winter crop) → "main-crop maize as a summer peak, second-crop fields as a spring peak (the preceding winter crop) followed by a late-summer peak, and wheat as a spring peak"
- 393–395 (Fig. 3 caption): add "the spring peak of the second-crop fields is the preceding winter crop"
- 399–401 (Fig. 4 caption): add "F5 (wheat) is mapped on 25 April; the maize fields on 29 July or 22 August"
- 510: "The soil-driven dose uncertainty and its behaviour on aggregation are summarised in Figure 7. A per-crop variance decomposition (Figure 7a) shows that soil texture dominates" → "Soil texture dominates the dose uncertainty for both crops (Figure 7a):"
- 534: Discussion opener → see Pass 3
- 553: "a change several times larger than the 3.3 percent soil uncertainty" → "about eight times the 3.3 percent soil uncertainty"
- 569–570: "not a validated better way to fertilize" → "not a validated improvement in fertilization"
- 604–607: "so the extension to phosphorus and potassium is not the balance itself but coupling those nutrients to the sensor" → "so extending the method to phosphorus and potassium means coupling those balances to the sensor"

## Content notes

1. Line 128 still says the tests "check the balance against the regional Fert_Office tool", and line 247–249 keeps a Fert_Office sentence. You said the agreement with Fert_Office has no place in this paper: replace with "a unit-test suite (168 tests, about 87 percent line coverage), run under continuous integration…" and decide whether line 247–249 stays (it explains the numerical reference, not an agreement).
2. Season scenario: F6 drops from 204 to 150 kg N ha⁻¹ under the measured rainfall (recorded previous crop), while the text implies every field rises. One clause in §3.3 would pre-empt a reviewer.
3. Limitations sit in §5, not §4. SAT accepts this, but a reviewer looking for limitations in the Discussion may miss them; a one-line pointer at the end of §4 helps.

## Top 5 Priority Revisions

1. Fix the Fig. 5 caption (direct calibration 60–109 percent, not among the most differentiated) — line 428–430.
2. Fix "maize fields are mostly optimal" (F4, F6 dominated by excess) — line 382–383.
3. One name per quantity: "dose" / "farm total" / "balance" (method only); define NNI and use it.
4. Define the five Fig. 5 strategies in §2.5 and move the strip-builder and canopy-mask descriptions from Results to Methods.
5. Rewrite the Discussion opening (one statement of the finding, no duplicate contribution claim) and add comparison with prior work; mark and move the main result in the abstract.
