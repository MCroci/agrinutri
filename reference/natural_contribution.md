# Natural Nitrogen Contribution

Calculates the natural nitrogen (N) contribution from atmospheric
deposition based on location and crop category.

## Usage

``` r
natural_contribution(
  location = "Plain adjacent to urbanized areas",
  ccp = "Autumn-winter crop <150 days",
  g.table = agrinutri_data_get("g.table"),
  coef_time = agrinutri_data_get("coef_time")
)
```

## Arguments

- location:

  The location or type of area (e.g., "Plain adjacent to urbanized
  areas"). Must match a value in the `location` column of the `g.table`.

- ccp:

  Crop category and planting period (e.g., "Autumn-winter crop \<150
  days"). Must match a value in the `ccp` column of the `coef_time`
  table.

- g.table:

  A data frame containing annual nitrogen deposition rates for different
  locations. It should have at least two columns: `location` (character)
  and `annual_deposition` (numeric). Defaults to
  [`agrinutri::g.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

- coef_time:

  A data frame containing adjustment factors (C_tempo) based on crop
  category and planting period. It should have at least two columns:
  `ccp` (character) and `C_tempo` (numeric). Defaults to
  [`agrinutri::coef_time`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

The estimated natural nitrogen contribution in kg/ha, or `NA` if input
values are not found in the respective tables.

## Details

The function calculates the natural nitrogen contribution using the
following formula:

    G = annual_deposition * C_tempo

where:

- `G` is the natural nitrogen contribution (kg/ha)

- `annual_deposition` is the annual nitrogen deposition rate for the
  specified `location` (kg/ha/year)

- `C_tempo` is the adjustment factor based on the `ccp`

## Examples

``` r
natural_contribution(
  location = "Plain adjacent to urbanized areas",
  ccp = "Autumn-winter crop <150 days"
)
#> [1] 10
```
