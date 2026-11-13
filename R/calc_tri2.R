#' Soil Texture Class Determination
#'
#' Determines the soil texture class (ID_Rag) based on clay and sand percentages.
#'
#' @param clay Percentage of clay in the soil.
#' @param sand Percentage of sand in the soil.
#'
#' @return The soil texture class ID (ID_Rag) corresponding to the given clay
#'   and sand percentages.
#'
#' @note
#'   - This function uses the USDA soil texture triangle classification.
#'   - Ensure the `clay` and `sand` percentages are valid (within 0-100) and their sum does not exceed 100.
#'
#' @export
#'
#' @examples
#' tri2(clay = 10, sand = 35)
#' tri2(clay = 25, sand = 20)

tri2 <- function(clay = 10, sand = 35) {

  tri2.table <- agrinutri_data_get("tri2.table")

  # Input Validation
  if (!is.numeric(clay) || clay < 0 || clay > 100) {
    stop("Invalid clay percentage. Must be a numeric value between 0 and 100.")
  }
  if (!is.numeric(sand) || sand < 0 || sand > 100) {
    stop("Invalid sand percentage. Must be a numeric value between 0 and 100.")
  }

  # Additional Validation: Check if clay + sand <= 100
  if (clay + sand > 100) {
    stop("Invalid clay and sand combination. Their sum must not exceed 100%.")
  }

  # Ensure tri2.table is a matrix
  if (!is.matrix(tri2.table)) {
    tri2.table <- as.matrix(tri2.table)
  }

  # Determine row and column indices (simplified)
  row <- 101 - floor(clay)
  col <- 1 + floor(sand)

  # Retrieve ID_Rag
  res <- tri2.table[row, col]

  # Check if result is valid (exists in tri2.table)
  valid_ids <- unique(as.vector(tri2.table))  # Get all unique IDs from the table
  if (!res %in% valid_ids) {
    stop("Invalid clay and sand combination. No corresponding soil texture class found.")
  }

  as.integer(round(res))
}
