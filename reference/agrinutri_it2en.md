# Translate an Italian agrinutri canonical key into its English alias

Translate an Italian agrinutri canonical key into its English alias

## Usage

``` r
agrinutri_it2en(
  x,
  kind = c("crop", "prev_crop", "source", "modality_epoch", "level")
)
```

## Arguments

- x:

  Character vector of Italian canonical strings.

- kind:

  One of `"crop"`, `"prev_crop"`, `"source"`, `"modality_epoch"`,
  `"level"`.

## Value

A character vector of English aliases.

## Examples

``` r
agrinutri_it2en("Mais trinciato classe 700", kind = "crop")
#> [1] "Silage maize (class 700)"
```
