# Classify cation exchange capacity (CEC, meq/100 g) From the Fert_Office v1.26 K sheet: \< 10 low, 10-20 medium, \> 20 high, returned as the Italian labels `"bassa"`, `"media"`, `"alta"`.

Classify cation exchange capacity (CEC, meq/100 g) From the Fert_Office
v1.26 K sheet: \< 10 low, 10-20 medium, \> 20 high, returned as the
Italian labels `"bassa"`, `"media"`, `"alta"`.

## Usage

``` r
classify_CEC(csc_meq)
```

## Arguments

- csc_meq:

  Numeric meq/100 g.

## Value

List with `class`.

## Examples

``` r
classify_CEC(18)
#> $class
#> [1] "media"
#> 
#> $csc
#> [1] 18
#> 
```
