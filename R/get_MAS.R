#' Maximum Allowed Doses (MAS) per DPI Emilia-Romagna
#'
#' Returns or checks the Maximum Allowed Doses (Massimali Ammessi dal DPI, MAS)
#' of nitrogen for a crop, as defined in the Disciplinari di Produzione
#' Integrata (DPI) Emilia-Romagna (Allegato 9, Reg. reg. 2/2024). In ZVN the
#' values are binding; they can be exceeded if production over 3 years exceeds
#' the reference yield.
#'
#' The DPI 2026 values (default) are read from the bundled [mas.table]
#' dataset, which mirrors the "MAS" sheet of Fert_Office v1.26 (239 crops).
#'
#' @param crop Character. Crop name, in English (canonical, as in
#'   `uptake_table$crop`) or Italian (Fert_Office label); matching is case- and
#'   accent-insensitive, and a few generic DPI names (e.g. `"Mais da
#'   insilato"`, `"Frumento tenero (granella)"`) are mapped to the
#'   corresponding table row. Use `get_MAS()` to list all crops.
#' @param mas_table Optional data frame with at least columns `crop` and
#'   `mas_N` (and optionally `crop_it`, `crop_en`). If NULL, uses the built-in
#'   table for the chosen `edition`.
#' @param edition Character. `"2026"` (default; DPI 2026 / Fert_Office v1.26,
#'   Reg. reg. 2/2024) or `"2025"` (Guida DPI 2025, ZVN table, 17 crops).
#'
#' @return For `get_MAS(crop)`: a one-row data frame with columns `crop`,
#'   `crop_it`, `crop_en`, `phase`, `mas_N` (kg N/ha; `NA` when the DPI sets
#'   no MAS), `reference_yield` (t/ha), `max_theoretical_N`, `standard_N`,
#'   `max_N_dose` and `note` (edition 2026), or all rows if `crop` is NULL.
#'   For `check_MAS`: a list with `ok` (logical), `mas_N`, `N_planned`,
#'   `message`.
#'
#' @references
#' DPI Emilia-Romagna - Norme Generali 2025, Allegato 9; Guida alla
#' Fertilizzazione Minerale e Organica 2025 (N, P, K). Reg. reg. 2/2024.
#' DPI 2026, FertDPI / Fert_Office_v1_26.
#'
#' @export
#' @examples
#' get_MAS("Grano duro (granella)")
#' get_MAS("Silage maize (class 700)")$mas_N
#' get_MAS("Frumento tenero (granella)", edition = "2025")  # ZVN 2025
#' head(get_MAS())  # full table
#' check_MAS("Mais da granella", 250)
#' check_MAS("Grano duro (granella)", 210)  # over MAS
get_MAS <- function(crop = NULL, mas_table = NULL, edition = c("2026", "2025")) {
  edition <- match.arg(edition)
  if (is.null(mas_table)) mas_table <- if (edition == "2025") .mas_table_dpi2025() else .mas_table_dpi2026()
  if (is.null(crop)) return(mas_table)
  crop <- as.character(crop)
  # Legacy generic DPI names (e.g. "Mais da insilato") map to a table row
  amap <- c(.mas_crop_alias(), .crop_alias_to_canonical())
  ia <- match(tolower(.agrinutri_ascii_fold(trimws(crop))), tolower(names(amap)))
  if (!is.na(ia) && !(crop %in% mas_table$crop)) crop <- unname(amap[ia])
  # Accent-insensitive match on crop, then on the Italian / English aliases
  norm <- function(s) tolower(.agrinutri_ascii_fold(gsub("\\s+", " ", trimws(as.character(s)))))
  key <- norm(crop)
  i <- NA_integer_
  for (col in intersect(c("crop", "crop_it", "crop_en"), names(mas_table))) {
    j <- which(norm(mas_table[[col]]) == key)
    if (length(j) > 0) { i <- j[1]; break }
  }
  if (is.na(i)) {
    warning("Crop '", crop, "' not found in MAS table. Return NULL. Use get_MAS() to see available crops.")
    return(NULL)
  }
  mas_table[i, , drop = FALSE]
}

#' Check planned N against MAS
#'
#' Checks whether a planned nitrogen dose (kg/ha) exceeds the Maximum Allowed
#' Dose (MAS) for the crop. In ZVN, also consider the 170 kg N/ha/year limit
#' from livestock effluents.
#'
#' @param crop Character. Crop name (DPI nomenclature).
#' @param N_planned Numeric. Planned nitrogen dose (kg/ha).
#' @param mas_table Optional. Same as in `get_MAS`. Default uses built-in table.
#'
#' @param edition Character. `"2026"` or `"2025"`; used only if `mas_table` is NULL.
#' @return List with `ok` (TRUE if N_planned <= MAS or crop has no MAS_N),
#'   `mas_N`, `N_planned`, `message`.
#' @export
check_MAS <- function(crop, N_planned, mas_table = NULL, edition = c("2026", "2025")) {
  edition <- match.arg(edition)
  if (is.null(mas_table)) mas_table <- if (edition == "2025") .mas_table_dpi2025() else .mas_table_dpi2026()
  row <- get_MAS(crop, mas_table)
  if (is.null(row) || nrow(row) == 0L) {
    return(list(ok = NA, mas_N = NA, N_planned = N_planned,
                message = "Crop not found in MAS table; check not performed."))
  }
  mas_N <- row$mas_N
  if (is.na(mas_N)) {
    return(list(ok = TRUE, mas_N = NA, N_planned = N_planned,
                message = "No MAS N defined for this crop (e.g. soya)."))
  }
  ok <- N_planned <= mas_N
  msg <- if (ok) "Planned N is within MAS." else
    paste0("Planned N (", N_planned, " kg/ha) exceeds MAS (", mas_N, " kg/ha).")
  list(ok = ok, mas_N = mas_N, N_planned = N_planned, message = msg)
}

