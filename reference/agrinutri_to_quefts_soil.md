# Translate agrinutri inputs into QUEFTS soil parameters

Builds the soil parameter list expected by
[`Rquefts::quefts()`](https://rdrr.io/pkg/Rquefts/man/quefts.html) from
the soil logic already reflected in
[`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md).
The conversion is deterministic and does not require additional
measurements.

## Usage

``` r
agrinutri_to_quefts_soil(
  N_supply,
  P_supply = 10,
  K_supply = 60,
  N_recovery = 0.55,
  P_recovery = 0.1,
  K_recovery = 0.5
)
```

## Arguments

- N_supply:

  Numeric. Plant-available N supply (kg N/ha) over the season. Typically
  the `B` component returned by
  [`N_balance()`](https://mcroci.github.io/agrinutri/reference/N_balance.md)
  (sum of b1 readily available N and b2 SOM mineralisation).

- P_supply:

  Numeric. Plant-available P supply (kg P/ha). If unknown, defaults to
  10 (representative for Italian arable soils with Olsen P in the 15–25
  mg/kg range).

- K_supply:

  Numeric. Plant-available K supply (kg K/ha). Default 60.

- N_recovery:

  Numeric. Apparent N recovery efficiency (fraction). Default 0.55,
  typical for cereals on medium-textured soils.

- P_recovery:

  Numeric. Apparent P recovery efficiency. Default 0.10.

- K_recovery:

  Numeric. Apparent K recovery efficiency. Default 0.50.

## Value

A named list ready to be passed to
[`Rquefts::quefts()`](https://rdrr.io/pkg/Rquefts/man/quefts.html) as
the `soil` argument.

## Details

QUEFTS uses native nutrient supplies and recovery fractions of applied
fertiliser to build a per-cycle balance. Default recovery values follow
QUEFTS applications for European cereal systems (Janssen et al., 1990;
Sattari et al., 2014).

The `UptakeAdjust` matrix matches the default in
[`Rquefts::quefts_soil()`](https://rdrr.io/pkg/Rquefts/man/quefts_soil.html).

## References

Janssen, B.H. et al. (1990). Geoderma 46, 299-318. Sattari, S.Z. et al.
(2014). Eur. J. Agron. 60, 79-90.
