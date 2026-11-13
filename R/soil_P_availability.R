#' Classify Olsen phosphorus availability
#'
#' Classifies soil phosphorus availability using the Olsen method, following
#' DPI Emilia-Romagna 2026 (Fert_Office v1.26 foglio `Gri_P`). The input may be
#' expressed either as elemental P or as P2O5 equivalent; the conversion
#' factor is P2O5 = P / 0.436681.
#'
#' @param value Numeric. Olsen phosphorus value in ppm.
#' @param unit Either `"P"` or `"P2O5"` (default `"P"`).
#' @param p_availability.table Lookup table, default `NFert::p_availability.table`.
#' @param p_availability_meta Conversion metadata, default `NFert::p_availability_meta`.
#'
#' @return A list with:
#'   - `value_ppm_P`, `value_ppm_P2O5`: input converted to both units.
#'   - `ID_Gri_P`: class id (1 molto bassa ... 5 molto elevata).
#'   - `rating`: human-readable class.
#'   - `soil_class`: DPI "Classe dotaz." (`molto scarso`, `scarso`, `normale`, `molto alto`).
#'   - `strategy`: one of `"Arricchimento"`, `"Mantenimento"`, `"Riduzione"`.
#'
#' @examples
#' classify_P_olsen(value = 15, unit = "P2O5")
#' classify_P_olsen(value = 6.55, unit = "P")
#' @export
classify_P_olsen <- function(value,
                             unit = c("P", "P2O5"),
                             p_availability.table = nfert_data_get("p_availability.table"),
                             p_availability_meta  = nfert_data_get("p_availability_meta")) {
  unit <- match.arg(unit)
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value < 0) {
    stop("`value` must be a single non-negative numeric.")
  }

  if (unit == "P") {
    ppm_P    <- value
    ppm_P2O5 <- value / as.numeric(p_availability_meta$P2O5_to_P[1])
  } else {
    ppm_P2O5 <- value
    ppm_P    <- value * as.numeric(p_availability_meta$P2O5_to_P[1])
  }

  # Match class on the P (ppm) lower thresholds, as Fert_Office does
  # (foglio Gri_P: VLOOKUP of the value converted to P)
  t <- p_availability.table[order(p_availability.table$min_P_ppm), , drop = FALSE]
  i <- findInterval(ppm_P, as.numeric(t$min_P_ppm))
  id <- NA_integer_
  rating <- NA_character_
  soil_class <- NA_character_
  if (i >= 1L) {
    id <- as.integer(t$ID_Gri_P[i])
    rating <- as.character(t$rating[i])
    soil_class <- as.character(t$`class`[i])
  }

  # DPI-style strategy: scarsa (1,2) = Arricchimento; normale (3,4) = Mantenimento; molto elevata (5) = Riduzione
  strategy <- if (is.na(id)) NA_character_ else
    if (id %in% 1:2) "Arricchimento" else
      if (id %in% 3:4) "Mantenimento" else "Riduzione"

  list(
    value_ppm_P    = ppm_P,
    value_ppm_P2O5 = ppm_P2O5,
    ID_Gri_P       = id,
    rating         = rating,
    soil_class     = soil_class,
    strategy       = strategy
  )
}

