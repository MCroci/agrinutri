#' Compliance-aware variable-rate nitrogen prescription
#'
#' Generates a spatially explicit nitrogen prescription that combines the
#' regulatory cap from the Italian DPI nutrient balance (computed by
#' [N_balance()]) with the local economic optimum nitrogen rate (EONR) computed
#' by the QUEFTS crop model via **Rquefts**, redistributed across the field
#' according to Sentinel-2 nitrogen status (NNI) under a mass-balance constraint.
#'
#' @param field_inputs Named list of inputs accepted by [N_balance()] (e.g.
#'   `crop`, `ccp`, `expected_yield_tons_ha`, `sand`, `clay`, \dots). Extra
#'   elements are ignored.
#' @param NNI_raster A `terra::SpatRaster` of NNI values for the field. Cells
#'   with `NA` are excluded from the prescription.
#' @param crop_params Either `NULL` (use [nfert_to_quefts_crop()] on
#'   `field_inputs$crop`), a character string (same lookup), or a named list of
#'   QUEFTS crop parameters passed straight to [Rquefts::quefts()].
#' @param fertilizers `data.frame` with columns `name`, `N`, `P`, `K`, and
#'   `price_kg` (EUR per kg product). Defaults to `fertilizers_IT.csv` in
#'   `extdata`, or falls back to [Rquefts::fertilizers()] with a synthetic
#'   `price_kg` if needed for [Rquefts::fertApp()].
#' @param prices Named list with `p_y` = crop price (EUR/t dry matter). Used as
#'   `dm_crop_value` in [Rquefts::optApp()] after conversion to EUR/kg.
#' @param zvn Logical. If `TRUE`, apply a 170 kg N/ha cap on the **field-mean**
#'   applied dose (nitrate-vulnerable zone style territorial cap).
#' @param max_iter Integer. Maximum iterations for mass-balance projection.
#' @param tol Numeric. Convergence tolerance on mean N (kg N/ha).
#'
#' @return A list with:
#' \describe{
#'   \item{N_prescription}{`SpatRaster` of N rate (kg N/ha)}
#'   \item{P_prescription}{`SpatRaster` of P2O5 rate (kg/ha)}
#'   \item{K_prescription}{`SpatRaster` of K2O rate (kg/ha)}
#'   \item{fertilizer_mix}{`data.frame` from [Rquefts::fertApp()] (may have
#'     one row per cell, depending on Rquefts version), or empty `data.frame` on
#'     failure}
#'   \item{economics}{list: `mean_dose`, `p_y`, optional `note`}
#'   \item{compliance}{list: DPI cap, MAS, ZVN flags, mass-balance check}
#' }
#'
#' @details
#' Four layers:
#' \enumerate{
#'   \item **Compliance:** `N_balance()` DPI dose; cap with [get_MAS()] and
#'     optional ZVN field-mean 170 kg N/ha.
#'   \item **Spatial:** NNI drives relative deficit weights (lower NNI, higher N share).
#'   \item **Economic:** [Rquefts::optApp()] per cell on QUEFTS with soil N supply
#'     from balance component B.
#'   \item **Operational:** [Rquefts::fertApp()] for a cost-optimal mix (optional;
#'     requires valid `price_kg` and compatible fertilizer table).
#' }
#'
#' Requires suggested packages **Rquefts**, **terra**, and **limSolve**
#' (via Rquefts for LP).
#'
#' @examples
#' \dontrun{
#' fld <- list(
#'   crop = "Grano duro (granella)",
#'   expected_yield_tons_ha = 6,
#'   ccp = "Spring-summer crop 100-130 days",
#'   sand = 15.5, clay = 18.5, Ntot = 1.5, SOM = 2.0, CN = 7.73,
#'   oxygen_availability = "Slow",
#'   winter_rain = 150, start_spring_rain = 0,
#'   prev_crop = "Winter cereals straw removal",
#'   source = "Cattle slurry", fertorg_frequency = "every year",
#'   location = "Isolated plain",
#'   forg_quantity = 0, organic_previous_year_N = 0, E_to_D = TRUE
#' )
#' r <- terra::rast(nrows = 5, ncols = 5, xmin = 0, xmax = 50, ymin = 0, ymax = 50,
#'                  crs = "EPSG:32632", vals = runif(25, 0.7, 1.05))
#' out <- optimize_VR_DPI(field_inputs = fld, NNI_raster = r, prices = list(p_y = 280))
#' terra::plot(out$N_prescription)
#' }
#'
#' @export
optimize_VR_DPI <- function(field_inputs,
                            NNI_raster,
                            crop_params = NULL,
                            fertilizers = NULL,
                            prices = list(p_y = 280),
                            zvn = TRUE,
                            max_iter = 200L,
                            tol = 0.01) {
  if (!requireNamespace("Rquefts", quietly = TRUE)) {
    stop(
      "Package 'Rquefts' is required. Install with install.packages('Rquefts').",
      call. = FALSE
    )
  }
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop(
      "Package 'terra' is required for optimize_VR_DPI().",
      call. = FALSE
    )
  }

  # --- N balance (field-level compliance) ---------------------------------
  fmn <- names(formals(N_balance))
  fi <- field_inputs[names(field_inputs) %in% fmn]
  bal <- do.call(N_balance, fi)
  bal <- bal[1L, , drop = FALSE]

  # Explicit column references (not with(bal, ...)) so codetools does not flag
  # the balance terms as undefined globals (R CMD check "no visible binding").
  N_tot_DPI <- bal$A - bal$B + bal$C1 + bal$C2 + bal$D -
    bal$E - bal$F - bal$Forg - bal$G

  mas_row <- get_MAS(field_inputs$crop)
  if (is.null(mas_row) || nrow(mas_row) == 0L || is.na(mas_row$mas_N[1])) {
    warning(
      "MAS not found for this crop; using no MAS limit (Inf).",
      call. = FALSE
    )
    N_MAS <- Inf
  } else {
    N_MAS <- as.numeric(mas_row$mas_N[1])
  }

  zvn_cap <- if (isTRUE(zvn)) 170 else Inf
  N_tot_field <- min(N_tot_DPI, N_MAS, zvn_cap, na.rm = TRUE)

  # --- NNI raster → weights (low NNI = higher N share) -------------------
  nni_vals <- terra::values(NNI_raster, mat = FALSE)
  if (is.matrix(nni_vals)) nni_vals <- nni_vals[, 1L]

  valid <- is.finite(nni_vals)
  n_cells <- sum(valid)
  if (n_cells < 1L) {
    stop("No finite NNI cells in NNI_raster.", call. = FALSE)
  }

  nni_v <- nni_vals[valid]
  rng <- range(nni_v, na.rm = TRUE)
  denom <- diff(rng)
  if (!is.finite(denom) || denom < 1e-12) denom <- 1
  weights <- 1 - (nni_v - rng[1L]) / denom
  w_norm <- weights / mean(weights)

  # --- Fertilizer table ----------------------------------------------------
  if (is.null(fertilizers)) {
    f_path <- system.file("extdata", "fertilizers_IT.csv", package = "NFert")
    if (nzchar(f_path) && file.exists(f_path)) {
      fertilizers <- utils::read.csv(f_path, stringsAsFactors = FALSE)
    } else {
      fertilizers <- Rquefts::fertilizers()
      if (!"price_kg" %in% names(fertilizers)) {
        n0 <- suppressWarnings(as.numeric(fertilizers$N))
        n0[!is.finite(n0)] <- 0
        fertilizers$price_kg <- 0.4 + 0.002 * n0
      }
    }
  }
  if (!all(c("name", "N", "P", "K") %in% names(fertilizers))) {
    stop("fertilizers must contain columns name, N, P, K.", call. = FALSE)
  }
  if (!"price_kg" %in% names(fertilizers)) {
    stop("fertilizers must contain price_kg (EUR/kg) for fertApp().", call. = FALSE)
  }

  fert_opt <- fertilizers[, c("name", "N", "P", "K"), drop = FALSE]

  # --- QUEFTS crop & soil --------------------------------------------------
  if (is.null(crop_params)) {
    crop_pars <- nfert_to_quefts_crop(field_inputs$crop)
  } else if (is.list(crop_params) && "Yzero" %in% names(crop_params)) {
    crop_pars <- crop_params
  } else {
    crop_pars <- nfert_to_quefts_crop(as.character(crop_params)[1L])
  }

  soil_pars <- nfert_to_quefts_soil(as.numeric(bal$B))

  p_y <- if (!is.null(prices$p_y)) as.numeric(prices$p_y)[1L] else 280
  dm_crop_value <- p_y / 1000

  # --- Per-cell EONR -------------------------------------------------------
  eonr <- matrix(NA_real_, nrow = n_cells, ncol = 3L,
                 dimnames = list(NULL, c("N", "P", "K")))

  # The QUEFTS economic optimisation (Rquefts::optApp, an LP solved via limSolve)
  # can fail for an individual cell when the NNI-scaled attainable biomass drives
  # the solver into a degenerate or infeasible state. A single bad cell must not
  # abort the whole field prescription, so each cell is evaluated defensively and
  # left as NA on failure (mirroring the tryCatch already used for fertApp()).
  for (i in seq_len(n_cells)) {
    cell <- tryCatch({
      biom_i <- nfert_to_quefts_biom(
        field_inputs$expected_yield_tons_ha,
        nni_v[i],
        crop_pars
      )
      qm <- Rquefts::quefts(
        soil_pars,
        crop_pars,
        list(N = 0, P = 0, K = 0),
        biom_i
      )
      res <- Rquefts::optApp(
        qm,
        fertilizers = fert_opt,
        dm_crop_value = dm_crop_value
      )
      c(
        N = as.numeric(res$N)[1L] * 100,
        P = as.numeric(res$P)[1L] * 100,
        K = as.numeric(res$K)[1L] * 100
      )
    }, error = function(e) c(N = NA_real_, P = NA_real_, K = NA_real_))
    eonr[i, ] <- cell
  }

  N_cap_cell <- pmin(N_tot_field * w_norm, N_MAS)

  # Cells whose economic optimum could not be computed fall back to the
  # regulatory balance cap, so the prescription stays complete and mass-balanced
  # even when the optional QUEFTS optimiser misbehaves on some cells/platforms.
  failed <- !is.finite(eonr[, "N"])
  if (any(failed)) {
    warning(sprintf(
      paste0("optimize_VR_DPI(): QUEFTS economic optimisation failed for %d of ",
             "%d cell(s); using the DPI balance cap for those cell(s)."),
      sum(failed), n_cells
    ), call. = FALSE)
    eonr[failed, "N"] <- N_cap_cell[failed]
  }

  N_cell <- pmin(eonr[, "N"], N_cap_cell)

  # --- Mass-balance projection on field mean ------------------------------
  for (.iter in seq_len(max_iter)) {
    delta <- N_tot_field - mean(N_cell)
    if (abs(delta) < tol) break
    step <- delta * w_norm * min(1, 0.8 / max(w_norm))
    N_cell <- pmax(0, pmin(N_cell + step, pmin(N_MAS, N_cap_cell)))
  }

  # --- fertApp (optional) --------------------------------------------------
  nutrients <- data.frame(
    N = N_cell,
    P = eonr[, "P"],
    K = eonr[, "K"],
    stringsAsFactors = FALSE
  )
  mix <- tryCatch(
    Rquefts::fertApp(
      nutrients = nutrients,
      fertilizers = fertilizers[, c("name", "N", "P", "K"), drop = FALSE],
      price = fertilizers$price_kg,
      exact = FALSE
    ),
    error = function(e) {
      warning("fertApp(): ", conditionMessage(e), call. = FALSE)
      data.frame()
    }
  )

  # --- Rasters (P, K as oxide for agronomic reporting) --------------------
  P2O5_cell <- eonr[, "P"] * 2.291
  K2O_cell  <- eonr[, "K"] * 1.205

  .fill_rst <- function(template, idx_logical, vals) {
    r <- terra::rast(template)
    vv <- terra::values(r, mat = FALSE)
    if (is.matrix(vv)) vv <- vv[, 1L]
    vv[] <- NA_real_
    vv[idx_logical] <- vals
    terra::values(r) <- vv
    r
  }

  N_rast <- .fill_rst(NNI_raster, valid, N_cell)
  names(N_rast) <- "N_kg_ha"
  P_rast <- .fill_rst(NNI_raster, valid, P2O5_cell)
  names(P_rast) <- "P2O5_kg_ha"
  K_rast <- .fill_rst(NNI_raster, valid, K2O_cell)
  names(K_rast) <- "K2O_kg_ha"

  list(
    N_prescription = N_rast,
    P_prescription = P_rast,
    K_prescription = K_rast,
    fertilizer_mix = mix,
    economics = list(
      mean_dose    = mean(N_cell),
      p_y          = p_y,
      dm_eur_per_kg = dm_crop_value
    ),
    compliance = list(
      DPI_cap_kg_ha   = N_tot_DPI,
      MAS_kg_ha       = if (is.finite(N_MAS)) N_MAS else NA_real_,
      ZVN_active      = isTRUE(zvn),
      ZVN_cap_kg_ha   = if (isTRUE(zvn)) 170 else NA_real_,
      applied_cap_kg_ha = N_tot_field,
      mass_balance_ok = abs(mean(N_cell) - N_tot_field) < max(tol, 0.05),
      max_cell_N      = max(N_cell),
      mean_field_N    = mean(N_cell)
    )
  )
}
