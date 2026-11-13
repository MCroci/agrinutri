#' Classify exchangeable potassium availability
#'
#' Classifies K (or K2O) availability by soil texture grouping, following DPI
#' Emilia-Romagna 2026 (Fert_Office v1.26 foglio `Gri_K`). The threshold ranges
#' depend on the DPI texture group (`Sabbiosi`, `Medio impasto`,
#' `Argillosi e limosi`).
#'
#' @param value Numeric K or K2O value in ppm.
#' @param unit `"K"` (default) or `"K2O"`. Conversion K2O = K / 0.83333.
#' @param soil_group Texture grouping (must match `k_availability.table$group`).
#' @param k_availability.table Lookup table, default `NFert::k_availability.table`.
#'
#' @return A list with `value_ppm_K`, `value_ppm_K2O`, `ID_Gri_K`, `rating`,
#'   `strategy` (`Arricchimento` / `Mantenimento` / `Riduzione`).
#' @examples
#' classify_K(value = 150, unit = "K2O", soil_group = "Medio impasto")
#' @export
classify_K <- function(value,
                       unit = c("K", "K2O"),
                       soil_group,
                       k_availability.table = nfert_data_get("k_availability.table")) {
  unit <- match.arg(unit)
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value < 0) {
    stop("`value` must be a single non-negative numeric.")
  }

  # 1 K2O = K / 0.83333 (0.83333 = 94.2/113.0 molecular ratio K/K2O)
  if (unit == "K") {
    ppm_K    <- value
    ppm_K2O  <- value / 0.83333
  } else {
    ppm_K2O  <- value
    ppm_K    <- value * 0.83333
  }

  # Normalise to canonical Italian plural form used in k_availability.table
  sg <- normalise_soil_group(soil_group)$en
  t <- k_availability.table[k_availability.table$group == sg, , drop = FALSE]
  if (nrow(t) == 0) {
    stop(sprintf("soil_group '%s' (canonical: '%s') not found in k_availability.table.",
                 soil_group, sg))
  }

  # Class from the K (ppm) lower thresholds, as Fert_Office does
  # (foglio Gri_K: VLOOKUP of the value converted to K)
  t <- t[order(t$min_K_ppm), , drop = FALSE]
  i <- findInterval(ppm_K, as.numeric(t$min_K_ppm))
  id <- NA_integer_
  rating <- NA_character_
  if (i >= 1L) {
    id <- as.integer(t$ID_Dot_K[i])   # 1 molto bassa .. 4 elevata
    rating <- as.character(t$rating[i])
  }

  # Strategy: 1-2 (molto bassa / bassa) -> Arricchimento, 3 (media) -> Mantenimento,
  # 4 (elevata) -> Riduzione (molto elevata not distinguished in DPI K table)
  strategy <- if (is.na(id)) NA_character_ else
    if (id %in% 1:2) "Arricchimento" else
      if (id == 3) "Mantenimento" else "Riduzione"

  list(value_ppm_K = ppm_K, value_ppm_K2O = ppm_K2O,
       ID_Gri_K = id, rating = rating, strategy = strategy)
}

#' K leaching by clay content
#'
#' Step function from Fert_Office v1.26 foglio Gri_K (righe 23-28):
#' clay < 5.1% -> 60 kg K2O/ha; 5.1-15.1 -> 30; 15.1-25.1 -> 20; >= 25.1 -> 10.
#' @param clay_pct Clay percentage.
#' @return Numeric, leachable K2O in kg/ha.
#' @examples
#' K_leaching_by_clay(18.5)
#' @export
K_leaching_by_clay <- function(clay_pct) {
  if (!is.numeric(clay_pct) || length(clay_pct) != 1 || is.na(clay_pct)) {
    stop("`clay_pct` must be a single non-negative numeric.")
  }
  if (clay_pct <  5.1)  return(60)
  if (clay_pct < 15.1)  return(30)
  if (clay_pct < 25.1)  return(20)
  return(10)
}

#' Compute soil K availability terms for the K balance
#'
#' @param k_value,unit,soil_group K analytical value and DPI texture group.
#' @param A_demand_K2O Crop K2O demand (kg/ha) from `calc_crop_K_demand()`.
#' @param clay_pct Clay percentage, used to compute leaching `H`.
#' @param include_leaching Logical, add K leaching to mantenimento term. Default TRUE.
#' @param k_availability.table,texture_groups.table Lookup tables.
#'
#' As in Fert_Office v1.26 (foglio `Gri_K`), with K2O the analytical value and
#' W the soil weight of the 30 cm layer (t/ha):
#' \itemize{
#'   \item Arricchimento (low / very low): B1 = (lower bound of the "media"
#'     class - K2O) x W / 1000 x (1 + 0.018 x clay);
#'   \item Mantenimento: A + H;
#'   \item Riduzione (high): B2 = (K2O - upper bound of the "media" class) x
#'     W / 1000, subtracted from A + H.
#' }
#'
#' @return A list with `strategy`, `ID_Gri_K`, `B1`, `A_mantenimento` (asportazione + H),
#'   `B2`, `H` (leaching).
#' @examples
#' soil_K_availability(k_value = 150, unit = "K2O",
#'                     soil_group = "Medio impasto",
#'                     A_demand_K2O = 119.4, clay_pct = 18.5)
#' @export
soil_K_availability <- function(k_value, unit = c("K","K2O"),
                                soil_group, A_demand_K2O,
                                clay_pct,
                                include_leaching = TRUE,
                                k_availability.table = nfert_data_get("k_availability.table"),
                                texture_groups.table = nfert_data_get("texture_groups.table")) {
  unit <- match.arg(unit)
  cls <- classify_K(k_value, unit = unit, soil_group = soil_group,
                    k_availability.table = k_availability.table)
  H <- if (isTRUE(include_leaching)) K_leaching_by_clay(clay_pct) else 0

  sg <- normalise_soil_group(soil_group)
  W <- as.numeric(texture_groups.table$soil_weight_30cm[
    match(sg$id_rag, texture_groups.table$ID_Rag)])
  media <- k_availability.table[k_availability.table$group == sg$en &
                                  k_availability.table$ID_Dot_K == 3L, , drop = FALSE]
  k2o <- cls$value_ppm_K * 1.2          # Gri_K!O16: K back to K2O

  B1 <- 0; A_mant <- A_demand_K2O + H; B2 <- 0
  if (!is.na(cls$strategy) && cls$strategy == "Arricchimento") {
    B1 <- max(0, media$min_K2O_ppm[1] - k2o) * W / 1000 * (1 + 0.018 * clay_pct)
  } else if (!is.na(cls$strategy) && cls$strategy == "Riduzione") {
    B2 <- max(0, k2o - media$max_K2O_ppm[1]) * W / 1000
  }

  list(strategy = cls$strategy, ID_Gri_K = cls$ID_Gri_K, rating = cls$rating,
       B1 = B1, A_mantenimento = A_mant, B2 = B2, H = H)
}
