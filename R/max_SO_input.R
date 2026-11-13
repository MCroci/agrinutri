#' Maximum annual organic matter input (t dry matter / ha)
#'
#' Returns the DPI 2026 maximum annual input of soil organic matter (SO) as
#' dry matter t/ha, based on the classification of initial SO in soil:
#' "Poor" = 13, "Normal" = 11, "Rich" = 9 (Fert_Office v1.26 foglio SO).
#'
#' @param so_class One of `"Poor"`, `"Normal"`, `"Rich"` (case-insensitive).
#' @param so_max_input Lookup table (default `agrinutri::so_max_input`).
#' @return Numeric t dry matter / ha.
#' @examples max_SO_input("Normal")
#' @export
max_SO_input <- function(so_class = c("Poor", "Normal", "Rich"),
                         so_max_input = agrinutri_data_get("so_max_input")) {
  choices <- c("Poor", "Normal", "Rich")
  if (length(so_class) == 1L && !is.na(so_class) && !so_class %in% choices) {
    i <- match(tolower(so_class), tolower(choices))
    if (!is.na(i)) so_class <- choices[i]
  }
  so_class <- match.arg(so_class, choices)
  v <- so_max_input$max_t_dm_ha[so_max_input$`class` == so_class]
  as.numeric(v[1])
}

#' Classify SO (soil organic matter) initial content by texture group
#'
#' Returns DPI 2026 SO class (molto bassa / bassa / media / elevata) by
#' soil texture group (Sabbiosi / Medio impasto / Argillosi e limosi) and
#' maps to the 3-class scheme "Scarsa / Normale / Elevata" used for the
#' maximum annual SO input.
#'
#' @param SOM Soil organic matter (% mass).
#' @param soil_group Texture group (Italian).
#' @param so.table Lookup (default `agrinutri::so.table`).
#' @return List with `rating` (4 classes) and `class` (3-class for SO input).
#' @examples classify_SOM(SOM = 2, soil_group = "Medio impasto")
#' @export
classify_SOM <- function(SOM, soil_group, so.table = agrinutri_data_get("so.table")) {
  if (!is.numeric(SOM) || length(SOM) != 1 || is.na(SOM) || SOM < 0) {
    stop("`SOM` must be a non-negative numeric.")
  }
  # Thresholds from foglio B (agrinutri 0.1.0 already handles fertility; here we
  # just classify SO for the organic-input limit)
  th <- list(
    "Sandy textures" = c(0.8, 1.4, 2.0),
    "Loamy textures" = c(1.0, 1.8, 2.5),
    "Clay textures"  = c(1.2, 2.2, 3.0)
  )
  sg <- normalise_soil_group(soil_group)$en
  if (!(sg %in% names(th))) {
    stop(sprintf("Unknown soil_group '%s' (canonical: '%s').", soil_group, sg))
  }
  b <- th[[sg]]
  rating <- if (SOM < b[1]) "very low" else
    if (SOM < b[2]) "low" else
      if (SOM < b[3]) "medium" else "high"

  # Map 4-class rating to the 3-class scheme used for the SO input cap.
  # Rationale: "very low" and "low" both translate to Scarsa/Poor, "medium"
  # to Normale/Normal, and "high" to Elevata/Rich (Fert_Office v1.26 foglio SO).
  class_en <- switch(rating,
                     "very low" = "Poor",
                     "low"      = "Poor",
                     "medium"   = "Normal",
                     "high"     = "Rich",
                     NA_character_)
  class_it <- switch(class_en,
                     "Poor"   = "Scarsa",
                     "Normal" = "Normale",
                     "Rich"   = "Elevata",
                     NA_character_)
  list(rating      = rating,
       class       = class_en,
       class_it    = class_it,
       SOM         = SOM,
       soil_group  = sg)
} 