#' Map agrinutri crop label to QUEFTS crop parameters (backward-compatible)
#'
#' Returns parameters for [Rquefts::quefts()]. If `crop_params` is already a
#' full QUEFTS crop list, it is returned unchanged. Otherwise this function
#' calls [agrinutri_to_quefts_crop()] using `inst/extdata/quefts_crop_pars_IT.csv`.
#' If the crop is missing from that table, it falls back to
#' [Rquefts::quefts_crop()] with a coarse heuristic (requires **Rquefts**).
#'
#' @param crop_params Character crop description (e.g. from [N_balance()]) or a
#'   named list of QUEFTS crop parameters.
#'
#' @return List compatible with `Rquefts::quefts(..., crop = crop_pars)`.
#' @seealso [agrinutri_to_quefts_crop()]
#' @export
agrinutri_crop_pars_quefts <- function(crop_params) {
  if (is.list(crop_params) && !is.null(names(crop_params)) &&
      "Yzero" %in% names(crop_params)) {
    return(crop_params)
  }
  label <- as.character(crop_params)[1]
  tryCatch(
    agrinutri_to_quefts_crop(label),
    error = function(e) {
      if (!requireNamespace("Rquefts", quietly = TRUE)) stop(e)
      warning(
        "agrinutri_to_quefts_crop('", label, "') failed (",
        conditionMessage(e),
        "); using Rquefts::quefts_crop() fallback.",
        call. = FALSE
      )
      .agrinutri_crop_fallback_quefts(label)
    }
  )
}

.agrinutri_crop_fallback_quefts <- function(label) {
  nm <- tolower(trimws(gsub("\\s*\\(.*$", "", label)))
  rquefts_name <- if (grepl("orzo|barley", nm)) {
    "Barley"
  } else if (grepl("durum|duro|wheat|grano|frumento", nm)) {
    "Wheat"
  } else if (grepl("mais|maize|corn", nm)) {
    "Maize"
  } else if (grepl("riso|rice", nm)) {
    "Rice"
  } else if (grepl("soy|soia", nm)) {
    "Soyabean"
  } else if (grepl("patata|potato", nm)) {
    "Potato"
  } else {
    "Wheat"
  }
  Rquefts::quefts_crop(rquefts_name)
}
