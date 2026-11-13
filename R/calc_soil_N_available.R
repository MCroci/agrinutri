#' Calculate soil fertility parameters (B = B1 + B2 in DPI).
#'
#' Estimates readily available and mineralized nitrogen in the soil as in
#' Fert_Office v1.26 (foglio `B`). DPI naming: b1 = readily available N from
#' soil total N ("N pronto", DPI B2); b2 = mineralized N from SOM (DPI B1).
#'
#' \itemize{
#'   \item b1 = `coef.N.readily` x min(Ntot, 2.1); it is counted only for
#'     crops with a time coefficient below 1 (cycle shorter than one year).
#'     Perennial crops in production (`C_tempo` = 1) use B = b2 only.
#'   \item b2 = `coef.N.mineralised` x min(SOM, 3) x `C_tempo`; the DPI keeps
#'     the mineralised N constant above 3 percent organic matter.
#'   \item With `soil_seeding = "no-till"` (semina su sodo) the soil supply is
#'     reduced by 10 kg N/ha, for crops where the DPI allows it
#'     (`crops.table$no_till_reduction`) and only when b1 is counted.
#' }
#' Total B = b1 + b2 - `no_till_reduction`.
#'
#' @param Ntot Total nitrogen content in the soil (g/kg, per mille).
#' @param SOM Soil organic matter content (%).
#' @param soil.group Soil group (e.g., "Sandy textures").
#' @param CN Carbon-to-nitrogen ratio.
#' @param ccp Crop category and planting period (e.g., "Autumn-winter crop <150 days").
#' @param soil_seeding Seeding mode, one of `"traditional"` (default) or `"no-till"`.
#' @param crop Optional crop name; used to check whether the no-till reduction
#'   applies to the crop. If `NULL`, the reduction applies to every crop.
#' @param coefN_readily,coefN_mineralised,coef_time Lookup tables.
#'
#' @return A named list containing:
#'   - b1: Readily available nitrogen (kg/ha), DPI B2 (0 for perennial crops
#'     in production).
#'   - b2: Mineralized nitrogen from SOM (kg/ha), DPI B1.
#'   - b1_potential: N pronto before the perennial rule (used by the leaching
#'     term).
#'   - no_till_reduction: Reduction for no-till seeding (kg/ha).
#'   - B: Total soil supply b1 + b2 - no_till_reduction (kg/ha).
#'   - C_tempo: Time coefficient of the crop phase.
#'   - units: The units of the output values ("kg/ha").
#'
#' @examples
#' soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Loamy textures", CN = 7.7,
#'                ccp = "Spring-summer crop 100-130 days")
#' @export
soil_fertility <- function(Ntot = 1.2, SOM = 2, soil.group = "Sandy textures",
                           CN = 8, ccp = "Autumn-winter crop <150 days",
                           soil_seeding = c("traditional", "no-till"),
                           crop = NULL,
                           coefN_readily = nfert_data_get("coefN_readily"),
                           coefN_mineralised = nfert_data_get("coefN_mineralised"),
                           coef_time = nfert_data_get("coef_time")) {
  soil_seeding <- match.arg(soil_seeding)
  ccp <- resolve_ccp(ccp, table = coef_time)
  CN_class <- ifelse(CN < 9, "<9", ifelse(CN >= 9 & CN < 12, "9-12", ">12"))

  coef.N.readily <- as.numeric(coefN_readily[coefN_readily[, "group"] == soil.group, "coef.N.readily"])
  coef.N.mineralised <- as.numeric(coefN_mineralised[coefN_mineralised[, "group"] == soil.group &
                                                       coefN_mineralised[, "CN_ratio"] == CN_class,
                                                     "coef.N.mineralised"])
  ctempo <- as.numeric(coef_time[coef_time[, "ccp"] == ccp, "C_tempo"])

  # N pronto from total N, capped at 2.1 g/kg (Fert_Office foglio B, H19)
  b1_potential <- min(Ntot, 2.1) * coef.N.readily
  annual_crop <- isTRUE(ctempo < 1)
  b1 <- if (annual_crop) b1_potential else 0

  # Mineralised N from SOM, constant above 3 % SOM, scaled by the time coefficient
  b2 <- min(SOM, 3) * coef.N.mineralised * ctempo

  # Semina su sodo: -10 kg/ha on the soil supply (DPI Allegato 2; foglio B, P7)
  no_till <- 0
  if (identical(soil_seeding, "no-till") && annual_crop && .no_till_applies(crop))
    no_till <- 10

  list(b1 = b1, b2 = b2, b1_potential = b1_potential,
       no_till_reduction = no_till, B = b1 + b2 - no_till,
       C_tempo = ctempo, units = "kg/ha")
}

# TRUE when the DPI no-till reduction applies to `crop` (crops.table flag).
.no_till_applies <- function(crop) {
  if (is.null(crop)) return(TRUE)
  ct <- tryCatch(nfert_data_get("crops.table"), error = function(e) NULL)
  if (is.null(ct) || !"no_till_reduction" %in% names(ct)) return(TRUE)
  key <- .nfert_ascii_fold(tolower(trimws(crop)))
  i <- match(key, .nfert_ascii_fold(tolower(trimws(ct$crop))))
  if (is.na(i) && "crop_it" %in% names(ct))
    i <- match(key, .nfert_ascii_fold(tolower(trimws(ct$crop_it))))
  if (is.na(i)) return(TRUE)
  isTRUE(as.logical(ct$no_till_reduction[i]))
}
