# Translate an English alias into its canonical Italian agrinutri key

Case-insensitive lookup in one of the agrinutri translation dictionaries
([`crop_en2it`](https://mcroci.github.io/agrinutri/reference/i18n.md),
[`prev_crop_en2it`](https://mcroci.github.io/agrinutri/reference/i18n.md),
[`source_en2it`](https://mcroci.github.io/agrinutri/reference/i18n.md),
[`modality_epoch_en2it`](https://mcroci.github.io/agrinutri/reference/i18n.md),
[`level_en2it`](https://mcroci.github.io/agrinutri/reference/i18n.md)).
Falls back to the input unchanged when no match is found, so strings
that already happen to be in the Italian canonical form pass through.

## Usage

``` r
agrinutri_en2it(
  x,
  kind = c("crop", "prev_crop", "source", "modality_epoch", "level")
)
```

## Arguments

- x:

  Character (or character vector) of English aliases to translate.

- kind:

  One of `"crop"`, `"prev_crop"`, `"source"`, `"modality_epoch"`,
  `"level"`. Selects which dictionary to use.

## Value

A character vector the same length as `x`.

## Examples

``` r
agrinutri_en2it("Silage maize (class 700)",  kind = "crop")
#> [1] "Mais trinciato classe 700"
agrinutri_en2it("Maize stalks removed",       kind = "prev_crop")
#> [1] "Mais stocchi asportati"
agrinutri_en2it(c("Dairy cattle slurry", "None"), kind = "source")
#> [1] "liquami bovini da latte" NA                       
```
