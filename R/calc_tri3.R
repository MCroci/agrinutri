#' Soil Texture Class Determination (Simplified)
#'
#' Determines a simplified soil texture class based on clay and sand percentages.
#'
#' @param clay Percentage of clay in the soil (0-100).
#' @param sand Percentage of sand in the soil (0-100).
#' @param tri3.table A matrix containing the simplified soil texture classes
#'   based on clay and sand percentages. The default is the package dataset
#'   `tri3.table`.
#'
#' @return A character string representing the simplified soil texture class
#'   (e.g., "Sandy", "Loamy", "Clayey"). If the `clay` and `sand` combination
#'   does not fall within the defined classes in `tri3.table`, returns NA.
#'
#' @note
#'   - This function provides a simplified classification based on the USDA soil
#'     texture triangle. For a more detailed classification, consider using the
#'     `tri2()` function.
#'   - As in Fert_Office (foglio `Suolo`), `clay` and `sand` are truncated to
#'     whole percentages (`INT`) before the triangle lookup, so 40.6 % clay is
#'     read as 40 %.
#'   - Ensure that `clay` and `sand` percentages are valid (within 0-100) and their
#'     sum does not exceed 100.
#'
#' @export
#'
#' @examples
#' tri3(clay = 10, sand = 35)  # "Sandy"
#' tri3(clay = 25, sand = 20)  # "Loamy"
#' tri3(clay = 55, sand = 15)  # "Clayey"

tri3 <- function(clay = 10, sand = 35, tri3.table = agrinutri_data_get("tri3.table")) {

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

  # Ensure tri3.table is a matrix
  if (!is.matrix(tri3.table)) {
    tri3.table <- as.matrix(tri3.table)
  }

  # Determine row and column indices
  row <- 101 - floor(clay)
  col <- 1 + floor(sand)

  # Retrieve simplified texture class
  texture_class <- tri3.table[row, col]

  # Check if result is valid (exists in tri3.table)
  valid_classes <- unique(as.vector(tri3.table))
  if (is.na(texture_class) || !texture_class %in% valid_classes) {
    warning("Clay and sand combination does not correspond to a defined texture class. Returning NA.")
    return(NA)
  }

  return(texture_class)
}
