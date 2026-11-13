# Nitrogen from previous crop residues

Estimates the amount of nitrogen (N) available from residues of a
previous crop.

## Usage

``` r
nitrogen_from_previous_crop_residues(
  previous_crop = "Winter cereals straw removal",
  e.table = agrinutri_data_get("e.table")
)
```

## Arguments

- previous_crop:

  The name of the previous crop. This must match a value in the
  `previous_crop` column of the `e.table`.

- e.table:

  A data frame containing the nitrogen values (in kg/ha) for different
  previous crops. It should have at least two columns: `previous_crop`
  (character) and `N` (numeric). The default is
  [`agrinutri::e.table`](https://mcroci.github.io/agrinutri/reference/agrinutri-data.md).

## Value

The estimated amount of nitrogen (N) in kg/ha available from the
previous crop residues.

## Details

- If the value in the `e.table` is negative, the function returns 0 (as
  negative N contribution from residues is not meaningful).

- If there is no matching entry for `previous_crop` in the `e.table`,
  the function returns `NA` to indicate missing data.

## Examples

``` r
E <- nitrogen_from_previous_crop_residues(previous_crop = "Winter cereals straw removal")
print(E)
#> [1] -10
```
