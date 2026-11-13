#' Estimate end-of-cycle soil P2O5 content (ppm)
#'
#' Given the starting soil P2O5 (ppm), the crop P2O5 asportazione (kg/ha) and
#' the fertilization plan (from `plan_distribution`), returns the estimated
#' soil P2O5 at the end of the cycle in ppm P2O5 (useful as input for the
#' following year's calculation). Formula from Fert_Office v1.26 foglio
#' `Gri_P!C27`:
#' \preformatted{
#'   P2O5_end_ppm = P2O5_start_ppm + (P2O5_applied - P2O5_removed) / (soil_weight_30cm/1000) / P_immobilisation_factor
#' }
#' @param P2O5_start_ppm Initial Olsen P2O5 ppm (or pass P and `unit="P"`).
#' @param unit `"P"` or `"P2O5"`.
#' @param P2O5_applied kg P2O5/ha applied via fertilisers.
#' @param P2O5_removed kg P2O5/ha removed by crop (asportazione).
#' @param soil_group DPI texture grouping.
#' @param depth_cm Soil depth (default 30 cm).
#' @param texture_groups.table,p_availability_meta Lookups.
#' @return Numeric ppm P2O5 at end of cycle.
#' @examples
#' estimate_soil_P_end_of_cycle(P2O5_start_ppm = 15, P2O5_applied = 170,
#'                              P2O5_removed = 64, soil_group = "Medio impasto")
#' @export
estimate_soil_P_end_of_cycle <- function(P2O5_start_ppm,
                                         unit = c("P2O5", "P"),
                                         P2O5_applied,
                                         P2O5_removed,
                                         soil_group,
                                         depth_cm = 30,
                                         texture_groups.table = agrinutri_data_get("texture_groups.table"),
                                         p_availability_meta     = agrinutri_data_get("p_availability_meta")) {
  unit <- match.arg(unit)
  if (unit == "P") P2O5_start_ppm <- P2O5_start_ppm / as.numeric(p_availability_meta$P2O5_to_P[1])

  id_rag <- normalise_soil_group(soil_group)$id_rag
  rt_idx <- match(id_rag, texture_groups.table$ID_Rag)
  if (is.na(rt_idx)) stop(sprintf("ID_Rag %d not found in texture_groups.table.", id_rag))
  w_col <- .texture_group_weight_col(depth_cm, texture_groups.table)
  soil_weight_t_ha <- as.numeric(texture_groups.table[[w_col]][rt_idx])
  f_imm <- as.numeric(p_availability_meta$P_immobilisation_factor[1])

  delta_kg <- P2O5_applied - P2O5_removed
  delta_ppm <- delta_kg / (soil_weight_t_ha / 1000) / f_imm
  P2O5_start_ppm + delta_ppm
}

#' Estimate end-of-cycle soil K2O content (ppm)
#'
#' Simplified relationship:
#' \preformatted{
#'   K2O_end_ppm = K2O_start_ppm + (K2O_applied - K2O_removed - K2O_leaching) / (soil_weight_30cm/1000)
#' }
#' The lisciviazione (H) is taken from `K_leaching_by_clay(clay_pct)`.
#'
#' @param K2O_start_ppm Initial exchangeable K2O ppm.
#' @param K2O_applied,K2O_removed kg K2O/ha applied / removed.
#' @param clay_pct Clay percentage for H leaching.
#' @param soil_group DPI texture group.
#' @param depth_cm Default 30 cm.
#' @param texture_groups.table Lookup.
#' @return Numeric ppm K2O at end of cycle.
#' @examples
#' estimate_soil_K_end_of_cycle(K2O_start_ppm = 150, K2O_applied = 230,
#'                              K2O_removed = 119.4, clay_pct = 18.5,
#'                              soil_group = "Medio impasto")
#' @export
estimate_soil_K_end_of_cycle <- function(K2O_start_ppm,
                                         K2O_applied, K2O_removed,
                                         clay_pct,
                                         soil_group,
                                         depth_cm = 30,
                                         texture_groups.table = agrinutri_data_get("texture_groups.table")) {
  id_rag <- normalise_soil_group(soil_group)$id_rag
  rt_idx <- match(id_rag, texture_groups.table$ID_Rag)
  if (is.na(rt_idx)) stop(sprintf("ID_Rag %d not found in texture_groups.table.", id_rag))
  w_col <- .texture_group_weight_col(depth_cm, texture_groups.table)
  soil_weight_t_ha <- as.numeric(texture_groups.table[[w_col]][rt_idx])

  H <- K_leaching_by_clay(clay_pct)
  delta_kg <- K2O_applied - K2O_removed - H
  delta_ppm <- delta_kg / (soil_weight_t_ha / 1000)
  K2O_start_ppm + delta_ppm
}
