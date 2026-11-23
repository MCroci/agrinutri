# Organic nitrogen efficiency by material, soil texture and distribution (DPI)

Returns the fraction of total organic N that is available to the crop in
the year of application, according to DPI (type of effluent, soil
texture and distribution technique). Used when `soil_group` and
`distribution_efficiency` are passed to
[`organic_fertilization()`](https://mcroci.github.io/agrinutri/reference/organic_fertilization.md).

## Usage

``` r
organic_N_efficiency(source, soil_group, distribution_efficiency)
```

## Arguments

- source:

  Character. Organic fertilizer source (e.g. "Cattle slurry").

- soil_group:

  Character. Soil group from
  [`calc_soil_group_and_id_rag()`](https://mcroci.github.io/agrinutri/reference/calc_soil_group_and_id_rag.md)
  (e.g. "Sandy textures", "Loamy textures", "Clay textures").

- distribution_efficiency:

  Character. "efficient", "medium", or "low". Efficient = injection,
  fertigation, incorporation within 4 h; medium = band spreading with
  incorporation; low = surface spreading without incorporation.

## Value

Numeric. Efficiency as a fraction between 0 and 1, or `NA` if not found.
For soil amendments (compost, mature manure, solid digestate) returns
0.40 (40%).

## References

DPI Emilia-Romagna, fertilisation guide; FertDPI efficiency sheet.
Sandy/loamy/clay soil x efficient/medium/low-efficiency distribution.

## Examples

``` r
organic_N_efficiency("Cattle slurry", "Sandy textures", "efficient")
#> [1] 0.671
organic_N_efficiency("Composted manure", "Loamy textures", "medium")  # 0.40
#> [1] 0.4
```
