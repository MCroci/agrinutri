#' Scheda a dose Standard - Nitrogen (DPI Emilia-Romagna 2026)
#'
#' Implements the DPI 2026 simplified "Scheda a dose Standard" method for nitrogen,
#' as coded in Fert_Office v1.26 sheet `Scheda_N`. Starts from a crop-specific
#' standard base dose (from `mas.table$standard_N`) and applies user-selected
#' decrement and increment factors. The final dose is then capped at MAS
#' (maximum allowed dose) from DPI 2026 Allegato 9 / Reg. reg. 2/2024.
#'
#' The decrement/increment catalogue (with default values in kg/ha) is:
#'
#' | Direction   | Factor                                           | Default kg/ha |
#' |-------------|--------------------------------------------------|---------------|
#' | Decremento  | Resa bassa (< 5 t/ha)                            | user-defined  |
#' | Decremento  | Ammendante nell'anno precedente                  | user-defined  |
#' | Decremento  | Tenore SO nel suolo elevato                      | user-defined  |
#' | Decremento  | Dopo medica o prato > 5 anni                     | 60            |
#' | Decremento  | Dopo una leguminosa                              | 30            |
#' | Incremento  | Resa alta (> 7 t/ha)                             | user-defined  |
#' | Incremento  | Tenore SO nel suolo basso                        | user-defined  |
#' | Incremento  | Ristoppio o interramento paglie                  | 30            |
#' | Incremento  | Lisciviazione x surplus pluviometrico            | user-defined  |
#' | Incremento  | Terreno compattato o semina su sodo              | 10            |
#'
#' @param crop Crop name exactly as in `agrinutri::mas.table$crop`.
#' @param phase Optional phase string (e.g. "Primaverile-estiva 100-130 gg") for crops
#'   with multiple fases. If `NULL` (default) and the crop has multiple rows, the
#'   first match is used and a note is emitted.
#' @param decrements Named numeric vector (kg/ha) with one or more of:
#'   `yield_low`, `prev_amendant`, `high_SOM`, `after_alfalfa_meadow`, `after_legume`.
#'   Missing names default to 0. Values are treated as positive and subtracted.
#' @param increments Named numeric vector (kg/ha) with one or more of:
#'   `yield_high`, `low_SOM`, `straw_burial`, `rain_surplus`, `compacted_no_till`.
#'   Missing names default to 0.
#' @param mas.table Reference MAS lookup (default `agrinutri::mas.table`).
#' @param apply_mas_cap Logical, default `TRUE`. Cap the final dose at
#'   `max_N_dose = standard_N + max_increment` from MAS.
#'
#' @return A named list with components:
#'   - `dose_base`: standard dose from MAS (kg N/ha)
#'   - `total_decrement`, `total_increment`
#'   - `dose_recalculated`: dose after increments/decrements
#'   - `max_N_dose`: DPI 2026 cap
#'   - `dose_final`: min(dose_recalculated, max_N_dose) if `apply_mas_cap = TRUE`
#'   - `mas_exceeded`: logical
#'
#' @examples
#' # Grano duro pianta intera, fase primaverile-estiva 100-130 gg
#' scheda_N(crop = "Grano duro (pianta intera)",
#'          decrements = c(after_alfalfa_meadow = 60),
#'          increments = c(straw_burial = 30,
#'                         compacted_no_till = 10))
#' @export
dose_standard_N <- function(crop,
                     phase = NULL,
                     decrements = numeric(),
                     increments = numeric(),
                     mas.table = agrinutri_data_get("mas.table"),
                     apply_mas_cap = TRUE) {

  if (missing(crop) || !is.character(crop) || length(crop) != 1) {
    stop("`crop` must be a single crop name string.")
  }

  # Accept Italian or English crop name
  crop <- resolve_crop(crop, table = mas.table)

  # Lookup crop row(s)
  idx <- which(mas.table$crop == crop)
  if (length(idx) == 0) {
    stop(sprintf("Crop '%s' not found in mas.table.", crop))
  }
  if (!is.null(phase)) {
    idx_p <- which(.agrinutri_ascii_fold(mas.table$crop) == .agrinutri_ascii_fold(crop) &
                     .agrinutri_ascii_fold(mas.table$phase) == .agrinutri_ascii_fold(phase))
    if (length(idx_p) == 0) {
      warning(sprintf("Phase '%s' not found for crop '%s'. Using first available row.", phase, crop))
    } else {
      idx <- idx_p
    }
  }
  if (length(idx) > 1) {
    message(sprintf("Crop '%s' has %d matching rows; using the first.", crop, length(idx)))
    idx <- idx[1]
  }

  row <- mas.table[idx, , drop = FALSE]
  dose_base <- suppressWarnings(as.numeric(row$standard_N))
  dose_max  <- suppressWarnings(as.numeric(row$max_N_dose))
  if (is.na(dose_base)) {
    stop(sprintf("No standard N dose (standard_N) available for crop '%s' in mas.table.", crop))
  }

  # ---- Decrementi ----
  dec_defaults <- c(yield_low = 0, prev_amendant = 0, high_SOM = 0,
                    after_alfalfa_meadow = 60, after_legume = 30)
  # Only apply defaults if the user passed a *logical* TRUE; if numeric, use the numeric
  dec_total <- 0
  for (nm in names(dec_defaults)) {
    v <- if (length(decrements) && !is.null(names(decrements)) && nm %in% names(decrements)) {
      decrements[[nm]]
    } else {
      NULL
    }
    if (is.null(v)) next
    if (is.logical(v)) {
      if (isTRUE(v)) dec_total <- dec_total + dec_defaults[[nm]]
    } else if (is.numeric(v)) {
      dec_total <- dec_total + abs(v)
    }
  }

  # ---- Incrementi ----
  inc_defaults <- c(yield_high = 0, low_SOM = 0, straw_burial = 30,
                    rain_surplus = 0, compacted_no_till = 10)
  inc_total <- 0
  for (nm in names(inc_defaults)) {
    v <- if (length(increments) && !is.null(names(increments)) && nm %in% names(increments)) {
      increments[[nm]]
    } else {
      NULL
    }
    if (is.null(v)) next
    if (is.logical(v)) {
      if (isTRUE(v)) inc_total <- inc_total + inc_defaults[[nm]]
    } else if (is.numeric(v)) {
      inc_total <- inc_total + abs(v)
    }
  }

  dose_recalc <- dose_base + inc_total - dec_total
  dose_recalc <- max(0, dose_recalc)

  exceeded <- FALSE
  dose_final <- dose_recalc
  if (isTRUE(apply_mas_cap) && !is.na(dose_max)) {
    if (dose_recalc > dose_max) {
      exceeded <- TRUE
      dose_final <- dose_max
    }
  }

  list(
    crop = crop,
    phase = if (!is.null(phase)) phase else row$phase[[1]],
    dose_base = dose_base,
    total_decrement = dec_total,
    total_increment = inc_total,
    dose_recalculated = dose_recalc,
    max_N_dose = dose_max,
    dose_final = dose_final,
    mas_exceeded = exceeded,
    units = "kg N/ha",
    reference = "DPI Emilia-Romagna 2026, Fert_Office v1.26 (Scheda_N)"
  )
}

#' @rdname dose_standard_N
#' @param ... Passed to \code{dose_standard_N()}.
#' @export
scheda_N <- function(...) dose_standard_N(...)
