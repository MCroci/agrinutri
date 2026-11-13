#' Nitrogen Immobilization Loss Calculation
#'
#' Calculates the amount of nitrogen immobilized by soil microorganisms based on soil fertility,
#' oxygen availability, and drainage.
#'
#' @param B Soil fertility factor (B) representing the potential nitrogen mineralization.
#' @param oxygen_availability Oxygen availability level in the soil (e.g., "Normal", "Reduced", "Poor").
#' @param id_rag Soil drainage index (ID_Rag), ranging from 1 (well-drained) to 5 (poorly drained).
#' @param greenhouse Logical. If `TRUE`, adds 2 kg/ha of nitrogen immobilization as per
#'   DPI 2026 foglio C&D (cella D23 "In serra = 2"). Default `FALSE`.
#' @param E_residual Optional numeric. When the previous crop has negative residual N
#'   (e.g. maize stalks buried, sorghum) the DPI 2026 sums `-E` into D (see foglio C&D,
#'   cella I21 "E da conteggiare"). If provided and negative, `-E_residual` is added to D.
#'   Default `0` (no adjustment; E is handled separately in `calculate_N_fertilization`).
#'
#' @return The estimated nitrogen immobilization loss (D) in kg/ha.
#' @export
#'
#' @details This function uses lookup tables (`ca.table` and `cb.table`) from the `agrinutri` package
#' to determine the immobilization correction factor (`fc_D`) based on soil drainage and oxygen
#' availability. The nitrogen immobilization loss is then calculated as:
#'
#'   D = B * fc_D + 2 * (greenhouse) + max(0, -E_residual)
#'
#' @examples
#' calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal", id_rag = 3)
#' # greenhouse:
#' calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal",
#'                            id_rag = 3, greenhouse = TRUE)

calc_N_immobilization_loss <- function(B = 50, oxygen_availability = "Normal",
                                       id_rag = 1, greenhouse = FALSE,
                                       E_residual = 0) {

  oxygen_availability <- agrinutri_normalize_oxygen(oxygen_availability)
  ca.table <- agrinutri_data_get("ca.table")
  cb.table <- agrinutri_data_get("cb.table")

  # Get ID_Dre corresponding to oxygen_availability
  avail <- trimws(as.character(ca.table$availability))
  id_dre <- ca.table$ID_Dre[match(oxygen_availability, avail)]

  # Check if id_dre is valid
  if (is.na(id_dre)) {
    stop("Invalid value for oxygen_availability. Check available options in ca.table.")
  }

  # Get fc_D corresponding to id_rag and id_dre
  fc_D <- cb.table$fc_D[cb.table$ID_Rag == id_rag & cb.table$ID_Dre == id_dre]

  # Check if fc_D is valid
  if (length(fc_D) == 0 || is.na(fc_D)) {
    stop("Invalid combination of id_rag and oxygen_availability. Check cb.table for valid combinations.")
  }

  D <- B * fc_D

  # DPI 2026 in-serra: +2 kg/ha (foglio C&D D23)
  if (isTRUE(greenhouse)) {
    D <- D + 2
  }

  # DPI 2026: E negativa (immobilizzazione da precessione) conteggiata in D
  if (is.numeric(E_residual) && !is.na(E_residual) && E_residual < 0) {
    D <- D + abs(E_residual)
  }

  return(D)
}
