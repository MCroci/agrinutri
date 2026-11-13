# TODO

## Vignettes: better figures with large-scale Emilia-Romagna data

The vignettes (`vignettes/*.Rmd`) currently illustrate the package with small examples
(one field at CERZOO, the bundled demonstration farm, the Cremonesi soil rasters). Rework their
figures to show what the package does at regional scale:

- [ ] `spatial-balance.Rmd`: replace the Cremonesi rasters with a clip of the regional
      Emilia-Romagna soil maps 0-30 cm (clay, sand, organic carbon, total N; Servizio Geologico,
      Sismico e dei Suoli) and map the pixel-level N dose over a plain area, not a single field.
- [ ] `farm-and-prescription-map.Rmd`: add a farm-to-province figure from the Piacenza plain
      application (`paper/softwarex/piacenza/`): N requirement by crop and year 2019-2026 and the
      field dose map (aggregated outputs only, no field identifiers).
- [ ] `agrinutri-PK-and-distribution.Rmd`: use the regional Olsen P and exchangeable K maps to show
      P2O5 and K2O availability classes and doses at scale.
- [ ] `agrinutri.Rmd`: one overview figure (soil map -> balance -> dose map -> farm total) in the
      house figure style (Arial 7 pt, mako palette for doses, scale bar and north arrow).
- [ ] Decide what can ship in the package: bundle only small, licence-compatible clips
      (check the reuse terms of the regional soil maps) in `inst/extdata/`, keep the rest as
      pre-rendered figures in `vignettes/figures/`, so `R CMD check` stays fast and offline.
- [ ] Rebuild the pkgdown site and check the figures on https://mcroci.github.io/agrinutri/.
