#' Nitrogen from previous crop residues
#'
#' Estimates the amount of nitrogen (N) available from residues of a previous crop.
#'
#' @param previous_crop The name of the previous crop. This must match a value
#'   in the `previous_crop` column of the `e.table`.
#' @param e.table A data frame containing the nitrogen values (in kg/ha) for different
#'   previous crops. It should have at least two columns: `previous_crop` (character)
#'   and `N` (numeric). The default is `agrinutri::e.table`.
#'
#' @return The estimated amount of nitrogen (N) in kg/ha available from the previous crop residues.
#'
#' @details
#'   - If the value in the `e.table` is negative, the function returns 0 (as negative N contribution
#'     from residues is not meaningful).
#'   - If there is no matching entry for `previous_crop` in the `e.table`, the function returns `NA`
#'     to indicate missing data.
#'
#' @export
#'
#' @examples
#' E <- nitrogen_from_previous_crop_residues(previous_crop = "Winter cereals straw removal")
#' print(E)
#'
nitrogen_from_previous_crop_residues <- function(previous_crop = "Winter cereals straw removal",
                                                 e.table = agrinutri_data_get("e.table")){


  # Input Validation
  if (!previous_crop %in% e.table$previous_crop) {
    warning(paste("Previous crop '", previous_crop, "' not found in the table. Returning NA."))
    return(NA)  # Return NA if the crop is not found
  }

  # Retrieve N value
  E <- e.table$N[e.table$previous_crop == previous_crop]

  return(E)
}
