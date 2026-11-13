# CRAN submission comments — NFert 1.0.0

This is a new submission.

## Test environments

- Local: Windows 11, R 4.5.1
- GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release, oldrel-1)
- (Before submission, also run win-builder (release and devel).)

## R CMD check results

`R CMD check --as-cran` (with vignettes) returns

    0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Michele Croci <michele.croci@unicatt.it>'
  New submission

(A local "unable to verify current time" note depends on network access
during the check.)

## Notes on the package

- `inst/extdata` (about 4 MB) holds the example data needed to run the
  documented workflows: a cropped Sentinel-2 scene and field boundaries, six
  small soil-property GeoTIFFs and the pre-trained Gaussian-process models
  (JSON) used by `estimate_biophysical()`.
- The example of `estimate_biophysical()` is in `\donttest{}` because loading
  the Gaussian-process model takes about 8 s.
- Bundled data are ASCII; Italian crop names with accents are matched
  accent-insensitively.
- The only hard dependency is `terra`. Other features (sf, jsonlite, Rquefts,
  limSolve, shiny, geodata) are optional and loaded from Suggests. Tests and
  examples that need the network (`soilgrids_input()`) are skipped on CRAN.

## Reverse dependencies

None (new submission).
