# Critical nitrogen curve parameters (Lemaire & Gastal 1997 framework)

Returns the coefficients `a` and `b` of the critical nitrogen dilution
curve \\N_c = a \cdot W^{-b}\\ (N_c in % DM, W in t DM / ha) for the
main Italian arable crops, plus the minimum biomass `W_min` below which
the curve is held constant at \\N_c = a \cdot W\_{min}^{-b}\\ (standard
convention: the curve is only valid for a closed canopy, i.e. W \>=
~1-1.55 t DM/ha depending on the crop).

## Usage

``` r
critical_N_curve(crop)
```

## Arguments

- crop:

  Character. Crop identifier (see list above). Case-insensitive; Italian
  synonyms (`"frumento"`, `"mais"`, `"colza"`, `"riso"`, `"girasole"`,
  `"sorgo"`) are accepted.

## Value

A list with numeric elements `a`, `b`, `W_min` and `reference`
(character).

## Details

Published references:

- **wheat (C3 cereals)**: a = 5.35, b = 0.44, W_min = 1.55 (Justes et
  al. 1994)

- **durum wheat**: same as wheat (Prey & Schmidhalter 2019)

- **maize (C4)**: a = 3.40, b = 0.37, W_min = 1.00 (Plenet & Lemaire
  1999)

- **rice**: a = 5.18, b = 0.52, W_min = 1.00 (Sheehy et al. 1998)

- **rapeseed**: a = 4.48, b = 0.25, W_min = 1.55 (Colnenne et al. 1998)

- **grass (ryegrass, fescue, Lolium)**: a = 4.80, b = 0.32, W_min = 1.00
  (Duru et al. 1997)

- **sorghum (C4)**: a = 3.90, b = 0.39, W_min = 1.00 (van Oosterom et
  al. 2010)

- **sunflower**: a = 4.53, b = 0.42, W_min = 1.00 (Debaeke et al. 2012)

## References

Lemaire, G. & Gastal, F. (1997). N uptake and distribution in plant
canopies. In: Lemaire G. (ed.) Diagnosis of the Nitrogen Status in
Crops. Springer, Berlin.

Justes, E. et al. (1994). Determination of a critical nitrogen dilution
curve for winter wheat crops. Ann. Bot. 74, 397-407.

Plenet, D. & Lemaire, G. (1999). Relationships between dynamics of
nitrogen uptake and dry matter accumulation in maize crops.
Determination of critical N concentration. Plant Soil 216, 65-82.
