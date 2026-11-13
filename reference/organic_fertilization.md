# Nitrogen Provided by Organic Fertilization

Calculates the amount of nitrogen (N) supplied to the soil through
organic fertilization. Optionally applies **DPI efficiency** by material
type, soil `distribution_efficiency` are both given). If either is
`NULL`, falls back to `f.table`: `value * quantity / 100`. Function
[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
passes computed soil texture and defaults distribution to `"medium"` so
`Forg` matches the DPI path used by Fert_Office (*Apporti al terreno*).
In the balance formula the term to subtract is the **efficient N** (N
utile) available to the crop in the year of application, not total N
(DPI Guida / FertDPI).

## Usage

``` r
organic_fertilization(
  source = "Cattle slurry",
  frequency = "every year",
  quantity = 100,
  soil_group = NULL,
  distribution_efficiency = NULL,
  f.table = agrinutri_data_get("f.table")
)
```

## Arguments

- source:

  The source of organic fertilizer (e.g., "Cattle slurry", "Composted
  manure").

- frequency:

  The frequency of application (e.g., "every year", "every two years").

- quantity:

  The amount of organic fertilizer applied per application (in m3/ha
  cubic metres, or t/ha). Use `0` for no organic application (returns 0
  kg N/ha).

- soil_group:

  Optional. Soil group from
  [`calc_soil_group_and_id_rag()`](https://mcroci.github.io/agrinutri/reference/calc_soil_group_and_id_rag.md)
  (e.g. "Sandy textures", "Franco") to use DPI efficiency by texture. If
  `NULL`, efficiency is taken from `f.table` (no texture/distribution).

- distribution_efficiency:

  Optional. `"efficient"`, `"medium"`, or `"low"` (DPI:
  Alta/Media/Bassa). Required together with `soil_group` for the DPI
  efficiency path.

- f.table:

  A data frame with columns `source`, `frequency`, `value`. Used when
  `soil_group` is `NULL`. Default is
  [`agrinutri::f.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

The estimated amount of nitrogen (N) in kg/ha available to the crop
(efficient N when `soil_group` and `distribution_efficiency` are set).

## References

DPI Emilia-Romagna, Guida alla fertilizzazione; efficienza in funzione
di tipologia di effluente, tessitura e modalita di distribuzione
(Tabella 7 Norme Generali).

## Examples

``` r
organic_fertilization(source = "Cattle slurry", frequency = "every year", quantity = 50)
#> [1] 0.15
organic_fertilization("Cattle slurry", "every year", 80,
  soil_group = "Sandy textures", distribution_efficiency = "efficient")
#> [1] 241.56
```
