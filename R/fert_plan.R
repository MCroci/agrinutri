#' Fertilization distribution plan
#'
#' Builds the fertilisation distribution plan for a crop according to DPI
#' Emilia-Romagna 2026 (Fert_Office v1.26 distribution sheet). Combines:
#'
#' - Organic applications (one or more matrices from `organic_fertilizers.table`, with
#'   efficiency selected from `efficiency.table` by soil group, efficiency
#'   level of the distribution, sector of the matrix and N dose class; manures,
#'   composts and solid digestate (types 2-3) take a fixed 40% as in Fert_Office).
#' - Mineral / synthesis fertilisers (from `mineral_fertilizers.table` or user-specified
#'   triplets of N, P2O5, K2O titres).
#'
#' For each input row the function computes the "useful" contribution to the
#' crop for N (via efficiency), P2O5 and K2O (assumed 100%), and aggregates
#' the totals. If `n_balance`, `p_balance`, `k_balance` are provided the
#' function also checks the totals against the required doses and returns
#' alerts (`"OK"`, `"Eccesso"` for excess, `"Deficit"`).
#'
#' @param soil_group DPI texture group (see [normalise_soil_group()]).
#' @param n_balance,p_balance,k_balance Optional numeric requirements (kg/ha).
#' @param organic_rows A list of lists, each with:
#'   - `fertilizer`: name matching `organic_fertilizers.table$fertilizer` (or a custom
#'     name plus explicit titres)
#'   - `quantity_t_ha`: amount in t/ha (fresh matter)
#'   - `year`: application year (e.g. 2024, 2025)
#'   - `modality_epoch`: ID or label from `distribution_modalities.table`
#'   - `level` (optional): efficiency level of the distribution
#'     (low, medium, high), given as `"bassa"`, `"media"` or `"alta"`; in
#'     Fert_Office it depends on modality, epoch and crop cycle (cycle-modality
#'     sheet); default `"media"` (medium).
#'     The N dose class (< 125, 125-249, >= 250 kg N/ha) is computed from the
#'     quantity and selects the efficiency as in Fert_Office.
#'   - Optional `N_pct`, `P2O5_pct`, `K2O_pct`, `dry_matter_pct` override the table.
#' @param mineral_rows A list of lists, each with:
#'   - `fertilizer`: matching `mineral_fertilizers.table$fertilizer`, or custom
#'   - `quantity_q_ha`: quintals/ha (100 kg/ha)
#'   - `modality_epoch`: ID or label from `distribution_modalities.table`
#'   - `N`, `P2O5`, `K2O` titres (kg per q) if custom.
#' @param zvn Logical, if TRUE, enforce the ZVN 170 kg N/ha zootec cap.
#' @param organic_fertilizers.table,mineral_fertilizers.table,efficiency.table,distribution_modalities.table,texture_groups.table Defaults.
#'
#' @return A list with:
#'   - `rows`: per-application data frame (fertilizer, quantity, delivered N/P/K, efficiency, useful N/P/K)
#'   - `totals`: totals of useful N, P2O5, K2O delivered
#'   - `alerts`: if balances provided, `"OK"`/`"Eccesso"` (excess)/`"Deficit"` for each nutrient
#'   - `zvn_zoot_N`: total zootec N delivered (useful for ZVN check)
#' @export
plan_distribution <- function(soil_group,
                              n_balance = NULL, p_balance = NULL, k_balance = NULL,
                              organic_rows = list(),
                              mineral_rows = list(),
                              zvn = FALSE,
                              organic_fertilizers.table      = agrinutri_data_get("organic_fertilizers.table"),
                              mineral_fertilizers.table       = agrinutri_data_get("mineral_fertilizers.table"),
                              efficiency.table    = agrinutri_data_get("efficiency.table"),
                              distribution_modalities.table = agrinutri_data_get("distribution_modalities.table"),
                              texture_groups.table      = agrinutri_data_get("texture_groups.table")) {

  ID_Rag <- normalise_soil_group(soil_group)$id_rag

  level_map <- c("bassa" = 1, "media" = 2, "alta" = 3)

  lookup_mod <- function(mod) {
    if (is.numeric(mod)) return(as.integer(mod))
    idx <- match(mod, distribution_modalities.table$modality_epoch)
    if (is.na(idx)) return(NA_integer_)
    as.integer(distribution_modalities.table$ID_Mo[idx])
  }

  dose_level_from_kg <- function(kg_N) {
    # DPI: < 125 low, 125-249 medium, >= 250 high
    if (is.na(kg_N)) return("media")
    if (kg_N < 125) return("bassa")
    if (kg_N < 250) return("media")
    "alta"
  }

  rows <- list()

  # -------- Organic --------
  for (r in organic_rows) {
    fert <- r$fertilizer
    q    <- if (!is.null(r$quantity_t_ha)) r$quantity_t_ha else 0
    # Accept English (`fertilizer`) or Italian (`fertilizer_it`) matrix name,
    # case-insensitive.
    row_fo <- organic_fertilizers.table[
      tolower(organic_fertilizers.table$fertilizer) == tolower(fert), , drop = FALSE]
    if (nrow(row_fo) == 0 && "fertilizer_it" %in% names(organic_fertilizers.table)) {
      row_fo <- organic_fertilizers.table[
        tolower(organic_fertilizers.table$fertilizer_it) == tolower(fert), , drop = FALSE]
    }
    if (nrow(row_fo) == 0 && (is.null(r$N_pct) || is.null(r$P2O5_pct) || is.null(r$K2O_pct))) {
      warning(sprintf("Organic fertilizer '%s' not in organic_fertilizers.table and no titres given; skipping.", fert))
      next
    }
    N_pct   <- if (!is.null(r$N_pct))    r$N_pct    else as.numeric(row_fo$avg_N[1])
    P_pct   <- if (!is.null(r$P2O5_pct)) r$P2O5_pct else as.numeric(row_fo$avg_P2O5[1])
    K_pct   <- if (!is.null(r$K2O_pct))  r$K2O_pct  else as.numeric(row_fo$avg_K2O[1])
    dry_matter_pct  <- if (!is.null(r$dry_matter_pct))   r$dry_matter_pct   else as.numeric(row_fo$avg_dm[1])
    # Fert_Office: the efficiency table is keyed by the sector code (ID_Sett,
    # e.g. "bov"), not by the matrix type; "fan" in Fert_org is "fanghi" there.
    sector  <- if (nrow(row_fo) > 0) as.character(row_fo$sector_id[1]) else NA
    if (identical(sector, "fan")) sector <- "fanghi"
    type_id <- if (nrow(row_fo) > 0) suppressWarnings(as.integer(row_fo$type_id[1])) else NA_integer_
    zootec  <- if (nrow(row_fo) > 0) isTRUE(as.logical(row_fo$fully_zootec[1])) else FALSE

    # Kg delivered (fresh): titres are kg/t of fresh matter
    N_kg  <- q * N_pct
    P_kg  <- q * P_pct
    K_kg  <- q * K_pct

    # Fert_Office (foglio Efficienza, DGET on ID_Rag, ID_Liv, ID_Sett, ID_N_org):
    # - ID_Liv is the efficiency level of the distribution (modality, epoch and
    #   crop cycle, foglio Ciclo_Modalita): given by `level`, default "media";
    # - ID_N_org is the class of the organic N dose of the application
    #   (Mod_distribuz: < 125, 125-249, >= 250 kg N/ha).
    level <- if (!is.null(r$level)) r$level else "media"
    ID_Liv <- level_map[[level]]
    ID_N_org <- level_map[[dose_level_from_kg(N_kg)]]

    # Fert_Office foglio Apporti al terreno: type 1 (none) -> 0; types 2-3
    # (manures, composts, solid digestate) -> fixed 40%; others -> table.
    eff <- NA_real_
    if (!is.na(type_id) && type_id == 1) {
      eff <- 0
    } else if (!is.na(type_id) && type_id < 4) {
      eff <- 40
    } else if (!is.na(sector)) {
      e <- efficiency.table[
        efficiency.table$ID_Rag == ID_Rag &
          efficiency.table$ID_Liv == ID_Liv &
          efficiency.table$sector_id == sector &
          efficiency.table$ID_N_org == ID_N_org, , drop = FALSE]
      if (nrow(e) > 0) eff <- as.numeric(e$efficiency_pct[1])
    }
    if (is.na(eff)) {
      warning(sprintf("No efficiency found for organic fertilizer '%s' (sector %s); using 50%%.", fert, sector))
      eff <- 50
    }

    rows[[length(rows) + 1]] <- data.frame(
      source = "organic",
      fertilizer = fert,
      year = if (!is.null(r$year)) r$year else NA_integer_,
      modality_epoch = if (!is.null(r$modality_epoch)) r$modality_epoch else NA_character_,
      ID_Mo = lookup_mod(r$modality_epoch %||% NA_integer_),
      quantity_t_ha = q,
      N_kg = N_kg, P2O5_kg = P_kg, K2O_kg = K_kg,
      efficiency_pct = eff,
      N_useful   = N_kg * eff / 100,
      P2O5_useful = P_kg,
      K2O_useful = K_kg,
      zootec = zootec,
      stringsAsFactors = FALSE
    )
  }

  # -------- Mineral --------
  for (r in mineral_rows) {
    conc <- r$fertilizer
    q    <- if (!is.null(r$quantity_q_ha)) r$quantity_q_ha else 0
    row_c <- mineral_fertilizers.table[
      tolower(mineral_fertilizers.table$fertilizer) == tolower(conc), , drop = FALSE]
    if (nrow(row_c) == 0 && "fertilizer_it" %in% names(mineral_fertilizers.table)) {
      row_c <- mineral_fertilizers.table[
        tolower(mineral_fertilizers.table$fertilizer_it) == tolower(conc), , drop = FALSE]
    }
    if (nrow(row_c) == 0 && (is.null(r$N) || is.null(r$P2O5) || is.null(r$K2O))) {
      warning(sprintf("Mineral '%s' not found and no titres given; skipping.", conc))
      next
    }
    N_t <- if (!is.null(r$N))    r$N    else as.numeric(row_c$N[1])
    P_t <- if (!is.null(r$P2O5)) r$P2O5 else as.numeric(row_c$P2O5[1])
    K_t <- if (!is.null(r$K2O))  r$K2O  else as.numeric(row_c$K2O[1])

    # Titres are kg/q = %: delivered kg/ha = q/ha * %
    N_kg <- q * N_t
    P_kg <- q * P_t
    K_kg <- q * K_t

    rows[[length(rows) + 1]] <- data.frame(
      source = "mineral",
      fertilizer = conc,
      year = if (!is.null(r$year)) r$year else NA_integer_,
      modality_epoch = if (!is.null(r$modality_epoch)) r$modality_epoch else NA_character_,
      ID_Mo = lookup_mod(r$modality_epoch %||% NA_integer_),
      quantity_t_ha = q / 10,   # q/ha to t/ha for reporting consistency
      N_kg = N_kg, P2O5_kg = P_kg, K2O_kg = K_kg,
      efficiency_pct = 100,
      N_useful = N_kg, P2O5_useful = P_kg, K2O_useful = K_kg,
      zootec = FALSE,
      stringsAsFactors = FALSE
    )
  }

  rows_df <- if (length(rows) > 0) do.call(rbind, rows) else
    data.frame(source = character(), fertilizer = character(),
               year = integer(), modality_epoch = character(), ID_Mo = integer(),
               quantity_t_ha = numeric(), N_kg = numeric(),
               P2O5_kg = numeric(), K2O_kg = numeric(),
               efficiency_pct = numeric(),
               N_useful = numeric(), P2O5_useful = numeric(), K2O_useful = numeric(),
               zootec = logical(), stringsAsFactors = FALSE)

  tot_N <- sum(rows_df$N_useful, na.rm = TRUE)
  tot_P <- sum(rows_df$P2O5_useful, na.rm = TRUE)
  tot_K <- sum(rows_df$K2O_useful, na.rm = TRUE)
  tot_zoot_N <- sum(rows_df$N_kg[rows_df$zootec], na.rm = TRUE)

  alert <- function(total, target) {
    if (is.null(target) || is.na(target)) return(NA_character_)
    if (total >  target * 1.05) return("Eccesso")
    if (total <  target * 0.95) return("Deficit")
    "OK"
  }

  alerts <- list(
    N = alert(tot_N, n_balance),
    P2O5 = alert(tot_P, p_balance),
    K2O  = alert(tot_K, k_balance)
  )

  zvn_warn <- NA
  if (isTRUE(zvn)) {
    zvn_warn <- if (tot_zoot_N > 170) "Eccesso ZVN (>170 kg N/ha/anno da effluenti)" else "OK ZVN"
  }

  list(
    rows = rows_df,
    totals = c(N_useful = tot_N, P2O5_useful = tot_P, K2O_useful = tot_K),
    targets = c(N = n_balance %||% NA_real_, P2O5 = p_balance %||% NA_real_, K2O = k_balance %||% NA_real_),
    alerts  = alerts,
    zvn_zoot_N = tot_zoot_N,
    zvn_alert  = zvn_warn
  )
}

