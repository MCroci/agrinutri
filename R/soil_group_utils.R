#' Normalise a soil-group label across the three agrinutri conventions
#'
#' agrinutri tables use three parallel naming conventions for the DPI 2026
#' texture grouping:
#'
#' \itemize{
#'   \item English (legacy agrinutri 0.1.0): "Sandy textures",
#'         "Loamy textures", "Clay textures".
#'   \item Italian plural (canonical DPI; foglio B, SO, Gri_K):
#'         "Sabbiosi", "Medio impasto", "Argillosi e limosi".
#'   \item Italian singular adjective (foglio Ragg_Tes):
#'         "Sabbioso", "Franco", "Argilloso".
#' }
#'
#' This helper accepts any of these forms (case-insensitive) and returns the
#' canonical English form (used by agrinutri >= 0.4.0 lookup tables) plus the
#' universal `ID_Rag` integer key used internally to join the lookup tables.
#'
#' @param x Character string. Soil group name in any supported convention.
#' @return A list with `id_rag` (1 = Sandy, 2 = Loamy, 3 = Clay), `en`
#'   (canonical English), `it_plural`, `it_singular`.
#' @examples
#' normalise_soil_group("Loamy textures")
#' normalise_soil_group("Medio impasto")
#' normalise_soil_group("Franco")
#' @export
normalise_soil_group <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    stop("`x` must be a single non-NA character.")
  }
  s <- tolower(trimws(x))
  if (s %in% c("sabbiosi","sabbioso","sandy textures","sandy","sabbiose","sandyloam","s")) {
    return(list(id_rag = 1L, it_plural = "Sabbiosi",
                it_singular = "Sabbioso", en = "Sandy textures"))
  }
  if (s %in% c("medio impasto","franco","loamy textures","loamy","franchi","mi","mediano","mi impasto","loam","f")) {
    return(list(id_rag = 2L, it_plural = "Medio impasto",
                it_singular = "Franco", en = "Loamy textures"))
  }
  if (s %in% c("argillosi e limosi","argillosi","argilloso","clay textures","clay","clayey","argillose","a")) {
    return(list(id_rag = 3L, it_plural = "Argillosi e limosi",
                it_singular = "Argilloso", en = "Clay textures"))
  }
  stop(sprintf("Unrecognised soil group label: '%s'. Accepted: %s",
               x, "Sabbiosi/Medio impasto/Argillosi e limosi (or English/singular forms)."))
}

#' @noRd
.texture_group_weight_col <- function(depth_cm, texture_groups.table) {
  c1 <- paste0("soil_weight_", depth_cm, "cm")
  c2 <- paste0("peso_", depth_cm, "cm")
  if (c1 %in% names(texture_groups.table)) return(c1)
  if (c2 %in% names(texture_groups.table)) return(c2)
  stop(sprintf(
    "No soil weight column for depth %s cm (expected '%s' or '%s') in texture_groups.table.",
    depth_cm, c1, c2
  ))
}

#' Resolve a numeric ID_Rag from any soil-group label or clay/sand %
#'
#' Convenience wrapper that returns the integer 1/2/3 for any soil group
#' text (Italian plural, singular or English) or, alternatively, derives it
#' from clay and sand percentages via `calc_soil_group_and_id_rag()`.
#'
#' @param soil_group Character (any convention) or NULL.
#' @param clay,sand Numeric percentages, used only if `soil_group` is NULL.
#' @return Integer ID_Rag (1/2/3).
#' @examples
#' resolve_id_rag("Loamy textures")
#' resolve_id_rag(clay = 18.5, sand = 15.5)
#' @export
resolve_id_rag <- function(soil_group = NULL, clay = NULL, sand = NULL) {
  if (!is.null(soil_group)) {
    return(normalise_soil_group(soil_group)$id_rag)
  }
  if (is.null(clay) || is.null(sand)) {
    stop("Provide either `soil_group` or both `clay` and `sand`.")
  }
  sp <- calc_soil_group_and_id_rag(clay = clay, sand = sand)
  as.integer(sp$id_rag)
}
