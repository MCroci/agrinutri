#' Classify soil pH
#'
#' DPI 2026 7-class scheme from Fert_Office v1.26 foglio `pH`:
#' \itemize{
#'   \item fortemente acido: pH < 5.4
#'   \item acido: 5.4 - 6.0
#'   \item leggermente acido: 6.1 - 6.7
#'   \item neutro: 6.8 - 7.3
#'   \item leggermente alcalino: 7.4 - 8.1
#'   \item alcalino: 8.2 - 8.6
#'   \item fortemente alcalino: > 8.6
#' }
#' The class is found as in Fert_Office (`VLOOKUP` on the lower thresholds
#' 0, 5.4, 6.0, 6.7, 7.3, 8.1, 8.61), so a value equal to a threshold falls in
#' the upper class: for instance pH 6.0 is "leggermente acido". The ranges
#' above are those printed in the DPI table for one-decimal pH readings.
#' @param pH Numeric.
#' @param ph.table Lookup (default `NFert::ph.table`).
#' @return List with `ID_pH` and `class`.
#' @examples classify_pH(8.3)
#' @export
classify_pH <- function(pH, ph.table = nfert_data_get("ph.table")) {
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
classify_carbonate_tot <- function(caco3_tot, total_carbonate.table = nfert_data_get("total_carbonate.table")) {
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
classify_carbonate_att <- function(caco3_att, active_carbonate.table = nfert_data_get("active_carbonate.table")) {
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

#' Classify cation exchange capacity (CSC, meq/100 g)
#' From Fert_Office v1.26 foglio Gri_K: < 10 = bassa, 10-20 = media, > 20 = alta.
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

#' Mg/K ratio assessment (Fert_Office foglio Gri_K)
#' 0-0.1 basso; 0.1-2.1 equilibrato; 2.1-5.1 alto; >5.1 molto alto.
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

#' K/CSC ratio assessment (Fert_Office foglio Gri_K)
#' <0.1% basso; 0.1-2.1 ottimale; 2.1-5.1 alto; ... (percentage of CSC)
#' @param k_meq_per_100g K in meq/100g.
#' @param csc_meq CSC in meq/100g.
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
