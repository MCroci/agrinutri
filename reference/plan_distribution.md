# Fertilization distribution plan

Builds the fertilisation distribution plan for a crop according to DPI
Emilia-Romagna 2026 (Fert_Office v1.26 foglio `Distribuz`). Combines:

## Usage

``` r
plan_distribution(
  soil_group,
  n_balance = NULL,
  p_balance = NULL,
  k_balance = NULL,
  organic_rows = list(),
  mineral_rows = list(),
  zvn = FALSE,
  organic_fertilizers.table = agrinutri_data_get("organic_fertilizers.table"),
  mineral_fertilizers.table = agrinutri_data_get("mineral_fertilizers.table"),
  efficiency.table = agrinutri_data_get("efficiency.table"),
  distribution_modalities.table = agrinutri_data_get("distribution_modalities.table"),
  texture_groups.table = agrinutri_data_get("texture_groups.table")
)
```

## Arguments

- soil_group:

  Italian DPI texture group.

- n_balance, p_balance, k_balance:

  Optional numeric requirements (kg/ha).

- organic_rows:

  A list of lists, each with:

  - `fertilizer`: name matching `organic_fertilizers.table$fertilizer`
    (or a custom name plus explicit titres)

  - `quantity_t_ha`: amount in t/ha (fresh matter)

  - `year`: application year (e.g. 2024, 2025)

  - `modality_epoch`: ID or label from `distribution_modalities.table`

  - `level` (optional): efficiency level `"bassa"/"media"/"alta"` if you
    want to override the default selection.

  - Optional `N_pct`, `P2O5_pct`, `K2O_pct`, `dry_matter_pct` override
    the table.

- mineral_rows:

  A list of lists, each with:

  - `fertilizer`: matching `mineral_fertilizers.table$fertilizer`, or
    custom

  - `quantity_q_ha`: quintals/ha (100 kg/ha)

  - `modality_epoch`: ID or label from `distribution_modalities.table`

  - `N`, `P2O5`, `K2O` titres (kg per q) if custom.

- zvn:

  Logical, if TRUE, enforce the ZVN 170 kg N/ha zootec cap.

- organic_fertilizers.table, mineral_fertilizers.table,
  efficiency.table, distribution_modalities.table, texture_groups.table:

  Defaults.

## Value

A list with:

- `rows`: per-application data frame (fertilizer, quantity, delivered
  N/P/K, efficiency, useful N/P/K)

- `totals`: totals of useful N, P2O5, K2O delivered

- `alerts`: if balances provided, OK/Eccesso/Deficit for each nutrient

- `zvn_zoot_N`: total zootec N delivered (useful for ZVN check)

## Details

- Organic applications (one or more matrices from
  `organic_fertilizers.table`, with efficiency selected from
  `efficiency.table` by soil group, dose level, and sector of matrix).

- Mineral / synthesis fertilisers (from `mineral_fertilizers.table` or
  user-specified triplets of N, P2O5, K2O titres).

For each input row the function computes the "useful" contribution to
the crop for N (via efficiency), P2O5 and K2O (assumed 100%), and
aggregates the totals. If `n_balance`, `p_balance`, `k_balance` are
provided the function also checks the totals against the required doses
and returns alerts (`OK` / `Eccesso` / `Deficit`).
