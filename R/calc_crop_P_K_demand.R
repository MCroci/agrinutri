#' Crop P2O5 demand
#'
#' Returns the crop P2O5 requirement (kg/ha) from `uptake_table` (column `P2O5`)
#' multiplied by the expected yield.
#'
#' @param expected_yield_tons_ha Expected yield (t/ha).
#' @param crop Crop name (must match `uptake_table$crop`).
#' @param uptake_table Lookup table (default `agrinutri::uptake_table`).
#' @return A list: `P2O5_requirement` (kg/ha), `unit_coef` (kg P2O5 / t yield), `crop`.
#' @export
#' @examples
#' calc_crop_P_demand(expected_yield_tons_ha = 6,
#'                    crop = "Grano duro (pianta intera)")
calc_crop_P_demand <- function(expected_yield_tons_ha,
                               crop,
                               uptake_table = agrinutri_data_get("uptake_table")) {
  if (!is.numeric(expected_yield_tons_ha) || expected_yield_tons_ha < 0) {
    stop("`expected_yield_tons_ha` must be non-negative numeric.")
  }
  crop <- resolve_crop(crop, table = uptake_table)
  idx <- which(uptake_table$crop == crop)
  if (length(idx) == 0) stop(sprintf("Crop '%s' not found in uptake_table.", crop))
  idx <- idx[1]
  coef <- suppressWarnings(as.numeric(uptake_table$P2O5[idx]))
  if (is.na(coef)) {
    warning(sprintf("No P2O5 coefficient available for crop '%s'.", crop))
    return(list(P2O5_requirement = NA_real_, unit_coef = NA_real_, crop = crop))
  }
  # Fert_Office A coefficients are expressed per quintale (0.1 t); multiply by 10.
  list(P2O5_requirement = expected_yield_tons_ha * coef * 10,
       unit_coef = coef, crop = crop, units = "kg P2O5/ha")
}

#' Crop K2O demand
#'
#' @param expected_yield_tons_ha,crop See `calc_crop_P_demand`.
#' @param uptake_table Lookup table.
#' @return List with `K2O_requirement`, `unit_coef`.
#' @export
#' @examples
#' calc_crop_K_demand(expected_yield_tons_ha = 6,
#'                    crop = "Grano duro (pianta intera)")
calc_crop_K_demand <- function(expected_yield_tons_ha,
                               crop,
                               uptake_table = agrinutri_data_get("uptake_table")) {
  if (!is.numeric(expected_yield_tons_ha) || expected_yield_tons_ha < 0) {
    stop("`expected_yield_tons_ha` must be non-negative numeric.")
  }
  crop <- resolve_crop(crop, table = uptake_table)
  idx <- which(uptake_table$crop == crop)
  if (length(idx) == 0) stop(sprintf("Crop '%s' not found in uptake_table.", crop))
  idx <- idx[1]
  coef <- suppressWarnings(as.numeric(uptake_table$K2O[idx]))
  if (is.na(coef)) {
    warning(sprintf("No K2O coefficient available for crop '%s'.", crop))
    return(list(K2O_requirement = NA_real_, unit_coef = NA_real_, crop = crop))
  }
  # Fert_Office A coefficients are expressed per quintale (0.1 t); multiply by 10.
  list(K2O_requirement = expected_yield_tons_ha * coef * 10,
       unit_coef = coef, crop = crop, units = "kg K2O/ha")
}
