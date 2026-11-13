# Propagating digital-soil-map uncertainty into N recommendations, nutrient budgets and aggregated totals

Verification note: each reference marked **[verified]** was checked this session against Crossref metadata or a publisher/repository record for authors, year, journal and DOI. **[partially verified]** means title and authors were seen but the DOI or venue was not confirmed. **[UNVERIFIED]** means recalled or only seen indirectly. Do not cite those without checking them first. Abstracts were read, but most full texts were not, so method details beyond the abstracts are marked as gaps.

## 1. Error propagation in spatial modelling and change of support (classic and recent)

### Takeaway
Error propagation through GIS models (Heuvelink et al. 1989; Heuvelink 1998) and the rule that aggregated uncertainty depends on the spatial autocorrelation of map errors (Heuvelink & Pebesma 1999; Wadoux & Heuvelink 2023) are established methodology. The NFert finding that the farm-total SD depends on the error correlation length is a textbook result. It should be cited as such, not presented as a discovery.

### Cited findings
- **[verified]** Heuvelink, G.B.M., Burrough, P.A., Stein, A. (1989). Propagation of errors in spatial modelling with GIS. *International Journal of Geographical Information Systems* 3(4): 303–322. https://doi.org/10.1080/02693798908941518. Uses first-order Taylor propagation of map prediction errors and model-coefficient errors through raster models. — [U. Twente record](https://research.utwente.nl/en/publications/propagation-of-errors-in-spatial-modelling-with-gis-2/); [Scilit](https://scilit.com/publications/0c93db319544759aed7190c5305a2713)
- **[partially verified]** Heuvelink, G.B.M. (1998). *Error Propagation in Environmental Modelling with GIS*. Taylor & Francis, London. ISBN 9780748407439 (from the CRC Press listing). No DOI was checked. — [CRC Press](https://www.crcpress.com/recommend/librarian/9780748407439)
- **[verified]** Heuvelink, G.B.M., Pebesma, E.J. (1999). Spatial aggregation and soil process modelling. *Geoderma* 89(1–2): 47–65. https://doi.org/10.1016/S0016-7061(98)00077-9. Main points: aggregate after running the model, interpolate before it, and do not ignore interpolation error when inputs are interpolated. Model error depends on support and can only be assessed by validation. — [Crossref](https://api.crossref.org/works/10.1016/S0016-7061(98)00077-9); [Bohrium abstract](https://www.bohrium.com/paper-details/spatial-aggregation-and-soil-process-modelling/813062815723028480-1342)
- **[verified]** Wadoux, A.M.J.-C., Heuvelink, G.B.M. (2023). Uncertainty of spatial averages and totals of natural resource maps. *Methods in Ecology and Evolution* 14(5): 1320–1332. https://doi.org/10.1111/2041-210X.14106. Uncertainty of an aggregate "must account for spatial autocorrelation of the map errors", and several high-profile studies fail to do so. The paper proposes Monte Carlo integration with geostatistical modelling of the **standardized map error**, designed for machine-learning maps. For above-ground biomass, aggregate uncertainty was small because the standardized errors were only weakly autocorrelated. — [ISRIC news](https://www.isric.org/news/new-paper-efficient-new-method-calculate-uncertainty-spatial-averages); [DOAJ](https://doaj.org/article/3e1a5a25b1f24c1382f1d07a4031d21d)
  - This is the most direct methodological precedent for the NFert block/n_eff analysis. Their method estimates the error correlation from the data (a variogram of standardized residuals) instead of scanning scenario values of L.
- **[partially verified]** Wadoux & Heuvelink (2025). "Scientists yet to consider spatial correlation in assessing uncertainty of spatial averages and totals". Venue and DOI were not checked. — [AGRIS record](https://agris.fao.org/search/fr/records/682f3fde9d0aa4165340c76c)
- **[verified]** Szatmári, G., Pásztor, L., Heuvelink, G.B.M. (2021). Estimating soil organic carbon stock change at multiple scales using machine learning and multivariate geostatistics. *Geoderma* 403: 115356. https://doi.org/10.1016/j.geoderma.2021.115356. Supports range from point to 1 km, 10 km, counties and country. Uncertainty shrinks with support. The authors conclude that totals with quantified uncertainty "cannot be solved by machine learning alone". — [ISRIC news](https://www.isric.org/news/new-article-published-soil-organic-carbon-estimation-multiple-scales); [sciencegate](https://www.sciencegate.app/document/10.1016/j.geoderma.2021.115356)
- **[partially verified]** Szatmári et al. (2024). Space-time modelling of soil organic carbon stock change at multiple scales: Case study from Hungary. *Geoderma* 451: 117067. The DOI was not checked; it is probably 10.1016/j.geoderma.2024.117067. — [OUCI](https://ouci.dntb.gov.ua/works/4NpEWj69); [MTAK](https://real.mtak.hu/210476)
- **[partially verified]** Disaggregating a regional digital soil map with Bayesian area-to-point regression kriging for farm-scale soil carbon assessment. *SOIL* 6: 359 (2020). Authors not recorded. — [SOIL](https://soil.copernicus.org/articles/6/359/2020/soil-6-359-2020.html)
- The requested "Heuvelink et al. 2016, spatial aggregation of soil property predictions" **could not be found** under that title. It may be a conflation. The closest real items are Heuvelink & Pebesma (1999), Wadoux & Heuvelink (2023) and Szatmári et al. (2021). [UNVERIFIED, recalled] A possible candidate is Heuvelink, Kros, Reinds, de Vries (2016), Geostatistical prediction and simulation of European soil property maps, *Geoderma Regional* 7: 201–215. Check it before citing.

### Inferences
- The block model n_eff = A/L² with a direct Monte Carlo check is a simplified version of the Wadoux & Heuvelink (2023) Monte Carlo method. The 0.1–2.5% range is a scenario envelope. Reviewers will ask what the actual correlation length of the map errors is. A variogram of hold-out (or cross-validation) standardized residuals would answer that, even with only 20 points (and with large uncertainty).
- The "systematic error" end (2.5%) is the fully correlated limit, where errors do not average out. That case is the policy-relevant one for a farm total, because a biased map leaves the farm total biased.

### Gaps
- Not verified this session: Heuvelink (2018) chapter on uncertainty propagation in *Pedometrics* (Springer); Vaysse & Lagacherie (2017, *Geoderma* 291: 55, quantile regression forest uncertainty); Styc & Lagacherie (2019) and Román Dobarco et al. (2019) on AWC error propagation, where texture dominates. All three are relevant analogues and are **[UNVERIFIED]**.

## 2. Propagating soil-map or soil-test uncertainty into fertilizer recommendations, N balances, leaching and VR prescriptions

### Takeaway
The closest precedent is Takoutsing, Heuvelink et al. (2024/2025). It propagated DSM uncertainty by Monte Carlo through QUEFTS into N/P/K recommendations and threshold-probability maps. That is very close to NFert's design (NFert also couples QUEFTS in `optimize_VR_DPI`). I found no study that propagates DSM uncertainty through a **regulatory** N balance, or that reports field/farm totals as a function of error correlation.

### Cited findings
- **[verified]** Takoutsing, B., Heuvelink, G.B.M., Aynekulu, E., Shepherd, K.D. (2024; print 2025). Modelling and mapping maize yields and making fertilizer recommendations with uncertain soil information. *Precision Agriculture* 26(1): article 5. https://doi.org/10.1007/s11119-024-10200-6. — [Crossref](https://api.crossref.org/works/10.1007/s11119-024-10200-6); [Springer](https://link.springer.com/article/10.1007/s11119-024-10200-6)
  - Monte Carlo recommendations were up to 59, 42 and 20 kg/ha lower in N, P and K than the deterministic ones, so the nonlinear model creates a bias as well as a spread. Stochastic sensitivity analysis: SOC drove 97% of N-fertilizer uncertainty, pH drove 81.6% for K, and extractable P (55%) and exchangeable K (20%) drove P. A threshold probability map was proposed as a decision aid. (Source: search-result abstract; full text not accessed.)
  - Note: a copy of this paper was in the repo's `references/` folder (now deleted per git status), so the authors probably know it.
- **[verified]** Lark, R.M., Knights, K.V. (2015). The implicit loss function for errors in soil information. *Geoderma* 251–252: 24–32. https://doi.org/10.1016/j.geoderma.2015.03.014. Treats soil-information error as an economic loss in a fertilizer decision. The expected loss is minimized at a quantile of the conditional distribution, which gives a decision-theoretic basis for sample size. — [Crossref](https://api.crossref.org/works?query.bibliographic=The+implicit+loss+function+for+errors+in+soil+information); [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0016706115000853)
- **[verified]** Schut, A.G.T., Giller, K.E. (2020). Soil-based, field-specific fertilizer recommendations are a pipe-dream. *Geoderma* 380: 114680. https://doi.org/10.1016/j.geoderma.2020.114680. Soil sampling and analysis errors have an effect on estimated P/K supply at least as large as the variation among smallholder fields. — [Crossref](https://api.crossref.org/works?query.bibliographic=Soil-based+field-specific+fertilizer+recommendations+are+a+pipe-dream); [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0016706120314750)
  - Rebuttal **[verified]**: Ros, G.H., Luleva, M., de Vries, W. (2021). Comment titled "Soil analysis is pivotal for fertilizer recommendations…". *Geoderma* 387: 114861. https://doi.org/10.1016/j.geoderma.2020.114861. — same Crossref query
- **[partially verified]** INL/OSTI preprint INEEL/CON-04-02144, "The Impact of Soil Sampling Errors on Variable Rate…". For many fertility parameters, laboratory error variance exceeded the spatial variability across grid locations. — [OSTI](https://www.osti.gov/servlets/purl/910814)
- **[verified]** Hack-ten Broeke, M.J.D., de Groot, W.J.M. (1998). Evaluation of nitrate leaching risk at site and farm level. *Nutrient Cycling in Agroecosystems* 50: 271–276. https://doi.org/10.1023/A:1009704714949. Simulations over multiple soil-profile descriptions gave a farm-wide distribution. The probability of exceeding 11.3 mg/L NO3-N was 63% for the farm (1991–95) and varied strongly with year, crop and hydrology. An early "probability of exceedance at farm level" combining soil variability and weather years. — [Crossref](https://api.crossref.org/works/10.1023/A:1009704714949); [Springer](https://link.springer.com/article/10.1023/A:1009704714949)
- **[partially verified]** Courteille, L., Lagacherie, P., Bailly, J.-S. Uncertainty of soil quality maps: estimation and relative contributions of its different sources. SSRN preprint (id 6813586). Argues that total uncertainty must combine input-map error with assessment-model parameter error, and that the latter "has been largely overlooked". Full text blocked (HTTP 403); peer-review status unknown. — [SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6813586)

### Inferences
- NFert's 95% texture dominance contrasts with Takoutsing's 97% SOC dominance for N. That contrast is interesting in its own right. It follows from model structure: the DPI balance uses texture-dependent coefficients (leaching, availability classes), while QUEFTS uses SOC for N supply. That is evidence that the *regulatory model form*, not only map quality, decides which soil property matters.
- Takoutsing found a Monte Carlo vs deterministic **bias**. NFert should report the mean shift as well as the SD, since texture-class thresholds in the DPI are nonlinear or step-like.
- Courteille et al. suggest NFert should state that regulatory coefficient uncertainty is excluded (or include it). Otherwise 3.3% understates total uncertainty.

### Gaps
- No verified study was found that propagates DSM uncertainty into a VR N prescription with spatially correlated simulation. Takoutsing et al.'s handling of spatial correlation is unknown (full text not accessed). Check whether they simulated per pixel independently.
- Kerry & Oliver, Pásztor (fertilizer-related DSM) and Lark on VR N were searched without finding a matching paper. Nothing to cite.

## 3. Uncertainty of N budgets and surplus indicators at farm and regional level; regulators and uncertainty

### Takeaway
Budget uncertainty is well studied at farm-gate and national level. Typical results: farm surplus CV around 8%, loss terms CV above 30%, and differences between datasets as large as the median for some countries. Guidance (EUNEP) asks for uncertainty to be reported. No source found shows a regulator formally using uncertainty in compliance decisions.

### Cited findings
- **[verified]** Oenema, O., Kros, H., de Vries, W. (2003). Approaches and uncertainties in nutrient budgets: implications for nutrient management and environmental policies. *European Journal of Agronomy* 20(1–2): 3–16. https://doi.org/10.1016/S1161-0301(03)00067-4. Farm-gate budgets are less uncertain than soil-surface budgets and so are preferred as a policy instrument. Uncertainty concentrates in loss partitioning, with Dutch denitrification and leaching CV above 30%. The paper calls for standard uncertainty-analysis procedures. — [Scilit](https://www.scilit.net/publications/569c98d16f055025605e0f13514eaaa1)
- **[verified]** Oenema, J., Burgers, S., van Keulen, H., van Ittersum, M. (2015). Stochastic uncertainty and sensitivities of nitrogen flows on dairy farms in The Netherlands. *Agricultural Systems* 137: 126–138. https://doi.org/10.1016/j.agsy.2015.04.009. Monte Carlo results: farm N surplus CV 8% (SD 15 kg N/ha), soil-surface surplus CV 12% (SD 16), grazing intake CV 49%. — [Crossref](https://api.crossref.org/works?query.bibliographic=Stochastic+uncertainty+and+sensitivities+of+nitrogen+flows+on+dairy+farms+in+The+Netherlands); [ScienceDirect](https://sciencedirect.com/science/article/abs/pii/S0308521X15000608)
- **[verified]** Zhang, X., Zou, T., Lassaletta, L., et al. (2021). Quantification of global and national nitrogen budgets for crop production. *Nature Food* 2: 529–540. https://doi.org/10.1038/s43016-021-00318-5. Compares 13 datasets for 115 countries (1961–2015). Global 2010 surplus 86 (68–97) Tg N/yr; NUE 46% (40–53%). Some country budget terms have ranges as large as their medians. — [Nature PDF](https://www.nature.com/articles/s43016-021-00318-5.pdf); [PBL](https://www.pbl.nl/en/node/6055). Author list beyond the first author not checked; cite as "Zhang et al.".
- **[verified]** Miller, C.M.F., Waterhouse, H., Harter, T., Fadel, J.G., Meyer, D. (2020). Quantifying the uncertainty in nitrogen application and groundwater nitrate leaching in manure based cropping systems. *Agricultural Systems* 184: 102877. https://doi.org/10.1016/j.agsy.2020.102877. Errors in application rate carry through to balance metrics and leaching, and affect "regulatory effectiveness". — [Crossref](https://api.crossref.org/works?query.bibliographic=Quantifying+the+uncertainty+in+nitrogen+application+and+groundwater+nitrate+leaching+in+manure+based+cropping+systems); [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0308521X19315525)
- **[verified]** Rahimi, J., Haas, E., Scheer, C., Grados, D., Abalos, D., Aderele, M.O., Blicher-Mathiesen, G., Butterbach-Bahl, K. (2024). Aggregation of activity data on crop management can induce large uncertainties in estimates of regional nitrogen budgets. *npj Sustainable Agriculture* 2: 7. https://doi.org/10.1038/s44264-024-00015-3. Denmark, LandscapeDNDC: with aggregated management data, gaseous losses were overestimated by about 18–31% and nitrate leaching by about 205% in one approach. — [Crossref](https://api.crossref.org/works/10.1038/s44264-024-00015-3)
- **[partially verified]** EU Nitrogen Expert Panel, *NUE Guidance Document* (2023). Asks that uncertainties be discussed alongside reported N surplus and NUE. — [EUNEP PDF](https://www.eunep.com/wp-content/uploads/2023/12/NUE-Guidance-Document.pdf)

### Inferences
- Scale comparison for the paper: soil-map-driven farm-total SD of 0.1–2.5% is small next to typical farm-surplus CV (about 8%) and loss-term CV (above 30%). In a regulatory balance, DSM error is probably a second-order source next to weather and loss coefficients. That is a useful, honest framing.
- Change of support also hits the input side. Rahimi et al. show that aggregating management data biases regional budgets, which parallels aggregating soil inputs before versus after the model (Heuvelink & Pebesma 1999).

### Gaps
- No source found shows Emilia-Romagna, or any Nitrates Directive authority, treating uncertainty in MAS/DPI compliance (for example tolerance bands). Searched and not found. The regulation text itself should be checked.
- EU gross nitrogen balance (Eurostat/OECD) uncertainty papers were not retrieved.

## 4. Weather uncertainty combined with soil uncertainty; probability of non-compliance and risk-based management

### Takeaway
It is well established that weather (rainfall) and soil texture jointly control N response. Explicit exceedance probabilities exist for leaching at farm level (Hack-ten Broeke & de Groot 1998) and as threshold-probability maps (Takoutsing et al.). I found no study that compares DSM error with weather variability inside a regulatory N dose and expresses the result as a probability of exceeding a legal limit.

### Cited findings
- **[verified]** Tremblay, N., et al. (2012). Corn response to nitrogen is influenced by soil texture and weather. *Agronomy Journal* 104(6): 1658–1671. https://doi.org/10.2134/agronj2012.0184. Meta-analysis of 51 N-rate trials (2006–09). Response was stronger in fine-textured soils, and abundant, well-distributed rainfall amplified it (4.5-fold yield increase with in-season N). — [CIMMYT repository](https://repository.cimmyt.org:443/handle/10883/23134); [CORE PDF](https://core.ac.uk/download/14342957.pdf)
- Hack-ten Broeke & de Groot (1998), above: 63% farm-level probability of exceeding the nitrate threshold, varying by year and hydrology.
- Takoutsing et al. (2024), above: threshold-probability maps for fertilizer decisions.
- Index tools (New York Nitrate Leaching Index; Ohio N&P risk assessment) combine rainfall and soil drainage into risk classes, not probabilities. — [Cornell NLI manual](http://nmsp.cals.cornell.edu/publications/extension/NLeachingIndex2022.pdf)

### Inferences
- NFert's comparison (weather changes the dose by 26%; soil-map error by 3.3% per pixel and up to 2.5% of the farm total) is the most decision-relevant result. It sets a ranking of uncertainty sources inside a legal instrument, an information-value question in the sense of Lark & Knights (2015).
- Caveat: the 26% is a deterministic scenario contrast (measured rainfall versus default), while the 3.3% is a Monte Carlo SD. They are not the same statistic. Put both on a common footing, for example SD or a 90% interval across a multi-year rainfall ensemble, before ranking them.

### Gaps
- No verified study combines a weather ensemble with DSM Monte Carlo in an N recommendation. Absence is not proof; searches were limited.

## 5. Area of applicability and validation of soil maps used for decisions

### Takeaway
With 20 samples, hold-out RMSE is itself uncertain and may not apply across the whole farm. The AOA method (Meyer & Pebesma 2021) and validation of uncertainty estimates are standard expectations.

### Cited findings
- **[verified]** Meyer, H., Pebesma, E. (2021). Predicting into unknown space? Estimating the area of applicability of spatial prediction models. *Methods in Ecology and Evolution* 12(9): 1620–1633. https://doi.org/10.1111/2041-210X.13650 (DOI from the publisher record pattern; volume and pages verified via MaRDI/CiNii). Defines the AOA as the area "for which the cross-validation error of the model applies", using an importance-weighted dissimilarity index. — [MaRDI](https://portal.mardi4nfdi.de/wiki/Publication:64347); [arXiv 2005.07939](https://arxiv.org/abs/2005.07939)
- Extension (EGU24, Schumacher, Knoth, Ludwig, Meyer): plain AOA lets a single training point make a region "applicable"; they propose a density-aware version. — [EGU24-10278](https://meetingorganizer.copernicus.org/EGU24/EGU24-10278.html)
- **[partially verified]** "Validation of uncertainty predictions in digital soil mapping" (2023). Authors and venue not confirmed (ResearchGate record). — [ResearchGate](https://www.researchgate.net/publication/372401684_Validation_of_uncertainty_predictions_in_digital_soil_mapping)

### Inferences
- In NFert the RMSE plays the role of a homoscedastic, stationary error SD. The paper should (a) report the AOA or dissimilarity index for the Sentinel-2 bare-soil covariates; (b) acknowledge that an RMSE from 20 points has a wide confidence interval (a chi-square interval on n of about 5–20 hold-out points is wide); and (c) test the sensitivity of the conclusions to RMSE inflated, for example, ×1.5.

### Gaps
- Not verified: Wadoux et al. on spatial cross-validation bias, and Ploton et al. (2020, *Nature Communications*) on spatial validation. Both are relevant **[UNVERIFIED]**.

## 6. What is new and what is textbook, and suggested research questions

### Takeaway
Textbook: Monte Carlo propagation of DSM error, stochastic sensitivity attribution, and shrinking aggregate uncertainty governed by error autocorrelation (n_eff ≈ A/L²), with no shrinkage for systematic error. New (no precedent found): applying this to a **regulatory** N balance (DPI 2026), where the legal decision sits at farm level; showing that regulatory model form makes texture, not SOC, the dominant input; and placing DSM uncertainty next to weather in the same legal dose, framed as compliance risk.

### Cited findings (basis for novelty claims)
- Closest prior work: Takoutsing et al. 2024 (QUEFTS, MC, threshold maps) — [Crossref](https://api.crossref.org/works/10.1007/s11119-024-10200-6). Aggregation method: Wadoux & Heuvelink 2023 — [ISRIC](https://www.isric.org/news/new-paper-efficient-new-method-calculate-uncertainty-spatial-averages). Budget-uncertainty context: Oenema et al. 2003; Oenema et al. 2015 — [Scilit](https://www.scilit.net/publications/569c98d16f055025605e0f13514eaaa1).

### Inferences: suggested research questions
1. **RQ1 (support and correlation):** How does DSM-propagated uncertainty in the regulatory N dose change from pixel to field to farm support, and how much of the farm-level uncertainty comes from spatially correlated or systematic map error rather than random error? Turn the L-scenario scan into an *estimated* L, from a variogram of standardized hold-out residuals as in Wadoux & Heuvelink (2023), and report the scenarios as a sensitivity bracket. Name the bias case explicitly as the policy-relevant one.
2. **RQ2 (which soil property, and why):** Which mapped properties control dose uncertainty in a regulatory balance, and how does that differ from process/QUEFTS-based recommendations (texture 95% vs SOC 97% in Takoutsing et al.)? Include the nonlinearity and bias from texture-class thresholds (mean shift, not only SD).
3. **RQ3 (ranking of uncertainty sources):** How large is soil-map uncertainty compared with weather (rainfall-driven leaching) and, optionally, regulatory-coefficient uncertainty? Use a common metric, for example variance across a multi-year weather ensemble, so the result can answer whether better soil maps are worth paying for compared with better weather inputs (value of information, Lark & Knights 2015).
4. **RQ4 (compliance risk, optional):** What is the probability that the farm N total or a field dose exceeds the legal MAS ceiling, given soil-map and weather uncertainty? This turns the result into an action-oriented output, in line with Hack-ten Broeke & de Groot (1998) and Takoutsing et al. (2024).
- Framing advice: do not claim novelty for "accounting for spatial correlation". Claim it for the *regulatory* context and the *ranking* of uncertainty sources. Expect reviewers to ask for an AOA and for an acknowledgement of RMSE uncertainty with n = 20.

### Gaps
- Whether Takoutsing et al. used spatially correlated simulation and aggregated to totals (full text not read). This decides how much RQ1 differs from them, so check the PDF the authors already held.
- No search covered Italian or regional literature (for example CREA or ARPAE work on DPI uncertainty).
