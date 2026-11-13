# Soil Group and ID_Rag Determination

Determines the soil group and ID_Rag based on clay and sand percentages
using the USDA soil texture triangle.

## Usage

``` r
calc_soil_group_and_id_rag(
  clay = 10,
  sand = 35,
  tri3.table = agrinutri_data_get("tri3.table"),
  soil.table = agrinutri_data_get("soil.table")
)
```

## Arguments

- clay:

  Percentage of clay in the soil (0-100).

- sand:

  Percentage of sand in the soil (0-100).

- tri3.table:

  A matrix containing the simplified soil texture classes based on clay
  and sand percentages. The default is the package dataset `tri3.table`.

- soil.table:

  A data frame mapping soil texture classes (ID_Suo) to soil groups and
  ID_Rag. It should have at least three columns: `ID_Suo`, `Group`, and
  `ID_Rag`. The default is the package dataset `soil.table`.

## Value

A named list containing:

- soil.group: The soil group based on the USDA classification.

- id_rag: The corresponding ID_Rag (numeric ID for the soil group).

## Note

- Ensure the `clay` and `sand` percentages are valid (within 0-100) and
  their sum does not exceed 100.

- The `soil.table` is assumed to contain accurate mappings between soil
  texture classes, groups, and ID_Rag values.

## Examples

``` r
calc_soil_group_and_id_rag(clay = 10, sand = 35)
#> $soil.group
#> [1] "Loamy textures"
#> 
#> $id_rag
#> [1] 2
#> 
#> $TRI3
#> [1] "FL"
#> 
calc_soil_group_and_id_rag(clay = 25, sand = 20)  # Clay loam
#> $soil.group
#> [1] "Loamy textures"
#> 
#> $id_rag
#> [1] 2
#> 
#> $TRI3
#> [1] "FL"
#> 
```
