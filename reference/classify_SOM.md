# Classify SO (soil organic matter) initial content by texture group

Returns DPI 2026 SO class (molto bassa / bassa / media / elevata) by
soil texture group (Sabbiosi / Medio impasto / Argillosi e limosi) and
maps to the 3-class scheme "Scarsa / Normale / Elevata" used for the
maximum annual SO input.

## Usage

``` r
classify_SOM(SOM, soil_group, so.table = agrinutri_data_get("so.table"))
```

## Arguments

- SOM:

  Soil organic matter (% mass).

- soil_group:

  Texture group (Italian).

- so.table:

  Lookup (default
  [`agrinutri::so.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

## Value

List with `rating` (4 classes) and `class` (3-class for SO input).

## Examples

``` r
classify_SOM(SOM = 2, soil_group = "Medio impasto")
#> $rating
#> [1] "medium"
#> 
#> $class
#> [1] "Normal"
#> 
#> $class_it
#> [1] "Normale"
#> 
#> $SOM
#> [1] 2
#> 
#> $soil_group
#> [1] "Loamy textures"
#> 
```
