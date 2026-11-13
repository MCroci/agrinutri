#' Soil Group and ID_Rag Determination
#'
#' Determines the soil group and ID_Rag based on clay and sand percentages using the USDA soil texture triangle.
#'
#' @param clay Percentage of clay in the soil (0-100).
#' @param sand Percentage of sand in the soil (0-100).
#' @param tri3.table A matrix containing the simplified soil texture classes based on
#'   clay and sand percentages. The default is the package dataset `tri3.table`.
#' @param soil.table A data frame mapping soil texture classes (ID_Suo) to soil groups and ID_Rag.
#'   It should have at least three columns: `ID_Suo`, `Group`, and `ID_Rag`. The default is the package dataset `soil.table`.
#'
#' @return A named list containing:
#'   - soil.group: The soil group based on the USDA classification.
#'   - id_rag: The corresponding ID_Rag (numeric ID for the soil group).
#'
#' @note
#'   - Ensure the `clay` and `sand` percentages are valid (within 0-100) and their sum does not exceed 100.
#'   - The `soil.table` is assumed to contain accurate mappings between soil texture classes, groups, and ID_Rag values.
#'
#' @export
#'
#' @examples
#' calc_soil_group_and_id_rag(clay = 10, sand = 35)
#' calc_soil_group_and_id_rag(clay = 25, sand = 20)  # Clay loam

calc_soil_group_and_id_rag <- function(clay = 10, sand = 35, tri3.table = agrinutri_data_get("tri3.table"), soil.table = agrinutri_data_get("soil.table")) {

  # Input Validation
  if (!is.numeric(clay) || clay < 0 || clay > 100) {
    stop("Invalid clay percentage. Must be a numeric value between 0 and 100.")
  }
  if (!is.numeric(sand) || sand < 0 || sand > 100) {
    stop("Invalid sand percentage. Must be a numeric value between 0 and 100.")
  }
  if (clay + sand > 100) {
    stop("Invalid clay and sand combination. Their sum must not exceed 100%.")
  }

  # Determine simplified soil texture class (TRI3)
  TRI3 <- tri3(clay, sand, tri3.table)

  # Handle case where TRI3 is NA (no matching texture class found)
  if (is.na(TRI3)) {
    stop("No soil texture class found for the given clay and sand percentages.")
  }

  # Retrieve soil group and ID_Rag (using match for safety and clarity)
  soil.group <- as.character(soil.table$Group[match(TRI3, soil.table$ID_Suo)])
  id_rag <- as.numeric(soil.table$ID_Rag[match(TRI3, soil.table$ID_Suo)])

  # Handle missing values in soil.table
  if (is.na(soil.group) || is.na(id_rag)) {
    stop(paste("No soil group or ID_Rag found for texture class:", TRI3))
  }

  return(list(
    soil.group = as.character(soil.group),
    id_rag = as.numeric(id_rag),
    TRI3 = as.character(TRI3)
  ))
}
