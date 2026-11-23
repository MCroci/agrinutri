#' Organic nitrogen efficiency by material, soil texture and distribution (DPI)
#'
#' Returns the fraction of total organic N that is available to the crop in the
#' year of application, according to DPI (type of effluent, soil texture and
#' distribution technique). Used when \code{soil_group} and \code{distribution_efficiency}
#' are passed to \code{organic_fertilization()}.
#'
#' @param source Character. Organic fertilizer source (e.g. "Cattle slurry").
#' @param soil_group Character. Soil group from \code{calc_soil_group_and_id_rag()}
#'   (e.g. "Sandy textures", "Loamy textures", "Clay textures").
#' @param distribution_efficiency Character. "efficient", "medium", or "low".
#'   Efficient = injection, fertigation, incorporation within 4 h; medium = band
#'   spreading with incorporation; low = surface spreading without incorporation.
#'
#' @return Numeric. Efficiency as a fraction between 0 and 1, or `NA` if not found.
#'   For soil amendments (compost, mature manure, solid digestate) returns 0.40 (40%).
#'
#' @references
#' DPI Emilia-Romagna, fertilisation guide; FertDPI efficiency sheet.
#' Sandy/loamy/clay soil x efficient/medium/low-efficiency distribution.
#'
#' @export
#' @examples
#' organic_N_efficiency("Cattle slurry", "Sandy textures", "efficient")
#' organic_N_efficiency("Composted manure", "Loamy textures", "medium")  # 0.40
organic_N_efficiency <- function(source, soil_group, distribution_efficiency) {
  eff <- .organic_efficiency_table()
  soil_dpi <- .soil_group_to_dpi(soil_group)
  dist <- .normalize_distribution(distribution_efficiency)
  if (is.na(soil_dpi) || is.na(dist)) return(NA_real_)
  # Ammendanti: 40% fisso
  if (.is_ammendante(source)) return(0.40)
  idx <- eff$source == source & eff$soil_dpi == soil_dpi & eff$distribution == dist
  if (!any(idx)) return(NA_real_)
  eff$efficiency_pct[idx][1L] / 100
}

#' Normalize soil group name to DPI class (sabbioso, franco, argilloso)
#' @noRd
.soil_group_to_dpi <- function(soil_group) {
  if (is.null(soil_group) || is.na(soil_group)) return(NA_character_)
  s <- tolower(as.character(soil_group))
  if (grepl("sabb|sand", s)) return("sabbioso")
  if (grepl("argill|clay", s)) return("argilloso")
  return("franco")
}

#' Normalize distribution to efficient / medium / low
#' @noRd
.normalize_distribution <- function(x) {
  if (is.null(x) || is.na(x)) return(NA_character_)
  x <- tolower(as.character(x))
  if (x %in% c("efficient", "alta", "high")) return("efficient")
  if (x %in% c("medium", "media", "intermedia")) return("medium")
  if (x %in% c("low", "bassa", "poco efficiente")) return("low")
  NA_character_
}

#' Ammendanti: fixed 40% (letame maturo, compost, digestato palabile)
#' @noRd
.is_ammendante <- function(source) {
  s <- tolower(as.character(source))
  grepl("compost|letame maturo|ammendante|digestato palabile|palabile", s)
}

#' Efficiency table (DPI): source × soil_dpi × distribution -> efficiency_pct
#' Sources aligned with f.table where possible; DPI types for effluents.
#' @noRd
.organic_efficiency_table <- function() {
  # DPI: sabbioso / franco / argilloso × efficient / medium / low (Alta/Media/Bassa)
  # Values from DPI Guida / FertDPI Efficienza (approx.)
  sources <- c(
    "Liquame avicolo", "Liquame bovino", "Liquame suino",
    "Digestato tal quale bovini", "Digestato tal quale suini", "Digestato tal quale avicoli",
    "Digestato frazione chiarificata", "Fanghi agroalimentari",
    "Cattle slurry", "Pig slurry", "Digestato t.q. bovini", "Digestato t.q. suini"
  )
  soil_dpi <- rep(c("sabbioso", "franco", "argilloso"), each = 3L * 12L)
  dist <- rep(rep(c("efficient", "medium", "low"), each = 12L), 3L)
  # Efficiency %: rows (sabbioso efficient, sabbioso medium, sabbioso low, franco efficient, ...)
  # Liquame avicolo: 90.9, 65.6, 40.3 (sabbioso); 81.6, 59.8, 37.9 (franco); 72.4, 54.0, 35.6 (argilloso)
  # Liquame bovino:  67.1, 48.4, 29.8; 60.4, 44.2, 28.1; 53.6, 40.1, 26.5
  # Liquame suino:   79.0, 57.0, 35.0; 71.0, 52.0, 33.0; 63.0, 47.0, 31.0
  # Digestato t.q. same as liquame by origin; chiarificata like avicolo; fanghi like bovino
  pct_sandy <- c(
    90.9, 67.1, 79.0, 67.1, 79.0, 90.9, 90.9, 67.1, 67.1, 79.0, 67.1, 79.0,
    65.6, 48.4, 57.0, 48.4, 57.0, 65.6, 65.6, 48.4, 48.4, 57.0, 48.4, 57.0,
    40.3, 29.8, 35.0, 29.8, 35.0, 40.3, 40.3, 29.8, 29.8, 35.0, 29.8, 35.0
  )
  pct_franco <- c(
    81.6, 60.4, 71.0, 60.4, 71.0, 81.6, 81.6, 60.4, 60.4, 71.0, 60.4, 71.0,
    59.8, 44.2, 52.0, 44.2, 52.0, 59.8, 59.8, 44.2, 44.2, 52.0, 44.2, 52.0,
    37.9, 28.1, 33.0, 28.1, 33.0, 37.9, 37.9, 28.1, 28.1, 33.0, 28.1, 33.0
  )
  pct_clay <- c(
    72.4, 53.6, 63.0, 53.6, 63.0, 72.4, 72.4, 53.6, 53.6, 63.0, 53.6, 63.0,
    54.0, 40.1, 47.0, 40.1, 47.0, 54.0, 54.0, 40.1, 40.1, 47.0, 40.1, 47.0,
    35.6, 26.5, 31.0, 26.5, 31.0, 35.6, 35.6, 26.5, 26.5, 31.0, 26.5, 31.0
  )
  src_rep <- rep(sources, 9L)
  dist_rep <- rep(rep(c("efficient", "medium", "low"), each = 12L), 3L)
  soil_rep <- rep(c("sabbioso", "franco", "argilloso"), each = 36L)
  pct <- c(pct_sandy, pct_franco, pct_clay)
  data.frame(
    source = src_rep,
    soil_dpi = soil_rep,
    distribution = dist_rep,
    efficiency_pct = pct,
    stringsAsFactors = FALSE
  )
}
