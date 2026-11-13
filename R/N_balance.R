#' Nitrogen Balance Calculation
#'
#' Calculates the nitrogen balance of a crop with the DPI Emilia-Romagna 2026
#' balance method (Allegato 2), reproducing the regional tool Fert_Office v1.26
#' term by term. Where the printed DPI tables and Fert_Office differ, agrinutri
#' follows Fert_Office (see `vignette("agrinutri-PK-and-distribution")`).
#'
#' @param expected_yield_tons_ha Expected crop yield in tons per hectare.
#' @param crop Name of the crop.
#' @param ccp Crop calendar period (e.g., "Spring-summer crop 100-130 days").
#' @param sand Percentage of sand in the soil.
#' @param clay Percentage of clay in the soil.
#' @param Ntot Total nitrogen content in the soil (%).
#' @param SOM Soil organic matter content (%).
#' @param CN Carbon to nitrogen ratio of the soil.
#' @param oxygen_availability Oxygen availability level in the soil (e.g., "Normal").
#' @param winter_rain Total winter rainfall (mm).
#' @param start_spring_rain Rainfall at the start of spring (mm).
#' @param prev_crop Previous crop grown in the field.
#' @param source Source of organic fertilizer (e.g., "Cattle slurry").
#' @param fertorg_frequency Frequency of organic fertilizer application (e.g., "every year").
#' @param location Location of the field relative to urban areas.
#' @param forg_quantity Quantity of organic fertilizer applied (m3/ha or t/ha, depending on source).
#'   Use \code{0} for no organic application: \code{Forg} is set to 0 without calling
#'   \code{organic_fertilization()}.
#' @param organic_previous_year_N Optional. Total N (kg/ha) from organic fertilization
#'   applied in the previous year (same source/frequency). If provided, term F (residual
#'   N from previous years' organic, DPI section 3.1.6) is included. Default 0.
#' @param soil_group Optional override for DPI organic-N efficiency (texture class).
#'   When \code{NULL} (default), \code{N_balance()} uses the \code{soil.group}
#'   computed from \code{sand} and \code{clay} via \code{calc_soil_group_and_id_rag()},
#'   so current-year organic (\code{Forg}) follows the same texture as \code{B}.
#' @param distribution_efficiency Optional. \code{"efficient"}, \code{"medium"}, or
#'   \code{"low"} (DPI distribution quality). When \code{NULL} (default),
#'   \code{N_balance()} uses \code{"medium"} for \code{Forg} (typical farm practice
#'   when not specified). Ignored for \code{Forg} when \code{forg_quantity == 0}.
#' @param soil_seeding One of `"traditional"` (default) or `"no-till"`. If `"no-till"`,
#'   the soil supply B is reduced by 10 kg/ha (DPI Allegato 2), for crops with
#'   a cycle shorter than one year where the DPI allows it.
#' @param greenhouse Logical. If `TRUE`, 2 kg/ha are added to D (DPI 2026 greenhouse factor).
#'   Default `FALSE`.
#' @param E_to_D Logical. If `TRUE` (default), negative `E` (e.g. buried stalks = -40) is
#'   added to `D` as in Fert_Office v1.26 sheet C&D, and `E` in the output is set to 0.
#'   If `FALSE`, `E` stays negative and the balance uses `calculate_N_fertilization()`.
#'   `E` is counted only for crop phases where the DPI counts the precession
#'   (`coef_time$precession_to_count`), i.e. not for perennial crops in production.
#' @param n_fixation_pct Share (%) of the legume N demand covered by biological
#'   fixation. `NULL` (default) uses the value proposed for the crop
#'   (`crops.table$n_fixation_pct`). It is booked under `G` when the balance is
#'   positive, as in Fert_Office; a value lower than the crop's default (lacking
#'   inoculation) lowers the dose ceiling to 120 kg N/ha.
#'
#' @return A data frame containing the calculated nitrogen balance components (all in kg/ha):
#'         \itemize{
#'           \item A: Total nitrogen demand of the crop (kg/ha).
#'           \item B: Total soil nitrogen supply, b1 + b2 - no-till reduction (kg/ha).
#'           \item b1: Readily available mineral nitrogen (DPI B2) (kg/ha).
#'           \item b2: Mineralizable N from soil organic matter (DPI B1) (kg/ha).
#'           \item C1: Nitrogen leaching loss in autumn-winter (Ca) (kg/ha).
#'           \item C2: Nitrogen leaching loss at the end of winter (Cb) (kg/ha).
#'           \item D: Nitrogen immobilization loss (kg/ha). Includes the abs(E) contribution
#'             if `E_to_D = TRUE` and E < 0, and `+2` if `greenhouse = TRUE`
#'             (not part of the Fert_Office v1.26 balance sheet).
#'           \item E: Nitrogen from previous crop residues (kg/ha). If `E_to_D = TRUE` and
#'             the raw value is negative, this column reports 0 (moved to D).
#'           \item F: Nitrogen from previous years' organic fertilization (kg/ha).
#'           \item Forg: Nitrogen from organic fertilizer (current year, efficient N) (kg/ha).
#'           \item G: Natural contributions (kg/ha): `G_deposition` (atmospheric
#'             deposition x time coefficient) plus `G_fixation` (legume N fixation).
#'           \item no_till_reduction: Reduction of B for no-till seeding (kg/ha).
#'           \item C_tempo, N_pct, N_limit: time coefficient of the phase, share
#'             of the balance admitted for the phase and dose ceiling (kg/ha),
#'             used by [calculate_N_fertilization()].
#'           \item surplus_pluviometrico: Logical flag (DPI 2026 standard sheet, surplus rain).
#'         }
#'
#' @details The nitrogen fertilization requirement (DPI formula) is:
#'          N = A - B + C1 + C2 + D - E - F - G, scaled by `N_pct`, bounded to
#'          [0, `N_limit`]; the current-year organic N `Forg` is then subtracted
#'          to give the mineral N ([calculate_N_fertilization()]).
#' @export
#'
#' @examples
#' N_balance(expected_yield_tons_ha = 60, crop = "Mais trinciato (classe 700)",
#'           ccp = "Spring-summer crop 100-130 days", sand = 50, clay = 35,
#'           Ntot = 1.2, SOM = 1.2, CN = 9.5, oxygen_availability = "Normal",
#'           winter_rain = 160, start_spring_rain = 40,
#'           prev_crop = "Winter cereals straw removal", source = "Cattle slurry",
#'           fertorg_frequency = "every year", location = "Plain adjacent to urbanized areas",
#'           forg_quantity = 100)

