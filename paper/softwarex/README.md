# SoftwareX manuscript

Source of the SoftwareX Original Software Publication on agrinutri 1.0.0.

| File | Content |
|---|---|
| `agrinutri_SoftwareX.md` | manuscript (Markdown, pandoc citations) |
| `agrinutri_SoftwareX.docx` | rendered manuscript (`sh render.sh`) |
| `references.bib` | references cited in the manuscript, collected by `make_bib.py` |
| `fig1_architecture.py` | Fig. 1, architecture diagram |
| `theme_swx.R` | house style of Figs. 2-4 (Arial 7 pt, mako palette for doses, NNI centred at 1, scale bar and north arrow) |
| `fig2_farm.R` | Fig. 2, `farm_balance()` on eight satellite-delineated fields, 2024 (after `piacenza/a01_inputs.R`) |
| `fig3_data.R`, `fig3_rs.R` | Fig. 3, Sentinel-2 to prescription on plot P01 of Fig. 2 (`data/rs_*`, local only; env var `PRESTO_DEPLOY`) |
| `piacenza/` | Section 3.4 and Fig. 4: `a01_inputs.R` (fields, regional soil maps, ERA5), `a02_balance.R` (balance 2019-2026, aggregates), `a03_figure.R`, `crop_map.csv` (crop class to DPI crop). Field-level files stay local (`.gitignore`); env vars `KWASI_DATA`, `RER_SOIL` |
| `pubfig.py` | figure style (journal sizes, fonts, DPI) |
| `make_refdoc_swx.py` | Word reference document (house style, monospaced code) |

Regenerate, from this folder:

```sh
# from the package root
Rscript paper/softwarex/piacenza/a01_inputs.R && Rscript paper/softwarex/piacenza/a02_balance.R
Rscript paper/softwarex/fig2_farm.R
(cd paper/softwarex && Rscript fig3_data.R) && Rscript paper/softwarex/fig3_rs.R
Rscript paper/softwarex/piacenza/a03_figure.R
(cd paper/softwarex && python fig1_architecture.py && python make_bib.py && sh render.sh)
```

The comparison with Fert_Office (test fixture and validation figure) is not part of the article;
its scripts are in `../_archive/softwarex_validation/`.

Items left for the authors are marked `[...]` in the manuscript: Zenodo DOI,
competing interests, CRediT statement, grant number and the course details in
Section 4, plus the access conditions of the CERZOO soil maps.
