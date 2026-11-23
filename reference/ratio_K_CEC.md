# K/CEC ratio assessment (Fert_Office K sheet) \<0.1% low; 0.1-2.1 optimal; 2.1-5.1 high (percentage of CEC), returned as the Italian labels `"basso"`, `"ottimale"`, `"alto"`.

K/CEC ratio assessment (Fert_Office K sheet) \<0.1% low; 0.1-2.1
optimal; 2.1-5.1 high (percentage of CEC), returned as the Italian
labels `"basso"`, `"ottimale"`, `"alto"`.

## Usage

``` r
ratio_K_CEC(k_meq_per_100g, csc_meq)
```

## Arguments

- k_meq_per_100g:

  K in meq/100g.

- csc_meq:

  CEC in meq/100g.

## Value

List with `pct` and `class`.

## Examples

``` r
ratio_K_CEC(k_meq_per_100g = 0.38, csc_meq = 18)
#> $pct
#> [1] 2.111111
#> 
#> $class
#> [1] "alto"
#> 
```
