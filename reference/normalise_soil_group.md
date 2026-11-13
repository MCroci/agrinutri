# Normalise a soil-group label across the three agrinutri conventions

agrinutri tables use three parallel naming conventions for the DPI 2026
texture grouping:

## Usage

``` r
normalise_soil_group(x)
```

## Arguments

- x:

  Character string. Soil group name in any supported convention.

## Value

A list with `id_rag` (1 = Sandy, 2 = Loamy, 3 = Clay), `en` (canonical
English), `it_plural`, `it_singular`.

## Details

- English (legacy agrinutri 0.1.0): "Sandy textures", "Loamy textures",
  "Clay textures".

- Italian plural (canonical DPI; foglio B, SO, Gri_K): "Sabbiosi",
  "Medio impasto", "Argillosi e limosi".

- Italian singular adjective (foglio Ragg_Tes): "Sabbioso", "Franco",
  "Argilloso".

This helper accepts any of these forms (case-insensitive) and returns
the canonical English form (used by agrinutri \>= 0.4.0 lookup tables)
plus the universal `ID_Rag` integer key used internally to join the
lookup tables.

## Examples

``` r
normalise_soil_group("Loamy textures")
#> $id_rag
#> [1] 2
#> 
#> $it_plural
#> [1] "Medio impasto"
#> 
#> $it_singular
#> [1] "Franco"
#> 
#> $en
#> [1] "Loamy textures"
#> 
normalise_soil_group("Medio impasto")
#> $id_rag
#> [1] 2
#> 
#> $it_plural
#> [1] "Medio impasto"
#> 
#> $it_singular
#> [1] "Franco"
#> 
#> $en
#> [1] "Loamy textures"
#> 
normalise_soil_group("Franco")
#> $id_rag
#> [1] 2
#> 
#> $it_plural
#> [1] "Medio impasto"
#> 
#> $it_singular
#> [1] "Franco"
#> 
#> $en
#> [1] "Loamy textures"
#> 
```
