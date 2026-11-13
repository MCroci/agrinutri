#' Leaching Loss of Nitrogen
#'
#' DPI 2026 (Allegato 2; foglio \verb{C&D} di Fert_Office v1.26): loss of readily
#' available mineral nitrogen ("N pronto") from leaching.
#'
#' Let \eqn{N_p} be the leachable N pronto: \code{b1} for crops with a cycle
#' shorter than one year, or a fixed 30 kg N/ha for perennial crops in
#' production (\code{perennial = TRUE}, i.e. time coefficient 1).
#'
#' \describe{
#'   \item{\strong{C1} (\eqn{C_a}, autumn--winter)}{
#'     Depends on winter rainfall \eqn{y} (1 October -- 31 January,
#'     \code{winter_rain}, mm): \eqn{N_p \times \min(\max(y - 150, 0), 100)/100},
#'     i.e. no loss up to 150 mm and the whole pool above 250 mm. It is 0 when
#'     \code{autumn_loss = FALSE} (first phase of a crop cycle, e.g. a second
#'     crop or pre-planting, as in Fert_Office).}
#'   \item{\strong{C2} (\eqn{C_b}, end of winter)}{
#'     With \eqn{s = y + f - 250}, where \eqn{f} is February rainfall
#'     (\code{start_spring_rain}): when \eqn{s > 0} the N pronto not yet lost
#'     (\eqn{N_p - C_a}) is lost, plus 1 kg N/ha for every 10 mm of \eqn{s} if
#'     \eqn{y > 150} mm.}
#' }
#'
#' \code{oxygen_availability} is validated against \code{\link{ca.table}} for
#' consistency with other balance terms; the leaching formulas do not use it.
#'
#' @param winter_rain Winter rainfall (October 1 to January 31) in mm.
#' @param start_spring_rain Rainfall in February in mm.
#' @param oxygen_availability Oxygen availability level in the soil: one of
#'   \code{ca.table$availability} (e.g. \code{"Normal"}, \code{"Slow"}, \code{"Fast"}).
#' @param id_rag Soil texture group index (\code{ID_Rag}); retained for backward
#'   compatibility (not used in the formulas).
#' @param b1 Readily available nitrogen in the soil (kg N/ha).
#' @param perennial Logical; \code{TRUE} for perennial crops in production
#'   (time coefficient 1), whose leachable pool is fixed at 30 kg N/ha.
#' @param autumn_loss Logical; \code{FALSE} sets \eqn{C_a} to 0.
#'
#' @return A list containing:
#'         \item{C1}{Autumn--winter leaching loss (kg N/ha).}
#'         \item{C2}{End-of-winter leaching loss (kg N/ha).}
#'         \item{surplus_pluviometrico}{Logical. \code{TRUE} when
#'           \code{winter_rain + start_spring_rain >= 300} mm (DPI 2026 scheda a
#'           dose standard: surplus-pluviometric flag).}
#'
#' @export
#'
#' @examples
#' leaching_loss(winter_rain = 160, start_spring_rain = 40,
#'               oxygen_availability = "Normal", id_rag = 3, b1 = 29.16)
#' leaching_loss(winter_rain = 300, start_spring_rain = 20, b1 = 0,
#'               perennial = TRUE)
leaching_loss <- function(winter_rain = 160, start_spring_rain = 40,
                          oxygen_availability = "Normal", id_rag = 3, b1 = 29.16,
                          perennial = FALSE, autumn_loss = TRUE) {

  if (!is.numeric(id_rag) || length(id_rag) != 1L || !is.finite(id_rag)) {
    stop("`id_rag` must be a single finite numeric value.", call. = FALSE)
  }
  if (!is.numeric(b1) || length(b1) != 1L || !is.finite(b1) || b1 < 0) {
    stop("`b1` must be a non-negative finite numeric value.", call. = FALSE)
  }

  oxygen_availability <- nfert_normalize_oxygen(oxygen_availability)
  ca.table <- nfert_data_get("ca.table")
  avail <- unique(trimws(as.character(ca.table[["availability"]])))

  if (!oxygen_availability %in% avail) {
    stop(
      "Invalid value for oxygen_availability. Use one of: ",
      paste(sort(avail), collapse = ", "),
      call. = FALSE
    )
  }

  N_p <- if (isTRUE(perennial)) 30 else b1

  # Ca: autumn-winter (C&D!C20:C22)
  percentage_loss <- min(max(winter_rain - 150, 0), 100)
  C1 <- if (isTRUE(autumn_loss)) N_p * percentage_loss / 100 else 0

  # Cb: late rain and February (C&D!C24, C30:C32)
  excess <- start_spring_rain - (250 - winter_rain)
  C2 <- 0
  if (excess > 0) {
    C2 <- N_p - C1
    if (winter_rain > 150) C2 <- C2 + excess / 10
  }

  # DPI 2026 scheda standard: surplus pluviometrico (foglio C&D)
  surplus_pluviometrico <- isTRUE((winter_rain + start_spring_rain) >= 300)

  list(C1 = C1, C2 = C2, surplus_pluviometrico = surplus_pluviometrico)
}