#' Compute soil P availability terms (B1 / A mantenimento / B2) for the P balance
#'
#' Implements the DPI 2026 Allegato 2 logic coded in Fert_Office v1.26 foglio
#' `Gri_P`: depending on the phosphorus availability class (`Arricchimento`,
#' `Mantenimento`, `Riduzione`) returns the contribution that goes onto the
#' NECESSITA' side (B1, A anticipations) or onto the DISPONIBILITA' side (B2).
#'
#' In "Riduzione" (very high P) the crop removal A is kept and the excess over
#' the upper bound of the normal range (68.7 ppm P2O5) times the soil weight is
#' returned as B2, to be subtracted.
#'
#' The B1 arricchimento term equals the distance of the analytical value from
#' the lower bound of the normal class (22.9 ppm P2O5), multiplied by the soil
#' weight at 30 cm (t/ha) and by the P immobilisation factor. As in
#' Fert_Office (foglio `Gri_P`, cell L10) the factor is the texture-group base
#' value (`texture_groups.table$P_immobilisation_factor`: 1.2 sandy, 1.3 loamy,
#' 1.4 clay) plus 0.02 times the total carbonate content (percent). When
#' `total_carbonate` is not supplied, the legacy constant
#' `p_availability_meta$P_immobilisation_factor` (1.6, i.e. a loamy soil with
#' 15 percent total carbonate) is used.
#'
#' @param olsen_value Numeric, Olsen P or P2O5 ppm.
#' @param unit `"P"` or `"P2O5"` (default `"P"`).
#' @param soil_group One of `"Sabbiosi"`, `"Medio impasto"`, `"Argillosi e limosi"`
#'   (must match `texture_groups.table$group`).
#' @param A_demand_P2O5 Crop P2O5 demand (kg/ha) (from `calc_crop_P_demand()`).
#' @param depth_cm Soil depth used for weight (default 30 cm).
#' @param total_carbonate Total carbonate (CaCO3, percent) from the soil test.
#'   `NULL` (default) uses the legacy constant immobilisation factor.
#' @param p_availability.table,p_availability_meta,texture_groups.table Lookup tables.
#'
#' @return A list with `strategy`, `B1` (arricchimento kg/ha), `A_mantenimento`,
#'   `B2` (riduzione kg/ha), and diagnostic `soil_weight_t_ha`, `P_immobilisation_factor`.
#' @examples
#' soil_P_availability(olsen_value = 15, unit = "P2O5",
#'                     soil_group = "Medio impasto", A_demand_P2O5 = 63.6)
#' @export
soil_P_availability <- function(olsen_value,
                                unit = c("P", "P2O5"),
                                soil_group,
                                A_demand_P2O5,
                                depth_cm = 30,
                                total_carbonate = NULL,
                                p_availability.table = nfert_data_get("p_availability.table"),
                                p_availability_meta  = nfert_data_get("p_availability_meta"),
                                texture_groups.table = nfert_data_get("texture_groups.table")) {
  unit <- match.arg(unit)
  cls <- classify_P_olsen(olsen_value, unit = unit,
                          p_availability.table = p_availability.table, p_availability_meta = p_availability_meta)

  # Universal join on ID_Rag (works regardless of the textual convention)
  id_rag <- normalise_soil_group(soil_group)$id_rag
  rt_idx <- match(id_rag, texture_groups.table$ID_Rag)
  if (is.na(rt_idx)) {
    stop(sprintf("ID_Rag %d not found in texture_groups.table.", id_rag))
  }
  weight_col <- .texture_group_weight_col(depth_cm, texture_groups.table)
  soil_weight_t_ha <- as.numeric(texture_groups.table[[weight_col]][rt_idx])
  if (is.null(total_carbonate)) {
    f_imm <- as.numeric(p_availability_meta$P_immobilisation_factor[1])
  } else {
    if (!is.numeric(total_carbonate) || length(total_carbonate) != 1L ||
        is.na(total_carbonate) || total_carbonate < 0 || total_carbonate > 100)
      stop("`total_carbonate` must be a single number between 0 and 100 (percent CaCO3).")
    f_imm <- as.numeric(texture_groups.table$P_immobilisation_factor[rt_idx]) +
      0.02 * total_carbonate
  }

  # Normal range ("normale" = media + elevata): 22.9 - 68.7 ppm P2O5 (DPI 2026)
  normal <- p_availability.table$`class` == "normale"
  lower_normal <- min(p_availability.table$min_P2O5_ppm[normal], na.rm = TRUE)
  upper_normal <- max(p_availability.table$max_P2O5_ppm[normal], na.rm = TRUE)

  # Fert_Office works on the P2O5 value obtained back from P (Gri_P!M8)
  p2o5 <- cls$value_ppm_P * 2.29

  B1 <- 0
  A_mant <- A_demand_P2O5
  B2 <- 0
  if (!is.na(cls$strategy) && cls$strategy == "Arricchimento") {
    # Enrichment up to the lower bound of the normal range (Gri_P!I14)
    B1 <- max(0, lower_normal - p2o5) * soil_weight_t_ha / 1000 * f_imm
  } else if (!is.na(cls$strategy) && cls$strategy == "Riduzione") {
    # Reduction: the excess over the normal range is subtracted (Gri_P!I16)
    B2 <- max(0, p2o5 - upper_normal) * soil_weight_t_ha / 1000
  }

  list(
    strategy = cls$strategy,
    ID_Gri_P = cls$ID_Gri_P,
    rating   = cls$rating,
    B1 = B1,
    A_mantenimento = A_mant,
    B2 = B2,
    soil_weight_t_ha = soil_weight_t_ha,
    P_immobilisation_factor = f_imm
  )
}
