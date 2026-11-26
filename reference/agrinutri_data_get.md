# Retrieve package objects and lazy-loaded datasets from `data/`.

Lazy datasets are not always bound in `asNamespace("agrinutri")` when
only the namespace is loaded (e.g. `agrinutri::fun()` without
[`library(agrinutri)`](https://github.com/mcroci/agrinutri)). Fall back
to [`utils::data()`](https://rdrr.io/r/utils/data.html) so vignettes and
`::` calls work.

## Usage

``` r
agrinutri_data_get(name)
```

## Details

Kept in `00-agrinutri_data.R` so collation loads this before other
sources.

A table supplied in the option `agrinutri.tables` (a named list)
replaces the bundled one, so the balance can be re-parameterised without
editing the package:
`options(agrinutri.tables = list(uptake_table = my_uptake))`. See
[agrinutri_tables](https://mcroci.github.io/agrinutri/reference/agrinutri_tables.md).
