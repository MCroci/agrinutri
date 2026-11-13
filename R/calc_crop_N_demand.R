#' Crop requirement estimation
#'
#' Estimates the crop's nitrogen requirement based on unit crop absorption
#' and expected yield, with a biological N-fixation correction for
#' legumes.
#'
#' The calculation is:
#' \preformatted{
#' A_gross = unit crop absorption (kg N / t yield) * yield (t / ha)
#' A       = A_gross * (1 - n_fixation_pct / 100)
#' }
#' where \code{n_fixation_pct} is taken from
#' \code{agrinutri::crops.table$n_fixation_pct} (0 for non-legumes, 85-100
#' for soybean, pea, faba bean, alfalfa, lupin, clover, etc.). Non-legume
#' crops have \code{n_fixation_pct = 0}, so the correction is a no-op.
#'
#' @param expected_yield_tons_ha Expected crop yield in tons per hectare
#'   (t/ha).
#' @param crop The name of the crop for which to calculate the
#'   requirement. Must be a valid value in the \code{crop} column of the
#'   \code{uptake_table} (English canonical names after agrinutri 0.12.0).
#' @param apply_n_fixation Logical. If \code{TRUE} (default) the gross
#'   demand is multiplied by \code{(1 - n_fixation_pct / 100)} using
#'   \code{agrinutri::crops.table}. Set to \code{FALSE} to recover the
#'   pre-0.12.1 behaviour (no fixation correction).
#'
#' @return A list with \code{N_requirement} (kg/ha), \code{units}
#'   ("kg/ha") and \code{n_fixation_pct} (0-100, the fraction applied).
#'
#' @note The `uptake_table` should provide the unit crop absorption for
#'   the specified `crop`. The default table (`agrinutri::uptake_table`) may
#'   not be suitable for all regions or specific crop varieties.
#'
#' @export
calc_crop_N_demand <- function(expected_yield_tons_ha = 10,
                              crop = "Shredded corn class 700",
                              apply_n_fixation = TRUE) {

  uptake_table <- agrinutri_data_get("uptake_table")

  # Accept either Italian (canonical) or English crop name
  crop <- resolve_crop(crop, table = uptake_table)

  # Error Handling and Input Validation
  if (!crop %in% uptake_table$crop) {
    stop(paste("Crop '", crop, "' not found in the uptake table."))
  }

  if (expected_yield_tons_ha <= 0) {
    stop("Expected yield must be a positive value.")
  }

  # Extraction and Calculation (use first match if crop appears multiple
  # times)
  N_perc <- uptake_table$N[uptake_table$crop == crop][1]
  N_requirement_kg_ha <- expected_yield_tons_ha * N_perc * 10  # kg/ha

  # Biological N-fixation correction for legumes. Lookup is tolerant of
  # both language variants of the crops.table schema.
  fix_pct <- 0
  if (isTRUE(apply_n_fixation)) {
    ct <- tryCatch(agrinutri_data_get("crops.table"), error = function(e) NULL)
    if (!is.null(ct) && "n_fixation_pct" %in% names(ct)) {
      m <- match(crop, ct$crop)
      if (is.na(m) && "crop_it" %in% names(ct))
        m <- match(.agrinutri_ascii_fold(crop), .agrinutri_ascii_fold(ct$crop_it))
      if (is.na(m) && "crop_en" %in% names(ct))
        m <- match(crop, ct$crop_en)
      if (!is.na(m)) {
        fp <- suppressWarnings(as.numeric(ct$n_fixation_pct[m]))
        if (is.finite(fp) && fp > 0 && fp <= 100) fix_pct <- fp
      }
    }
  }
  N_requirement_kg_ha <- N_requirement_kg_ha * (1 - fix_pct / 100)

  # Return with Units
  return(list(
    N_requirement  = N_requirement_kg_ha,
    units          = "kg/ha",
    n_fixation_pct = fix_pct
  ))
}