#' Built-in MAS table - DPI 2025 Guida (ZVN, resa riferimento)
#' Reg. reg. 2/2024, Allegato 9.
#' @noRd
.mas_table_dpi2025 <- function() {
  data.frame(
    crop = c(
      "Frumento tenero (granella)",
      "Grano tenero FF (granella)",
      "Frumento duro (granella)",
      "Grano duro (granella)",
      "Orzo",
      "Mais da granella",
      "Mais da insilato",
      "Shredded corn class 700",
      "Soia",
      "Barbabietola da zucchero",
      "Pomodoro da industria",
      "Patata",
      "Melo",
      "Pero",
      "Pesco e Nettarine",
      "Vite (uva da vino)",
      "Asparago verde"
    ),
    mas_N = c(180L, 180L, 190L, 190L, 150L, 280L, 280L, 280L, 30L, 160L, 180L, 190L, 120L, 120L, 175L, 100L, 210L),
    reference_yield = c(6.5, 6.5, 6.0, 6.0, 6.0, 13.0, 23.0, 23.0, NA_real_, 60.0, 80.0, 48.0, 35.0, 30.0, 25.0, 18.0, 7.0),
    type = c(
      "Erbacee", "Erbacee", "Erbacee", "Erbacee", "Erbacee", "Erbacee", "Erbacee", "Erbacee",
      "Erbacee", "Erbacee", "Orticole", "Orticole", "Arboree", "Arboree", "Arboree", "Arboree", "Orticole"
    ),
    stringsAsFactors = FALSE
  )
}

#' Built-in MAS table (DPI 2026 / FertDPI style)
#' @noRd
.mas_table_dpi2026 <- function() {
  # DPI 2026 MAS (Allegato 9, Reg. reg. 2/2024) as shipped in the bundled
  # `mas.table` dataset, which mirrors the "MAS" sheet of Fert_Office v1.26
  # (column "MAS", not the "teorico massimo" column).
  m <- agrinutri_data_get("mas.table")
  ref <- m$reference_yield_t_ha
  ref[!is.na(ref) & ref <= 0] <- NA_real_
  out <- data.frame(
    crop              = as.character(m$crop),
    crop_it           = as.character(m$crop_it),
    crop_en           = as.character(m$crop_en),
    phase             = as.character(m$phase),
    mas_N             = as.integer(m$MAS_N),
    reference_yield   = ref,
    max_theoretical_N = as.integer(m$max_theoretical_N),
    standard_N        = m$standard_N,
    max_N_dose        = m$max_N_dose,
    note              = as.character(m$note),
    stringsAsFactors  = FALSE
  )
  out[!duplicated(out$crop), , drop = FALSE]
}

# Generic DPI crop names used by earlier agrinutri releases and in the DPI text,
# mapped to the corresponding row of the DPI 2026 MAS table.
.mas_crop_alias <- function() {
  stats::setNames(
    c("Soft wheat FP/FPS (grain)", "Soft wheat FP/FPS (whole plant)",
      "Durum wheat (grain)", "Durum wheat (grain)",
      "Grain maize 500-700 (grain)", "Silage maize (class 700)",
      "Silage maize (class 700)", "Barley (grain)", "Sunflower (achenes)",
      "Soybean (grain)", "Sugar beet (roots)",
      "Processing tomato (medium yield)", "Apple - fruit, wood and leaves",
      "Pear (medium yield) - fruit, wood and leaves",
      "Peach - fruit, wood and leaves",
      "Vineyard (plain) - grapes, wood and leaves",
      "Kiwifruit (green flesh) - fruit, wood and leaves",
      "Cherry - fruit, wood and leaves"),
    c("Frumento tenero (granella)", "Frumento tenero (pianta intera)",
      "Frumento duro (granella)", "Grano duro",
      "Mais da granella", "Mais da insilato",
      "Shredded corn class 700", "Orzo", "Girasole",
      "Soia", "Barbabietola da zucchero",
      "Pomodoro da industria", "Melo",
      "Pero",
      "Pesco e Nettarine",
      "Vite (uva da vino)",
      "Actinidia",
      "Ciliegio")
  )
}
