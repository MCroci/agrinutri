# K leaching by clay content

Step function from the Fert_Office v1.26 K sheet (rows 23-28): clay \<
5.1% -\> 60 kg K2O/ha; 5.1-15.1 -\> 30; 15.1-25.1 -\> 20; \>= 25.1 -\>
10.

## Usage

``` r
K_leaching_by_clay(clay_pct)
```

## Arguments

- clay_pct:

  Clay percentage.

## Value

Numeric, leachable K2O in kg/ha.

## Examples

``` r
K_leaching_by_clay(18.5)
#> [1] 20
```
