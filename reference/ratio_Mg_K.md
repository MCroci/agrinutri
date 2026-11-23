# Mg/K ratio assessment (Fert_Office K sheet) 0-0.1 low; 0.1-2.1 balanced; 2.1-5.1 high; \>5.1 very high, returned as the Italian labels `"basso"`, `"equilibrato"`, `"alto"`, `"molto alto"`.

Mg/K ratio assessment (Fert_Office K sheet) 0-0.1 low; 0.1-2.1 balanced;
2.1-5.1 high; \>5.1 very high, returned as the Italian labels `"basso"`,
`"equilibrato"`, `"alto"`, `"molto alto"`.

## Usage

``` r
ratio_Mg_K(mg_ppm, k_ppm)
```

## Arguments

- mg_ppm, k_ppm:

  Magnesium and potassium ppm.

## Value

List with `ratio` and `class`.

## Examples

``` r
ratio_Mg_K(mg_ppm = 121.5, k_ppm = 150)
#> $ratio
#> [1] 2.606667
#> 
#> $class
#> [1] "alto"
#> 
```
