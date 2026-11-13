# Soil Texture Class Determination (Simplified)

Determines a simplified soil texture class based on clay and sand
percentages.

## Usage

``` r
tri3(clay = 10, sand = 35, tri3.table = agrinutri_data_get("tri3.table"))
```

## Arguments

- clay:

  Percentage of clay in the soil (0-100).

- sand:

  Percentage of sand in the soil (0-100).

- tri3.table:

  A matrix containing the simplified soil texture classes based on clay
  and sand percentages. The default is the package dataset `tri3.table`.

## Value

A character string representing the simplified soil texture class (e.g.,
"Sandy", "Loamy", "Clayey"). If the `clay` and `sand` combination does
not fall within the defined classes in `tri3.table`, returns NA.

## Note

- This function provides a simplified classification based on the USDA
  soil texture triangle. For a more detailed classification, consider
  using the
  [`tri2()`](https://mcroci.github.io/agrinutri/reference/tri2.md)
  function.

- As in Fert_Office (foglio `Suolo`), `clay` and `sand` are truncated to
  whole percentages (`INT`) before the triangle lookup, so 40.6 % clay
  is read as 40 %.

- Ensure that `clay` and `sand` percentages are valid (within 0-100) and
  their sum does not exceed 100.

## Examples

``` r
tri3(clay = 10, sand = 35)  # "Sandy"
#>   35 
#> "FL" 
tri3(clay = 25, sand = 20)  # "Loamy"
#>   20 
#> "FL" 
tri3(clay = 55, sand = 15)  # "Clayey"
#>  15 
#> "A" 
```
