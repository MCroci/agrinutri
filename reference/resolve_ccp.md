# Resolve a `ccp` (crop calendar period) string with whitespace and dash normalisation

Handles common variations between user input and the canonical English
value stored in `coef_time$ccp`:

- Trims outer whitespace and collapses internal multiple spaces.

- Replaces en-dash (U+2013) and em-dash (U+2014) with hyphen.

- Case-insensitive match.

## Usage

``` r
resolve_ccp(x, table = agrinutri_data_get("coef_time"))
```

## Arguments

- x:

  Character. The `ccp` string to resolve.

- table:

  Lookup with column `ccp`; default
  [`agrinutri::coef_time`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

The canonical `ccp` string (as in `table$ccp`), or `x` unchanged with a
warning if not found.

## Examples

``` r
resolve_ccp("Spring-summer crop 100\u2013130 days")  # em-dash
#> [1] "Spring-summer crop 100-130 days"
resolve_ccp("autumn-winter crop <150 days")         # case
#> [1] "Autumn-winter crop <150 days"
```
