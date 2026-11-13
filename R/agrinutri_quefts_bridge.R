#' Translate agrinutri inputs into QUEFTS soil parameters
#'
#' Builds the soil parameter list expected by [Rquefts::quefts()] from the
#' soil logic already reflected in [N_balance()]. The conversion is
#' deterministic and does not require additional measurements.
#'
#' @param N_supply Numeric. Plant-available N supply (kg N/ha) over the season.
#'   Typically the `B` component returned by [N_balance()]
#'   (sum of b1 readily available N and b2 SOM mineralisation).
#' @param P_supply Numeric. Plant-available P supply (kg P/ha). If unknown,
#'   defaults to 10 (representative for Italian arable soils with Olsen P
#'   in the 15--25 mg/kg range).
#' @param K_supply Numeric. Plant-available K supply (kg K/ha). Default 60.
#' @param N_recovery Numeric. Apparent N recovery efficiency (fraction).
#'   Default 0.55, typical for cereals on medium-textured soils.
#' @param P_recovery Numeric. Apparent P recovery efficiency. Default 0.10.
#' @param K_recovery Numeric. Apparent K recovery efficiency. Default 0.50.
#'
#' @return A named list ready to be passed to [Rquefts::quefts()] as the
#'   `soil` argument.
#'
#' @details
#' QUEFTS uses native nutrient supplies and recovery fractions of applied
#' fertiliser to build a per-cycle balance. Default recovery values follow
#' QUEFTS applications for European cereal systems (Janssen et al., 1990;
#' Sattari et al., 2014).
#'
#' The `UptakeAdjust` matrix matches the default in [Rquefts::quefts_soil()].
#'
#' @references
#' Janssen, B.H. et al. (1990). Geoderma 46, 299-318.
#' Sattari, S.Z. et al. (2014). Eur. J. Agron. 60, 79-90.
#'
#' @export
agrinutri_to_quefts_soil <- function(N_supply, P_supply = 10, K_supply = 60,
                                 N_recovery = 0.55, P_recovery = 0.10,
                                 K_recovery = 0.50) {
  list(
    N_base_supply = as.numeric(N_supply),
    P_base_supply = as.numeric(P_supply),
    K_base_supply = as.numeric(K_supply),
    N_recovery = as.numeric(N_recovery),
    P_recovery = as.numeric(P_recovery),
    K_recovery = as.numeric(K_recovery),
    UptakeAdjust = matrix(c(
      0, 0.0,
      40, 0.4,
      80, 0.7,
      120, 1.0,
      240, 1.6,
      360, 2.0,
      1000, 2.0
    ), ncol = 2L, byrow = TRUE)
  )
}

#' Translate agrinutri crop name into QUEFTS crop parameters
#'
#' Looks up QUEFTS crop parameters in the bundled `quefts_crop_pars_IT.csv`
#' table. Crop names follow agrinutri / English DPI-style labels
#' (e.g. `"Durum wheat (whole plant)"`, `"Grano duro (granella)"`).
#'
#' @param crop Character. Crop name as accepted by [N_balance()].
#' @param crop_pars_path Character. Optional path to a custom CSV. If
#'   `NULL`, the bundled file under `inst/extdata` is used.
#'
#' @return A named list with elements suitable for [Rquefts::quefts()] as the
#'   `crop` argument (`NminVeg`, `NmaxVeg`, `NminStore`, \dots, `SeasonLength`).
#'
#' @export
agrinutri_to_quefts_crop <- function(crop, crop_pars_path = NULL) {
  if (is.null(crop_pars_path)) {
    crop_pars_path <- system.file(
      "extdata", "quefts_crop_pars_IT.csv",
      package = "agrinutri"
    )
  }
  if (!nzchar(crop_pars_path) || !file.exists(crop_pars_path)) {
    stop(
      "Crop parameters file not found: ",
      crop_pars_path,
      call. = FALSE
    )
  }
  tab <- utils::read.csv(crop_pars_path, stringsAsFactors = FALSE, check.names = FALSE)
  crop <- as.character(crop)[1L]

  hit <- tab[tolower(trimws(tab$crop)) == tolower(trimws(crop)), , drop = FALSE]
  if (nrow(hit) == 0L) {
    hit <- tab[vapply(seq_len(nrow(tab)), function(i) {
      ci <- tolower(trimws(tab$crop[i]))
      cr <- tolower(trimws(crop))
      grepl(ci, cr, fixed = TRUE) || grepl(cr, ci, fixed = TRUE)
    }, logical(1)), , drop = FALSE]
    if (nrow(hit) > 1L) hit <- hit[1L, , drop = FALSE]
  }
  if (nrow(hit) == 0L) {
    stop(
      "Crop '", crop, "' not found in QUEFTS calibration table (",
      basename(crop_pars_path), "). Available crops: ",
      paste(unique(tab$crop), collapse = ", "),
      call. = FALSE
    )
  }

  list(
    NminVeg = hit$NminVeg,
    NmaxVeg = hit$NmaxVeg,
    NminStore = hit$NminStore,
    NmaxStore = hit$NmaxStore,
    PminVeg = hit$PminVeg,
    PmaxVeg = hit$PmaxVeg,
    PminStore = hit$PminStore,
    PmaxStore = hit$PmaxStore,
    KminVeg = hit$KminVeg,
    KmaxVeg = hit$KmaxVeg,
    KminStore = hit$KminStore,
    KmaxStore = hit$KmaxStore,
    Yzero = hit$Yzero,
    Nfix = hit$Nfix,
    SeasonLength = hit$SeasonLength
  )
}

#' Build QUEFTS biomass list from agrinutri state and Sentinel-2 NNI
#'
#' Translates expected yield and per-pixel NNI into QUEFTS attainable biomass
#' partitioning. NNI scales attainable storage biomass between a stressed and
#' near-potential state.
#'
#' @param expected_yield_tons_ha Numeric. Expected attainable yield (t/ha).
#' @param NNI Numeric vector or scalar. Nitrogen Nutrition Index (typical range
#'   near 0.5--1.1).
#' @param crop_pars Named list returned by [agrinutri_to_quefts_crop()].
#' @param leaf_to_store_ratio Numeric. Leaf:store DM ratio for cereals. Default
#'   0.42.
#'
#' @return If `NNI` has length 1, a single list with `leaf_att`, `stem_att`,
#'   `store_att`, `SeasonLength`. If `NNI` has length > 1, a list of such lists
#'   (one per element).
#'
#' @export
agrinutri_to_quefts_biom <- function(expected_yield_tons_ha, NNI, crop_pars,
                                 leaf_to_store_ratio = 0.42) {
  Y_pot_kg <- as.numeric(expected_yield_tons_ha) * 1000
  NNI_clamped <- pmin(pmax(NNI, 0.30), 1.10)
  store <- Y_pot_kg * NNI_clamped
  leaf <- store * leaf_to_store_ratio
  stem <- store * leaf_to_store_ratio
  sl <- crop_pars$SeasonLength

  if (length(NNI) == 1L) {
    list(
      leaf_att = leaf,
      stem_att = stem,
      store_att = store,
      SeasonLength = sl
    )
  } else {
    Map(function(le, st, sa) {
      list(
        leaf_att = le, stem_att = st, store_att = sa,
        SeasonLength = sl
      )
    }, leaf, stem, store)
  }
}
