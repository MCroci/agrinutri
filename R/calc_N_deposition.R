#' Natural Nitrogen Contribution
#'
#' Calculates the natural nitrogen (N) contribution from atmospheric deposition based on location and crop category.
#'
#' @param location The location or type of area (e.g., "Plain adjacent to urbanized areas"). Must match a value in the `location` column of the `g.table`.
#' @param ccp Crop category and planting period (e.g., "Autumn-winter crop <150 days"). Must match a value in the `ccp` column of the `coef_time` table.
#' @param g.table A data frame containing annual nitrogen deposition rates for different locations.
#'   It should have at least two columns: `location` (character) and `annual_deposition` (numeric).
#'   Defaults to `agrinutri::g.table`.
#' @param coef_time A data frame containing adjustment factors (C_tempo) based on crop category and planting period.
#'   It should have at least two columns: `ccp` (character) and `C_tempo` (numeric).
#'   Defaults to `agrinutri::coef_time`.
#'
#' @return The estimated natural nitrogen contribution in kg/ha, or `NA` if input values are not found in the respective tables.
#'
#' @details
#'   The function calculates the natural nitrogen contribution using the following formula:
#'
#'   ```
#'   G = annual_deposition * C_tempo
#'   ```
#'
#'   where:
#'   - `G` is the natural nitrogen contribution (kg/ha)
#'   - `annual_deposition` is the annual nitrogen deposition rate for the specified `location` (kg/ha/year)
#'   - `C_tempo` is the adjustment factor based on the `ccp`
#'
#' @export
#'
#' @examples
#' natural_contribution(
#'   location = "Plain adjacent to urbanized areas",
#'   ccp = "Autumn-winter crop <150 days"
#' )

natural_contribution <- function(location = "Plain adjacent to urbanized areas",
                                 ccp = "Autumn-winter crop <150 days",
                                 g.table = agrinutri_data_get("g.table"),
                                 coef_time = agrinutri_data_get("coef_time")) {

  # Input Validation
  if (!location %in% g.table$location) {
    warning(paste("Location '", location, "' not found in the table. Returning NA."))
    return(NA)
  }

  ccp <- resolve_ccp(ccp, table = coef_time)
  if (!ccp %in% coef_time$ccp) {
    warning(paste("CCP '", ccp, "' not found in the table. Returning NA."))
    return(NA)
  }

  # Retrieval of Data
  annual_deposition <- g.table$annual_deposition[g.table$location == location]
  ctempo <- coef_time$C_tempo[coef_time$ccp == ccp]

  # Calculation
  G <- annual_deposition * ctempo

  return(G)
}
