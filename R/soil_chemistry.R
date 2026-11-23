#' Classify soil pH
#'
#' DPI 2026 7-class scheme from the Fert_Office v1.26 pH sheet:
#' \itemize{
#'   \item strongly acid: pH < 5.4
#'   \item acid: 5.4 - 6.0
#'   \item slightly acid: 6.1 - 6.7
#'   \item neutral: 6.8 - 7.3
#'   \item slightly alkaline: 7.4 - 8.1
#'   \item alkaline: 8.2 - 8.6
#'   \item strongly alkaline: > 8.6
#' }
#' The class is found as in Fert_Office (`VLOOKUP` on the lower thresholds
#' 0, 5.4, 6.0, 6.7, 7.3, 8.1, 8.61), so a value equal to a threshold falls in
#' the upper class: for instance pH 6.0 is "slightly acid". The ranges
#' above are those printed in the DPI table for one-decimal pH readings.
#' @param pH Numeric.
#' @param ph.table Lookup (default `agrinutri::ph.table`).
#' @return List with `ID_pH` and `class`.
#' @examples classify_pH(8.3)
#' @export
classify_pH <- function(pH, ph.table = agrinutri_data_get("ph.table")) {
  if (!is.numeric(pH) || length(pH) != 1 || is.na(pH)) {
    stop("`pH` must be a single numeric.")
  }
  t <- ph.table[order(as.numeric(ph.table$threshold_min)), , drop = FALSE]
  id <- NA_integer_; cl <- NA_character_
  for (i in seq_len(nrow(t))) {
    thr <- as.numeric(t$threshold_min[i])
    if (!is.na(thr) && pH >= thr) { id <- as.integer(t$ID_pH[i]); cl <- as.character(t$`class`[i]) }
  }
  list(ID_pH = id, class = cl, pH = pH)
}

#' Classify total carbonate (CaCO3 %)
#' @param caco3_tot Numeric.
#' @param total_carbonate.table Lookup.
#' @return List with `ID` and `class`.
#' @examples classify_carbonate_tot(15)
#' @export
classify_carbonate_tot <- function(caco3_tot, total_carbonate.table = agrinutri_data_get("total_carbonate.table")) {
  if (!is.numeric(caco3_tot) || length(caco3_tot) != 1 || is.na(caco3_tot)) {
    stop("`caco3_tot` must be a single numeric.")
  }
  t <- total_carbonate.table
  for (i in seq_len(nrow(t))) {
    lo <- as.numeric(t$min[i]); hi <- as.numeric(t$max[i])
    if (!is.na(lo) && !is.na(hi) && caco3_tot >= lo && caco3_tot < hi) {
      return(list(ID = as.integer(t$ID[i]), class = as.character(t$`class`[i]),
                  caco3_tot = caco3_tot))
    }
  }
  list(ID = NA_integer_, class = NA_character_, caco3_tot = caco3_tot)
}

#' Classify active carbonate
#' @param caco3_att Numeric %.
#' @param active_carbonate.table Lookup.
#' @return List with `ID` and `class`.
#' @examples classify_carbonate_att(6.8)
#' @export
classify_carbonate_att <- function(caco3_att, active_carbonate.table = agrinutri_data_get("active_carbonate.table")) {
  if (!is.numeric(caco3_att) || length(caco3_att) != 1 || is.na(caco3_att)) {
    stop("`caco3_att` must be a single numeric.")
  }
  t <- active_carbonate.table
  for (i in seq_len(nrow(t))) {
    lo <- as.numeric(t$min[i]); hi <- as.numeric(t$max[i])
    if (!is.na(lo) && !is.na(hi) && caco3_att >= lo && caco3_att < hi) {
      return(list(ID = as.integer(t$ID[i]), class = as.character(t$`class`[i]),
                  caco3_att = caco3_att))
    }
  }
  list(ID = NA_integer_, class = NA_character_, caco3_att = caco3_att)
}

#' Classify cation exchange capacity (CEC, meq/100 g)
#' From the Fert_Office v1.26 K sheet: < 10 low, 10-20 medium, > 20 high,
#' returned as the Italian labels `"bassa"`, `"media"`, `"alta"`.
#' @param csc_meq Numeric meq/100 g.
#' @return List with `class`.
#' @examples classify_CEC(18)
#' @export
classify_CEC <- function(csc_meq) {
  if (!is.numeric(csc_meq) || length(csc_meq) != 1 || is.na(csc_meq)) {
    return(list(class = "non valorizzato", csc = csc_meq))
  }
  cl <- if (csc_meq < 10) "bassa" else if (csc_meq <= 20) "media" else "alta"
  list(class = cl, csc = csc_meq)
}

#' Mg/K ratio assessment (Fert_Office K sheet)
#' 0-0.1 low; 0.1-2.1 balanced; 2.1-5.1 high; >5.1 very high, returned as the
#' Italian labels `"basso"`, `"equilibrato"`, `"alto"`, `"molto alto"`.
#' @param mg_ppm,k_ppm Magnesium and potassium ppm.
#' @return List with `ratio` and `class`.
#' @examples ratio_Mg_K(mg_ppm = 121.5, k_ppm = 150)
#' @export
ratio_Mg_K <- function(mg_ppm, k_ppm) {
  if (any(!is.numeric(c(mg_ppm, k_ppm)))) {
    return(list(ratio = NA_real_, class = "non calcolato"))
  }
  # Convert to meq (valence 2 for Mg, 1 for K)
  mg_meq <- mg_ppm / 12.15
  k_meq  <- k_ppm  / 39.10
  r <- if (k_meq > 0) mg_meq / k_meq else NA_real_
  cl <- if (is.na(r)) "non calcolato" else
    if (r < 0.1) "basso" else
      if (r < 2.1) "equilibrato" else
        if (r < 5.1) "alto" else "molto alto"
  list(ratio = r, class = cl)
}

#' K/CEC ratio assessment (Fert_Office K sheet)
#' <0.1% low; 0.1-2.1 optimal; 2.1-5.1 high (percentage of CEC), returned as
#' the Italian labels `"basso"`, `"ottimale"`, `"alto"`.
#' @param k_meq_per_100g K in meq/100g.
#' @param csc_meq CEC in meq/100g.
#' @return List with `pct` and `class`.
#' @examples ratio_K_CEC(k_meq_per_100g = 0.38, csc_meq = 18)
#' @export
ratio_K_CEC <- function(k_meq_per_100g, csc_meq) {
  if (!is.numeric(k_meq_per_100g) || !is.numeric(csc_meq) ||
      length(k_meq_per_100g) != 1L || length(csc_meq) != 1L ||
      is.na(k_meq_per_100g) || is.na(csc_meq) || csc_meq <= 0) {
    return(list(pct = NA_real_, class = "non calcolato"))
  }
  pct <- 100 * k_meq_per_100g / csc_meq
  cl <- if (pct < 0.1) "basso" else
    if (pct < 2.1) "ottimale" else
      if (pct < 5.1) "alto" else "non calcolato"
  list(pct = pct, class = cl)
}
