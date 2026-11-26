# Replace the coefficient tables of the balance

Every coefficient of the nitrogen, phosphorus and potassium balances is
read from a bundled table (for example
[uptake_table](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md),
[mas.table](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md),
[cb.table](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md),
[e.table](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md)).
`agrinutri_tables()` makes the balance use other tables for the rest of
the session (or until it is called again), without editing the package:
start from the bundled table, change its values, and pass it by name.
The replacement must keep the columns of the bundled table.

## Usage

``` r
agrinutri_tables(...)
```

## Arguments

- ...:

  Named data frames, each replacing the bundled table of the same name,
  e.g. `uptake_table = my_uptake`. Call with no arguments to go back to
  the bundled tables.

## Value

The previous replacement list, invisibly (pass it to
`options(agrinutri.tables = ...)` to restore it).

## Examples

``` r
my_uptake <- uptake_table
i <- my_uptake$crop == "Grain maize 500-700 (grain)"
my_uptake$N[i] <- my_uptake$N[i] * 1.1            # 10 percent higher unit uptake
old <- agrinutri_tables(uptake_table = my_uptake)
calc_crop_N_demand(10, "Grain maize 500-700 (grain)")$N_requirement   # 10 percent higher
#> [1] 249.7
agrinutri_tables()                                  # bundled tables again
```
