# Organic nitrogen efficiency by material, soil texture and distribution (DPI)

Returns the fraction of total organic N that is available to the crop in
the year of application, according to DPI (tipo di effluente, tessitura,
modalita di distribuzione). Used when `soil_group` and
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
  (e.g. "Sandy textures", "Franco", "Clayey") or DPI class: "sabbioso",
  "franco", "argilloso".

- distribution_efficiency:

  Character. "efficient" (Alta), "medium" (Media), or "low" (Bassa).
  Alta = iniezione, fertirrigazione, interramento entro 4 h; Media =
  rasoterra con interramento; Bassa = spandimento superficiale senza
  incorporazione.

## Value

Numeric. Efficiency as a fraction between 0 and 1, or `NA` if not found.
For ammendanti (compost, letame maturo, digestato palabile) returns 0.40
(40%).

## References

DPI Emilia-Romagna, Guida alla fertilizzazione; FertDPI foglio
Efficienza. Terreno sabbioso/franco/argilloso x distribuzione
efficiente/media/poco efficiente.

## Examples

``` r
organic_N_efficiency("Cattle slurry", "Sandy textures", "efficient")
#> [1] 0.671
organic_N_efficiency("Composted manure", "Franco", "medium")  # 0.40
#> [1] 0.4
```
