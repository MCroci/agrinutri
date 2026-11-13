#' Variable-rate nitrogen from balance + NDVI
#'
#' Bridges the constant-rate output of `N_balance()` / `calculate_N_fertilization()`
#' or `scheda_N()` with the spatial NDVI-based variable-rate estimators of NFert
#' (`estimate_N_rate_from_calibration_curve()` and
#' `estimate_N_rate_from_holland_schepers()`).
#'
#' Two integration patterns are supported:
#'
#' 1. **Calibration curve** (`method = "calibration"`): the agronomic balance
#'    determines the *target field-average* dose; the function then derives a
#'    `minN`/`maxN` envelope around it (default +/- 25%) and applies the linear
#'    NDVI-driven calibration (low NDVI = more N, high NDVI = less N).
#' 2. **Holland & Schepers** (`method = "holland"`): the agronomic balance is
#'    used as the **base N rate** of the H&S sufficiency-index algorithm.
#'
#' The output preserves the field-average dose computed by the balance: the
#' raster of variable rates has a mean equal to the input `n_dose` (water-filling
#' rescaling within [0, `mas_cap`]), so the agronomic constraint (MAS, ZVN) is kept.
#'
#' @param ndvi_raster A `terra::SpatRaster` with NDVI (0--1); layer \code{NDVI}
#'   if present, otherwise the first layer. Legacy `raster` objects are accepted
#'   and converted with `terra::rast()`.
#' @param n_dose Numeric. Field-average N dose (kg/ha) from `N_balance()` +
#'   `calculate_N_fertilization()`, `scheda_N()$dose_final`, or any custom
#'   target.
#' @param method Either `"calibration"` (default, two-point linear) or
#'   `"holland"` (Holland & Schepers sufficiency index).
#' @param envelope Numeric in (0, 1). Half-amplitude of the dose range around
#'   `n_dose` for the calibration method. Default 0.25 (i.e. minN = 0.75 *
#'   n_dose, maxN = 1.25 * n_dose).
#' @param minN,maxN Optional explicit override of the envelope (in kg/ha).
#' @param mas_cap Numeric or NULL. If provided, caps the per-pixel rate so it
#'   never exceeds the MAS limit (e.g. from `get_MAS()`).
#' @param plot Logical, passed to the underlying estimator. Default FALSE.
#'
#' @return A list with:
#' \describe{
#'   \item{rate_raster}{`terra::SpatRaster` of N rate per pixel (kg/ha).}
#'   \item{mean_kg_ha}{Mean rate over non-NA pixels (kg/ha).}
#'   \item{min_kg_ha, max_kg_ha}{Min and max rate over non-NA pixels.}
#'   \item{n_dose_input}{The input field-average N dose.}
#'   \item{method}{The method used.}
#' }
#'
#' @examples
#' \dontrun{
#' library(terra)
#' library(NFert)
#' # NDVI raster
#' data(s2.rast)
#' ndvi <- terra::rast(s2.rast)   # s2.rast is a PackedSpatRaster; unwrap it
#'
#' # 1) Compute agronomic dose with the balance
#' bal <- N_balance(expected_yield_tons_ha = 6,
#'                  crop = "Grano duro (pianta intera)",
#'                  ccp  = "Spring-summer crop 100-130 days",
#'                  sand = 15.5, clay = 18.5,
#'                  Ntot = 1.5, SOM = 2, CN = 7.73,
#'                  oxygen_availability = "Normal",
#'                  winter_rain = 150, start_spring_rain = 0,
#'                  prev_crop = "Maize stalks removed",
#'                  source = "None", fertorg_frequency = "every year",
#'                  location = "Plain adjacent to urbanized areas",
#'                  forg_quantity = 0)
#' n_dose <- calculate_N_fertilization(bal)   # ~128 kg/ha
#'
#' # 2) Spatialise via NDVI calibration
#' vr <- variable_rate_N(ndvi, n_dose = n_dose, method = "calibration",
#'                       mas_cap = get_MAS("Grano duro (pianta intera)")$mas_N)
#' terra::plot(vr$rate_raster)
#' vr$mean_kg_ha
#' }
#' @export
variable_rate_N <- function(ndvi_raster,
                            n_dose,
                            method   = c("calibration", "holland"),
                            envelope = 0.25,
                            minN = NULL, maxN = NULL,
                            mas_cap = NULL,
                            plot    = FALSE) {
  method <- match.arg(method)
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required.")
  }
  if (!is.numeric(n_dose) || length(n_dose) != 1 || n_dose <= 0) {
    stop("`n_dose` must be a single positive numeric (kg/ha).")
  }
  if (!is.numeric(envelope) || envelope <= 0 || envelope >= 1) {
    stop("`envelope` must be in (0, 1).")
  }

  if (is.null(minN)) minN <- n_dose * (1 - envelope)
  if (is.null(maxN)) maxN <- n_dose * (1 + envelope)

  if (method == "calibration") {
    rate <- estimate_N_rate_from_calibration_curve(
      raster = ndvi_raster, minN = minN, maxN = maxN,
      calibration_type = "two-point", plot = plot)
  } else {
    res <- estimate_N_rate_from_holland_schepers(
      ndvi_raster = ndvi_raster, base_N_rate = n_dose, plot = plot)
    rate <- res$dose_raster
  }

  # Preserve the agronomic mean (mass-balance constraint): pixel mean equals
  # n_dose, with every pixel in [0, mas_cap] (water filling)
  hi <- if (!is.null(mas_cap) && is.numeric(mas_cap) && mas_cap > 0) mas_cap else Inf
  vals <- terra::values(rate, mat = FALSE)
  vals <- .preserve_mean(vals, rep(1, length(vals)), n_dose, lo = 0, hi = hi)
  rate <- terra::setValues(rate, vals)

  vals_final <- terra::values(rate, mat = FALSE)
  list(
    rate_raster  = rate,
    mean_kg_ha   = mean(vals_final, na.rm = TRUE),
    min_kg_ha    = min(vals_final,  na.rm = TRUE),
    max_kg_ha    = max(vals_final,  na.rm = TRUE),
    n_dose_input = n_dose,
    method       = method,
    minN_envelope = minN,
    maxN_envelope = maxN,
    mas_cap      = mas_cap
  )
}
