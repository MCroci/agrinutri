#' Critical nitrogen curve parameters (Lemaire & Gastal 1997 framework)
#'
#' Returns the coefficients \code{a} and \code{b} of the critical nitrogen
#' dilution curve \eqn{N_c = a \cdot W^{-b}} (N_c in % DM, W in t DM / ha)
#' for the main Italian arable crops, plus the minimum biomass
#' \code{W_min} below which the curve is held constant at
#' \eqn{N_c = a \cdot W_{min}^{-b}} (standard convention: the curve is only
#' valid for a closed canopy, i.e. W >= ~1-1.55 t DM/ha depending on the crop).
#'
#' Published references:
#' \itemize{
#'   \item \strong{wheat (C3 cereals)}: a = 5.35, b = 0.44, W_min = 1.55
#'         (Justes et al. 1994)
#'   \item \strong{durum wheat}: same as wheat (Prey & Schmidhalter 2019)
#'   \item \strong{maize (C4)}: a = 3.40, b = 0.37, W_min = 1.00
#'         (Plenet & Lemaire 1999)
#'   \item \strong{rice}: a = 5.18, b = 0.52, W_min = 1.00
#'         (Sheehy et al. 1998)
#'   \item \strong{rapeseed}: a = 4.48, b = 0.25, W_min = 1.55
#'         (Colnenne et al. 1998)
#'   \item \strong{grass (ryegrass, fescue, Lolium)}: a = 4.80, b = 0.32,
#'         W_min = 1.00 (Duru et al. 1997)
#'   \item \strong{sorghum (C4)}: a = 3.90, b = 0.39, W_min = 1.00
#'         (van Oosterom et al. 2010)
#'   \item \strong{sunflower}: a = 4.53, b = 0.42, W_min = 1.00
#'         (Debaeke et al. 2012)
#' }
#'
#' @param crop Character. Crop identifier (see list above). Case-insensitive;
#'   Italian synonyms (\code{"frumento"}, \code{"mais"}, \code{"colza"},
#'   \code{"riso"}, \code{"girasole"}, \code{"sorgo"}) are accepted.
#'
#' @return A list with numeric elements \code{a}, \code{b}, \code{W_min}
#'   and \code{reference} (character).
#'
#' @references
#' Lemaire, G. & Gastal, F. (1997). N uptake and distribution in plant
#' canopies. In: Lemaire G. (ed.) Diagnosis of the Nitrogen Status in Crops.
#' Springer, Berlin.
#'
#' Justes, E. et al. (1994). Determination of a critical nitrogen dilution
#' curve for winter wheat crops. Ann. Bot. 74, 397-407.
#'
#' Plenet, D. & Lemaire, G. (1999). Relationships between dynamics of
#' nitrogen uptake and dry matter accumulation in maize crops. Determination
#' of critical N concentration. Plant Soil 216, 65-82.
#'
#' @export
critical_N_curve <- function(crop) {
  if (missing(crop) || length(crop) != 1)
    stop("`crop` must be a single character string.")

  key <- tolower(trimws(as.character(crop)))
  synonyms <- c(
    "wheat" = "wheat", "bread wheat" = "wheat",
    "grano tenero" = "wheat", "frumento" = "wheat",
    "frumento tenero" = "wheat", "c3 cereal" = "wheat",
    "durum wheat" = "wheat", "grano duro" = "wheat",
    "maize" = "maize", "mais" = "maize", "corn" = "maize",
    "rice" = "rice", "riso" = "rice",
    "rapeseed" = "rapeseed", "colza" = "rapeseed",
    "grass" = "grass", "ryegrass" = "grass",
    "lolium" = "grass", "prato" = "grass",
    "fescue" = "grass",
    "sorghum" = "sorghum", "sorgo" = "sorghum",
    "sunflower" = "sunflower", "girasole" = "sunflower"
  )
  resolved <- synonyms[key]
  if (is.na(resolved))
    stop("Unknown crop '", crop, "'. Supported: ",
         paste(unique(synonyms), collapse = ", "),
         " (plus Italian synonyms).")

  tab <- list(
    wheat    = list(a = 5.35, b = 0.44, W_min = 1.55,
                    reference = "Justes et al. 1994"),
    maize    = list(a = 3.40, b = 0.37, W_min = 1.00,
                    reference = "Plenet & Lemaire 1999"),
    rice     = list(a = 5.18, b = 0.52, W_min = 1.00,
                    reference = "Sheehy et al. 1998"),
    rapeseed = list(a = 4.48, b = 0.25, W_min = 1.55,
                    reference = "Colnenne et al. 1998"),
    grass    = list(a = 4.80, b = 0.32, W_min = 1.00,
                    reference = "Duru et al. 1997"),
    sorghum  = list(a = 3.90, b = 0.39, W_min = 1.00,
                    reference = "van Oosterom et al. 2010"),
    sunflower= list(a = 4.53, b = 0.42, W_min = 1.00,
                    reference = "Debaeke et al. 2012")
  )
  tab[[resolved]]
}


