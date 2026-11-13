# Apply the agrinutri balance to every plot of a farm

Reads a vector layer (GeoJSON, Shapefile, GeoPackage, or an in-memory
`sf` object) in which each feature is an agronomic plot, runs
[`N_balance`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
on every feature using the attributes as arguments, and returns an
enriched `sf` object with the field-scale target N\* (`N_target`, kg N
ha\\^{-1}\\), the crop- specific MAS cap, a compliance flag and the
total N (kg) required by each plot (`N_total_kg = N_target * area_ha`).
The enriched layer can be written back to disk as GeoJSON or any other
OGR format.

## Usage

``` r
farm_balance(
  x,
  p_balance = FALSE,
  k_balance = FALSE,
  output = NULL,
  quiet = TRUE
)
```

## Arguments

- x:

  Either a path to a file readable by
  [`st_read`](https://r-spatial.github.io/sf/reference/st_read.html)
  (GeoJSON, Shapefile, GeoPackage, ...) or a pre-loaded `sf` object.

- p_balance:

  Logical. If `TRUE` also run
  [`P_balance`](https://mcroci.github.io/agrinutri/reference/P_balance.md)
  per plot, using the columns `olsen_value` (ppm) and `olsen_unit`
  (default `"P2O5"`). Adds `P2O5_target` and `P2O5_total_kg`.

- k_balance:

  Logical. Same for
  [`K_balance`](https://mcroci.github.io/agrinutri/reference/K_balance.md),
  with columns `k_value` (ppm) and `k_unit` (default `"K2O"`).

- output:

  Optional path where to write the enriched layer (the extension
  determines the driver used by
  [`st_write`](https://r-spatial.github.io/sf/reference/st_write.html);
  `.geojson` is a common choice).

- quiet:

  Logical, passed to
  [`st_read`](https://r-spatial.github.io/sf/reference/st_read.html) and
  [`st_write`](https://r-spatial.github.io/sf/reference/st_write.html).

## Value

The enriched `sf` object. If `output` is given, the file is also written
to disk (existing files are overwritten).

## Expected attribute columns

Every feature must carry at least:

|  |  |  |
|----|----|----|
| **Column** | **Example** | **Notes** |
| `crop` | "Mais da insilato (classe 700)" | DPI 2026 name |
| `expected_yield_tons_ha` | 60 | target yield |
| `ccp` | "Spring-summer crop 100-130 days" | climate period |
| `sand`, `clay` | 50, 35 | pct of texture |
| `Ntot`, `SOM`, `CN` | 1.2, 1.2, 9.5 | soil analysis |
| `oxygen_availability` | "Normal" / "Low" / "High" |  |
| `winter_rain`, `start_spring_rain` | 160, 40 | mm |
| `prev_crop` | "Winter cereals straw removal" |  |
| `source` | "Cattle slurry" or "None"/NA | organic source |
| `fertorg_frequency` | "every year" |  |
| `location` | "Plain adjacent to urbanized areas" |  |
| `forg_quantity` | 100 | organic dose this year (m\\^3\\/ha or t/ha, see [`N_balance`](https://mcroci.github.io/agrinutri/reference/N_balance.md)) |
| `organic_previous_year_N` | 50 | optional; kg N ha\\^{-1}\\ from organic applied last year (term `F`) |
| `area_ha` | 5.2 | used to derive `N_total_kg` |

Italian aliases (Frumento tenero, Liquame bovino, Cereali vernini -
paglia asportata, ...) are accepted because the underlying agrinutri
functions carry the translation layer.

## Output columns added to the layer

- `N_target`:

  Net mineral N to apply (kg N ha\\^{-1}\\).

- `MAS_cap`:

  Crop-specific maximum allowed dose.

- `MAS_ok`:

  Logical - `N_target <= MAS_cap`.

- `N_total_kg`:

  `N_target * area_ha` (kg N for the plot).

- `balance_error`:

  `NA` on success, error message otherwise (rows that fail are not
  dropped).

## See also

[`N_balance`](https://mcroci.github.io/agrinutri/reference/N_balance.md),
[`P_balance`](https://mcroci.github.io/agrinutri/reference/P_balance.md),
[`K_balance`](https://mcroci.github.io/agrinutri/reference/K_balance.md),
[`plan_distribution`](https://mcroci.github.io/agrinutri/reference/plan_distribution.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
farm <- farm_balance(ex)
print(farm[, c("plot_id", "crop", "area_ha",
                "N_target", "MAS_cap", "N_total_kg")])

# Write the enriched layer for GIS use:
farm_balance(ex, output = "my_farm_with_Ntargets.geojson")
} # }
```
