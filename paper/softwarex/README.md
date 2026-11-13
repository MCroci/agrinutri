# SoftwareX manuscript

Source of the SoftwareX Original Software Publication on agrinutri 1.0.0.

| File | Content |
|---|---|
| `agrinutri_SoftwareX.md` | manuscript (Markdown, pandoc citations) |
| `agrinutri_SoftwareX.docx` | rendered manuscript (`sh render.sh`) |
| `references.bib` | references cited in the manuscript, collected by `make_bib.py` |
| `fig1_architecture.py` | Fig. 1, architecture diagram |
| `fig2_data.R`, `fig2_farm.py` | Fig. 2, demonstration farm |
| `fig3_data.R`, `fig3_rs_prescription.py` | Fig. 3, Sentinel-2 to prescription on a satellite-delineated field (`data/rs_*`, local only; env var `PRESTO_DEPLOY`) |
| `piacenza/` | Section 3.4 and Fig. 4: `a01_inputs.R` (fields, regional soil maps, ERA5), `a02_balance.R` (balance 2019-2026, aggregates), `a03_figure.R`, `crop_map.csv` (crop class to DPI crop). Field-level files stay local (`.gitignore`); env vars `KWASI_DATA`, `RER_SOIL` |
| `pubfig.py` | figure style (journal sizes, fonts, DPI) |
| `make_refdoc_swx.py` | Word reference document (house style, monospaced code) |

Regenerate, from this folder:

```sh
Rscript fig2_data.R && Rscript fig3_data.R
python fig1_architecture.py && python fig2_farm.py && python fig3_rs_prescription.py
Rscript piacenza/a01_inputs.R && Rscript piacenza/a02_balance.R && Rscript piacenza/a03_figure.R   # from the package root
python make_bib.py && sh render.sh
```

The comparison with Fert_Office (test fixture and validation figure) is not part of the article;
its scripts are in `../_archive/softwarex_validation/`.

Items left for the authors are marked `[...]` in the manuscript: Zenodo DOI,
competing interests, CRediT statement, grant number and the course details in
Section 4, plus the access conditions of the CERZOO soil maps.