#' Nitrogen Nutrition Index (NNI)
#'
#' Computes the Nitrogen Nutrition Index, the standard scalar indicator of
#' crop N status (Lemaire & Gastal 1997). NNI = N_actual / N_c, where
#' N_actual is the measured aboveground N concentration (% DM) and N_c is
#' the critical N concentration derived from the species-specific dilution
#' curve \eqn{N_c = a \cdot W^{-b}}.
#'
#' Interpretation:
#' \itemize{
#'   \item NNI < \code{deficient_threshold} (default 0.90): N-deficient
#'   \item \code{deficient_threshold} <= NNI <= \code{excessive_threshold}
#'         (0.90 to 1.10 by default): optimal / balanced
#'   \item NNI > \code{excessive_threshold} (default 1.10): luxury
#'         consumption / N-excess
#' }
#'
#' All three arguments can be scalar, numeric vectors of the same length
#' (pixel-wise / plot-wise), or \code{terra::SpatRaster}s aligned to the
#' same grid. If any of them is a `SpatRaster`, the output is a
#' `SpatRaster`; otherwise a numeric vector is returned. Legacy `raster`
#' objects are accepted and converted with `terra::rast()`.
#'
#' @param N_content Aboveground N concentration as a fraction of DM (e.g.
#'   0.025 = 2.5pct) \strong{or} percentage DM (pass \code{is_percent = TRUE}).
#' @param biomass Aboveground dry biomass in t DM / ha (\strong{tonnes}).
#' @param crop Crop identifier, passed to \code{\link{critical_N_curve}}.
#' @param curve Optional list with \code{a} and \code{b} (and optionally
#'   \code{W_min}) to override the default curve. Useful for custom local
#'   calibration.
#' @param is_percent Logical. Is \code{N_content} supplied as a percentage
#'   (e.g. 2.5 for 2.5pct) rather than a fraction? Default \code{FALSE}
#'   (fraction). Auto-detected and warned if values > 1.
#'
#' @return A numeric scalar / vector or a `terra::SpatRaster` of NNI values.
#'
#' @references
#' Lemaire, G. & Gastal, F. (1997). N uptake and distribution in plant
#' canopies. In: Lemaire G. (ed.) Diagnosis of the Nitrogen Status in Crops.
#' Springer, Berlin.
#'
#' Lemaire, G., Jeuffroy, M.-H., Gastal, F. (2008). Diagnosis tool for plant
#' and crop N status in vegetative stage: theory and practices for crop N
#' management. Eur. J. Agron. 28, 614-624.
#'
#' @examples
#' \dontrun{
#' # Scalar: wheat at GS30, N% = 3.2, biomass = 2.5 t/ha
#' compute_NNI(N_content = 3.2, biomass = 2.5, crop = "wheat",
#'             is_percent = TRUE)
#' # ~ 0.94 -> slightly deficient
#'
#' # Field-average maize at V8, N% = 2.8, biomass = 4 t/ha
#' compute_NNI(2.8, 4, crop = "maize", is_percent = TRUE)
#' # ~ 1.52 -> luxury consumption
#'
#' # Raster (pixel-wise): N_content and biomass as SpatRasters
#' nni_map <- compute_NNI(N_content = n_map, biomass = w_map,
#'                        crop = "wheat", is_percent = TRUE)
#' }
#' @export
compute_NNI <- function(N_content, biomass, crop,
                        curve = NULL, is_percent = FALSE) {
  if (is.null(curve))
    curve <- critical_N_curve(crop)
  if (is.null(curve$a) || is.null(curve$b))
    stop("`curve` must contain `a` and `b`.")
  if (is.null(curve$W_min)) curve$W_min <- 1.00

  # Accept legacy raster objects by coercing to terra SpatRaster.
  if (inherits(N_content, c("RasterLayer", "RasterStack", "RasterBrick")) ||
      inherits(biomass,   c("RasterLayer", "RasterStack", "RasterBrick"))) {
    if (!requireNamespace("terra", quietly = TRUE))
      stop("Package 'terra' is required for raster inputs.")
    if (inherits(N_content, c("RasterLayer", "RasterStack", "RasterBrick")))
      N_content <- terra::rast(N_content)
    if (inherits(biomass, c("RasterLayer", "RasterStack", "RasterBrick")))
      biomass <- terra::rast(biomass)
  }

  is_raster <- function(x) inherits(x, "SpatRaster")
  any_raster <- is_raster(N_content) || is_raster(biomass)

  if (any_raster && !requireNamespace("terra", quietly = TRUE))
    stop("Package 'terra' is required for raster inputs.")

  # normalise N_content to percent (DM)
  normalise_N <- function(x) {
    if (is_raster(x)) {
      vals <- terra::values(x, mat = FALSE)
      if (!isTRUE(is_percent) && any(vals > 1, na.rm = TRUE)) {
        warning("`N_content` raster has values > 1 but `is_percent = FALSE`",
                ". Treating values as percent.")
        return(x)
      }
      if (isTRUE(is_percent)) return(x) else return(x * 100)
    }
    if (!isTRUE(is_percent) && any(x > 1, na.rm = TRUE)) {
      warning("`N_content` has values > 1 but `is_percent = FALSE`.",
              " Treating values as percent.")
      return(x)
    }
    if (isTRUE(is_percent)) x else x * 100
  }

  N_pct <- normalise_N(N_content)

  # clamp biomass at W_min (curve invalid for open canopy)
  clamp_W <- function(x) {
    if (is_raster(x)) {
      v <- terra::values(x, mat = FALSE)
      v[!is.na(v) & v < curve$W_min] <- curve$W_min
      return(terra::setValues(x, v))
    }
    ifelse(!is.na(x) & x < curve$W_min, curve$W_min, x)
  }

  W <- clamp_W(biomass)

  # Nc = a * W^(-b)
  Nc <- curve$a * W ^ (-curve$b)

  nni <- N_pct / Nc
  if (is_raster(nni)) names(nni) <- "NNI"
  nni
}


