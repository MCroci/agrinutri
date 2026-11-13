#' Calculate Nitrogen Fertilization Requirement
#'
#' Calculates the final nitrogen fertilization requirement (N_fert) from a nitrogen balance result.
#'
#' @param n_balance A data frame returned by `N_balance()` containing nitrogen balance components.
#' @param method The calculation method to use. Only "standard" (DPI balance)
#'   is available.
#'
#' @return A numeric value representing the nitrogen fertilization requirement in kg/ha.
#'
#' @details
#' This function calculates the mineral nitrogen to apply from the nitrogen
#' balance components, as Fert_Office v1.26 does: the balance
#' ```
#' N = A - B + C1 + C2 + D - E - F - G
#' ```
#' is multiplied by the share admitted for the crop phase (`N_pct`; 0 before
#' planting, 1 for most phases), bounded to 0 and to the crop's ceiling
#' (`N_limit`, usually 340 kg N/ha), and the current-year organic N `Forg` is
#' then subtracted (the result is never negative):
#' ```
#' N_fert = max(0, min(max(0, N * N_pct), N_limit) - Forg)
#' ```
#'
#' Where:
#' - A: Crop nitrogen demand
#' - B: Soil nitrogen supply
#' - C1, C2: Leaching losses
#' - D: Immobilization losses
#' - E: Nitrogen from previous crop residues
#' - F: Nitrogen from previous years' organic fertilization (0 if not in balance)
#' - Forg: Nitrogen from organic fertilizer (current year)
#' - G: Natural nitrogen contribution
#'
#' @export
#'
#' @examples
#' # Calculate nitrogen balance
#' balance <- N_balance(
#'   expected_yield_tons_ha = 60,
#'   crop = "Mais trinciato (classe 700)",
#'   ccp = "Spring-summer crop 100-130 days",
#'   sand = 50, clay = 35,
#'   Ntot = 1.2, SOM = 1.2, CN = 9.5,
#'   oxygen_availability = "Normal",
#'   winter_rain = 160, start_spring_rain = 40,
#'   prev_crop = "Winter cereals straw removal",
#'   source = "Cattle slurry",
#'   fertorg_frequency = "every year",
#'   location = "Plain adjacent to urbanized areas",
#'   forg_quantity = 100
#' )
#'
#' # Calculate required nitrogen fertilization
#' n_fert <- calculate_N_fertilization(balance)
#' print(paste("Required N fertilization:", round(n_fert, 2), "kg/ha"))

calculate_N_fertilization <- function(n_balance, method = "standard") {
  # Input validation
  if (!is.data.frame(n_balance)) {
    stop("n_balance must be a data frame (typically returned by N_balance()).")
  }
  
  required_cols <- c("A", "B", "C1", "C2", "D", "E", "Forg", "G")
  missing_cols <- setdiff(required_cols, names(n_balance))
  if (length(missing_cols) > 0) {
    stop(paste("n_balance is missing required columns:",
               paste(missing_cols, collapse = ", ")))
  }
  
  if (nrow(n_balance) == 0) {
    stop("n_balance data frame is empty.")
  }
  
  # Extract values (handle first row if multiple rows exist). F optional (backward compatibility)
  A <- n_balance$A[1]
  B <- n_balance$B[1]
  C1 <- n_balance$C1[1]
  C2 <- n_balance$C2[1]
  D <- n_balance$D[1]
  E <- n_balance$E[1]
  F_prev <- if ("F" %in% names(n_balance)) n_balance$F[1] else 0
  Forg <- n_balance$Forg[1]
  G <- n_balance$G[1]
  
  # Handle NA values (set to 0 for calculation purposes, but warn user)
  na_components <- character()
  if (is.na(A)) na_components <- c(na_components, "A")
  if (is.na(B)) { B <- 0; na_components <- c(na_components, "B") }
  if (is.na(C1)) { C1 <- 0; na_components <- c(na_components, "C1") }
  if (is.na(C2)) { C2 <- 0; na_components <- c(na_components, "C2") }
  if (is.na(D)) { D <- 0; na_components <- c(na_components, "D") }
  if (is.na(E)) { E <- 0; na_components <- c(na_components, "E") }
  if (is.na(F_prev)) F_prev <- 0
  if (is.na(Forg)) { Forg <- 0; na_components <- c(na_components, "Forg") }
  if (is.na(G)) { G <- 0; na_components <- c(na_components, "G") }
  
  if (length(na_components) > 0 && !("A" %in% na_components)) {
    warning(paste("Some balance components are NA and were set to 0:",
                  paste(na_components, collapse = ", ")))
  }
  
  if (is.na(A)) {
    stop("Crop nitrogen demand (A) is NA. Cannot calculate fertilization requirement.")
  }
  
  if (method != "standard") stop("Unknown method. Use 'standard'.")

  # DPI balance (Fert_Office Bilancio!H31): N = A - B + C + D - E - F - G
  N_need <- A - B + C1 + C2 + D - E - F_prev - G

  # Reported dose (Fert_Office "Valori da riportare"): share admitted for the
  # crop phase, non-negative, capped at the crop's ceiling. Older balance
  # objects without these columns use 1 and no cap.
  N_pct <- if ("N_pct" %in% names(n_balance)) n_balance$N_pct[1] else 1
  N_limit <- if ("N_limit" %in% names(n_balance)) n_balance$N_limit[1] else Inf
  if (is.na(N_pct)) N_pct <- 1
  if (is.na(N_limit)) N_limit <- Inf
  N_dose <- min(max(0, N_need * N_pct), N_limit)

  # Mineral N to apply: the current-year organic contribution is subtracted
  max(0, N_dose - Forg)
}
