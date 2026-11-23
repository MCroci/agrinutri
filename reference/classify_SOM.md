# Classify SOM (soil organic matter) initial content by texture group

Returns the DPI 2026 SOM rating (very low / low / medium / high) by soil
texture group (sandy / loamy / clay textures) and maps it to the 3-class
scheme (Poor / Normal / Rich) used for the maximum annual SOM input.

## Usage

``` r
classify_SOM(SOM, soil_group, so.table = agrinutri_data_get("so.table"))
```

## Arguments

- SOM:

  Soil organic matter (% mass).

- soil_group:

  DPI texture group (see
  [`normalise_soil_group()`](https://mcroci.github.io/agrinutri/reference/normalise_soil_group.md)).

- so.table:

  Lookup (default
  [`agrinutri::so.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).

## Value

List with `rating` (4 classes) and `class` (3-class for SOM input).

## Examples

``` r
classify_SOM(SOM = 2, soil_group = "Loamy textures")
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