#' Diagnose crop N status from biomass and N content (NNI classes)
#'
#' Wraps \code{\link{compute_NNI}} and turns continuous NNI values into
#' three discrete classes used for fertilisation diagnosis and for
#' diagnostic maps in variable-rate applications.
#'
#' Class codes (integer factor levels):
#' \enumerate{
#'   \item \strong{1 - deficient}: NNI < \code{deficient_threshold}
#'         (default 0.90)
#'   \item \strong{2 - optimal}: \code{deficient_threshold} <= NNI <=
#'         \code{excessive_threshold} (default 1.10)
#'   \item \strong{3 - excessive}: NNI > \code{excessive_threshold}
#' }
#'
#' The class raster can be fed straight into variable-rate logic: e.g. apply
#' the full agronomic dose only where class = 1 or 2, zero dose where class = 3.
#'
#' @inheritParams compute_NNI
#' @param deficient_threshold Lower bound of the optimal NNI band.
#'   Default 0.90.
#' @param excessive_threshold Upper bound of the optimal NNI band.
#'   Default 1.10.
#'
#' @return A list with:
#' \describe{
#'   \item{\code{NNI}}{Continuous NNI (numeric or SpatRaster).}
#'   \item{\code{class}}{Integer class (1/2/3) or SpatRaster of classes.}
#'   \item{\code{labels}}{Character labels matching \code{class}.}
#'   \item{\code{summary}}{Counts / fractions per class (rasters only).}
#'   \item{\code{thresholds}}{The thresholds used.}
#'   \item{\code{curve}}{The critical-N curve parameters.}
#' }
#'
#' @examples
#' \dontrun{
#' # Scalar diagnosis
#' diagnose_N_status(N_content = 2.8, biomass = 4,
#'                   crop = "maize", is_percent = TRUE)
#'
#' # Pixel-wise diagnosis
#' d <- diagnose_N_status(N_content = n_raster, biomass = w_raster,
#'                        crop = "wheat", is_percent = TRUE)
#' terra::plot(d$class)
#' d$summary
#' }
#' @export
diagnose_N_status <- function(N_content, biomass, crop,
                              curve = NULL, is_percent = FALSE,
                              deficient_threshold = 0.90,
                              excessive_threshold = 1.10) {
  if (deficient_threshold >= excessive_threshold)
    stop("`deficient_threshold` must be < `excessive_threshold`.")

  nni <- compute_NNI(N_content, biomass, crop = crop,
                     curve = curve, is_percent = is_percent)

  is_raster <- inherits(nni, "SpatRaster")
  labels <- c("deficient", "optimal", "excessive")

  classify <- function(v) {
    out <- integer(length(v))
    out[!is.na(v) & v <  deficient_threshold] <- 1L
    out[!is.na(v) & v >= deficient_threshold &
                   v <= excessive_threshold] <- 2L
    out[!is.na(v) & v >  excessive_threshold] <- 3L
    out[is.na(v)] <- NA_integer_
    out
  }

  if (is_raster) {
    if (!requireNamespace("terra", quietly = TRUE))
      stop("Package 'terra' is required for raster inputs.")
    vals <- terra::values(nni, mat = FALSE)
    cls_vals <- classify(vals)
    cls <- terra::setValues(nni, cls_vals)
    names(cls) <- "NNI_class"
    tab <- table(factor(cls_vals, levels = 1:3, labels = labels),
                 useNA = "no")
    frac <- tab / sum(tab)
    summary <- list(counts = as.list(tab), fractions = as.list(frac))
  } else {
    cls <- classify(nni)
    summary <- NULL
  }

  lbls <- character(length(cls))
  if (is_raster) {
    lbls <- labels
  } else {
    lbls[cls == 1L] <- labels[1]
    lbls[cls == 2L] <- labels[2]
    lbls[cls == 3L] <- labels[3]
    lbls[is.na(cls)] <- NA_character_
  }

  list(
    NNI        = nni,
    class      = cls,
    labels     = lbls,
    summary    = summary,
    thresholds = c(deficient = deficient_threshold,
                   excessive = excessive_threshold),
    curve      = if (is.null(curve)) critical_N_curve(crop) else curve
  )
}