N_balance <- function(expected_yield_tons_ha = 15, crop = "Grano tenero FF (granella)", ccp = "Spring-summer crop 100-130 days",
                      sand = 50, clay = 35, Ntot = 1.2, SOM = 1.2, CN = 9.5, oxygen_availability = "Normal",
                      winter_rain = 160, start_spring_rain = 40,
                      prev_crop = "Winter cereals straw removal", source = "Cattle slurry", fertorg_frequency = "every year",
                      location = "Plain adjacent to urbanized areas", forg_quantity = 100,
                      organic_previous_year_N = 0, soil_group = NULL, distribution_efficiency = NULL,
                      soil_seeding = c("traditional", "no-till"),
                      greenhouse = FALSE,
                      E_to_D = TRUE,
                      n_fixation_pct = NULL){

  soil_seeding <- match.arg(soil_seeding)

  # Comprehensive input validation
  if (!is.numeric(expected_yield_tons_ha) || expected_yield_tons_ha <= 0) {
    stop("Expected yield must be a positive numeric value.")
  }
  if (!is.numeric(sand) || sand < 0 || sand > 100) {
    stop("Sand percentage must be a numeric value between 0 and 100.")
  }
  if (!is.numeric(clay) || clay < 0 || clay > 100) {
    stop("Clay percentage must be a numeric value between 0 and 100.")
  }
  if (sand + clay > 100) {
    stop("The sum of sand and clay percentages cannot exceed 100%.")
  }
  if (!is.numeric(Ntot) || Ntot < 0) {
    stop("Total nitrogen (Ntot) must be a non-negative numeric value.")
  }
  if (!is.numeric(SOM) || SOM < 0) {
    stop("Soil organic matter (SOM) must be a non-negative numeric value.")
  }
  if (!is.numeric(CN) || CN <= 0) {
    stop("Carbon to nitrogen ratio (CN) must be a positive numeric value.")
  }
  if (!is.numeric(winter_rain) || winter_rain < 0) {
    stop("Winter rainfall must be a non-negative numeric value.")
  }
  if (!is.numeric(start_spring_rain) || start_spring_rain < 0) {
    stop("Spring rainfall must be a non-negative numeric value.")
  }
  if (!is.numeric(forg_quantity) || forg_quantity < 0) {
    stop("Organic fertilizer quantity must be a non-negative numeric value.")
  }
  if (!is.null(organic_previous_year_N) && (!is.numeric(organic_previous_year_N) || organic_previous_year_N < 0)) {
    stop("organic_previous_year_N must be NULL or a non-negative number.")
  }

  # Calculate soil properties (single call for efficiency)
  soil_props <- calc_soil_group_and_id_rag(clay = clay, sand = sand)
  id_rag <- soil_props$id_rag
  soil.group <- soil_props$soil.group

  # Crop phase: time coefficient, precession rule and admitted share of N
  coef_time <- agrinutri_data_get("coef_time")
  ccp <- resolve_ccp(ccp, table = coef_time)
  ph <- coef_time[match(ccp, coef_time$ccp), , drop = FALSE]
  C_tempo <- as.numeric(ph$C_tempo)
  id_fa_d <- as.integer(ph$ID_Fa_D)
  count_precession <- isTRUE(as.logical(ph$precession_to_count))
  N_pct <- if ("N_pct" %in% names(ph)) as.numeric(ph$N_pct) else 1

  # A: crop demand, without the N-fixation discount (which Fert_Office books
  # under G, see below)
  A_result <- calc_crop_N_demand(expected_yield_tons_ha = expected_yield_tons_ha,
                                 crop = crop, apply_n_fixation = FALSE)
  A <- A_result$N_requirement
  crop_info <- .crop_info(crop)
  fix_default <- crop_info$n_fixation_pct
  if (is.null(n_fixation_pct)) n_fixation_pct <- fix_default
  if (!is.numeric(n_fixation_pct) || length(n_fixation_pct) != 1L ||
      is.na(n_fixation_pct) || n_fixation_pct < 0 || n_fixation_pct > 100)
    stop("`n_fixation_pct` must be NULL or a single number between 0 and 100.")

  # B: soil fertility (b1 = N pronto, b2 = mineralised from SOM)
  B <- soil_fertility(Ntot = Ntot, SOM = SOM, soil.group = soil.group, CN = CN, ccp = ccp,
                      soil_seeding = soil_seeding, crop = crop)
  B_total <- B$B

  # C: leaching. Perennial crops in production lose a fixed 30 kg N/ha pool;
  # the first phase of each cycle (pre-planting, second crop, 1st cut) has
  # no autumn-winter loss (Fert_Office C&D!C20:C22).
  C <- leaching_loss(winter_rain = winter_rain, start_spring_rain = start_spring_rain,
                     oxygen_availability = oxygen_availability, id_rag = id_rag,
                     b1 = B$b1_potential, perennial = isTRUE(C_tempo >= 1),
                     autumn_loss = !(id_fa_d %in% c(1L, 5L, 8L, 15L)))

  # E: previous crop, counted only for phases where the DPI counts it
  E_raw <- nitrogen_from_previous_crop_residues(previous_crop = prev_crop)
  E_counted <- if (count_precession) E_raw else 0

  # D: immobilisation, plus |E| when E < 0 (Fert_Office C&D!G23)
  D <- calc_N_immobilization_loss(B = B_total, oxygen_availability = oxygen_availability,
                                  id_rag = id_rag,
                                  greenhouse = greenhouse,
                                  E_residual = if (E_to_D) E_counted else 0)

  # If E<0 is folded into D, expose E = 0 in balance output to avoid double counting
  E <- if (isTRUE(E_to_D) && !is.na(E_counted) && E_counted < 0) 0 else E_counted

  # F: previous years' organic fertilisation, scaled by the time coefficient
  F_prev <- organic_previous_years_N(
    N_applied_previous_year = if (is.null(organic_previous_year_N)) 0 else organic_previous_year_N,
    source = source,
    frequency = fertorg_frequency,
    c_tempo = C_tempo
  )
  # Current-year organic N (Forg): DPI path N_tot x efficiency when texture + distribution
  # are known. Defaults match Fert_Office-style behaviour when args omitted.
  soil_for_org <- if (!is.null(soil_group)) soil_group else soil.group
  dist_for_org <- if (!is.null(distribution_efficiency)) distribution_efficiency else "medium"
  Forg <- if (isTRUE(forg_quantity == 0)) {
    0
  } else {
    organic_fertilization(
      source = source,
      frequency = fertorg_frequency,
      quantity = forg_quantity,
      soil_group = soil_for_org,
      distribution_efficiency = dist_for_org
    )
  }

  # G: natural deposition, plus biological N fixation of legumes when the
  # balance net of deposition is positive (Fert_Office foglio G, D13:D20)
  G_deposition <- natural_contribution(location = location, ccp = ccp)
  net <- A + C[["C1"]] + C[["C2"]] + D - B_total - E - F_prev - G_deposition
  G_fixation <- if (isTRUE(net > 0) && n_fixation_pct > 0) A * n_fixation_pct / 100 else 0
  G <- G_deposition + G_fixation

  # Ceiling on the reported dose (Fert_Office "Valori da riportare", E4:E7):
  # the crop's default limit, or 120 kg N/ha when the N fixation considered is
  # lower than the crop's (lacking inoculation)
  N_limit <- if (n_fixation_pct < fix_default) 120 else crop_info$N_limit
  if (id_fa_d %in% c(2L, 3L))
    warning("For young woody crops (1st / 2nd year) Fert_Office uses the ",
            "standard-dose scheme; consider dose_standard_N().", call. = FALSE)

  # Check for NA values and warn user
  na_components <- character()
  if (is.na(A)) na_components <- c(na_components, "A (crop demand)")
  if (is.na(B_total)) na_components <- c(na_components, "B (soil supply)")
  if (is.na(C[["C1"]])) na_components <- c(na_components, "C1 (winter leaching)")
  if (is.na(C[["C2"]])) na_components <- c(na_components, "C2 (spring leaching)")
  if (is.na(D)) na_components <- c(na_components, "D (immobilization)")
  if (is.na(E)) na_components <- c(na_components, "E (previous crop residues)")
  if (is.na(Forg)) na_components <- c(na_components, "Forg (organic fertilizer)")
  if (is.na(G)) na_components <- c(na_components, "G (natural contribution)")

  if (length(na_components) > 0) {
    warning(paste("Some balance components returned NA:",
                  paste(na_components, collapse = ", "),
                  ". These may indicate missing data or invalid input values."))
  }

  # Defensive: if any component is length-0 (failed silent lookup), report it
  pieces <- list(A = A, B = B_total, b1 = B[["b1"]], b2 = B[["b2"]],
                 C1 = C[["C1"]], C2 = C[["C2"]], D = D, E = E,
                 F = F_prev, Forg = Forg, G = G,
                 G_deposition = G_deposition, G_fixation = G_fixation,
                 no_till_reduction = B[["no_till_reduction"]],
                 C_tempo = C_tempo, N_pct = N_pct, N_limit = N_limit,
                 surplus_pluviometrico = C[["surplus_pluviometrico"]])
  empty <- names(pieces)[vapply(pieces, function(p) length(p) == 0, logical(1))]
  if (length(empty) > 0) {
    stop(sprintf(
      "N_balance(): the following balance component(s) returned length-0 (silent lookup failure): %s.\n%s",
      paste(empty, collapse = ", "),
      "Check that `crop`, `ccp`, `prev_crop`, `source`, `location` and soil group all match values present in the lookup tables."))
  }

  # Coerce length-1 vectors (handles the case where `A` is length 2 due to
  # crop appearing twice in uptake_table)
  pieces <- lapply(pieces, function(p) p[1])

  # Build result data frame (DPI: N = A - B + C + D - E - F - Forg - G)
  agrinutri <- as.data.frame(pieces, stringsAsFactors = FALSE)

  return(agrinutri)
}
