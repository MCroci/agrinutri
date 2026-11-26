# SoftwareX manuscript

Source of the SoftwareX Original Software Publication on agrinutri 1.2.0.

| File | Content |
|---|---|
| `agrinutri_SoftwareX.md` | manuscript (Markdown, pandoc citations) |
| `agrinutri_SoftwareX.docx` | rendered manuscript (`sh render.sh`) |
| `references.bib` | references cited in the manuscript, collected by `make_bib.py` (from `references_intl.bib` first, then the project .bib files) |
| `fig1_architecture.py` | Fig. 1, architecture diagram (modules colour-coded) |
| `theme_swx.R` | house style of Figs. 2-6 (Arial 7 pt, mako palette for N doses, NNI centred at 1, term labels, scale bar and north arrow) |
| `fig2_farm.R` | Fig. 2, nitrogen: `farm_balance()` on four satellite-delineated fields (one per crop), 2024, with the standard dose (after `piacenza/a01_inputs.R`) |
| `fig3_p01_years.R` | Fig. 3, nitrogen: plot P01 through 2019-2026, balance terms and October-January rainfall (`data/p01_years.csv`) |
| `fig4_pk.R` | Fig. 4, phosphorus and potassium: P01 rotation, farm plots, P and K availability classes on the regional maps |
| `fig5_data.R`, `fig5_rs.R` | Fig. 5, Sentinel-2 to prescription on plot P01 (`data/rs_*`, local only; scene read from the Microsoft Planetary Computer STAC catalogue) |
| `fig6_strategies.R` | Fig. 6, prescription methods: input layers, six maps on one dose scale, cell-dose distribution |
| `piacenza/` | province example of Section 4 (figure `piacenza_2019_2026`, not in the article): `a01_inputs.R` (fields, regional soil maps, ERA5), `a02_balance.R` (balance 2019-2026, aggregates), `a03_figure.R`, `crop_map.csv` (crop class to DPI crop). Field-level files stay local (`.gitignore`); env vars `KWASI_DATA`, `RER_SOIL` |
| `pubfig.py` | figure style (journal sizes, fonts, DPI) |
| `make_refdoc_swx.py` | Word reference document (house style, monospaced code) |

Regenerate, from this folder:

```sh
# from the package root
Rscript paper/softwarex/piacenza/a01_inputs.R && Rscript paper/softwarex/piacenza/a02_balance.R
Rscript paper/softwarex/fig2_farm.R && Rscript paper/softwarex/fig3_p01_years.R && Rscript paper/softwarex/fig4_pk.R
(cd paper/softwarex && Rscript fig5_data.R) && Rscript paper/softwarex/fig5_rs.R   # fig2_farm.R writes data/rs_field.geojson
Rscript paper/softwarex/fig6_strategies.R
Rscript paper/softwarex/piacenza/a03_figure.R
(cd paper/softwarex && python fig1_architecture.py && python make_bib.py && sh render.sh)
```

The comparison with Fert_Office (test fixture and validation figure) is not part of the article;
its scripts are in `../_archive/softwarex_validation/`.

Items left for the authors are marked `[...]` in the manuscript: Zenodo DOI,
competing interests, CRediT statement, grant number and the course details in
Section 4.
