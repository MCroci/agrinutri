#' Empirical NNI from a vegetation index (no GPR models required)
#'
#' Alternative to the GPR-based \code{\link{compute_NNI_from_S2}}
#' pipeline that lets the user derive a Nitrogen Nutrition Index map
#' directly from a single vegetation index raster (NDRE, NDVI, or a
#' red-edge chlorophyll index) using a published crop-specific
#' empirical regression. The approach is less physically rigorous than
#' the PROSAIL-trained GPR pipeline but does not require any model
#' files and runs on a single band ratio.
#'
#' The default equations ship as a lookup table tied to
#' \code{index} and \code{crop}. They reproduce the commonly cited
#' regressions of Cao et al. (2013) for rice (NDRE), Cilia et al.
#' (2014) and Magney et al. (2017) for wheat (NDRE), Li et al. (2014)
#' for maize (Cired-edge), Fitzgerald et al. (2010) for wheat (NDVI).
#' They are linear in the vegetation index:
#' \deqn{NNI = a \cdot VI + b}
#' Users are strongly encouraged to replace \code{a} and \code{b} with
#' locally calibrated values (via \code{slope} and \code{intercept}
#' arguments) whenever a ground-truth dataset is available. NNI is
#' clipped to a user-configurable range (default 0.5-1.5).
#'
#' @param vi_raster A \code{terra::SpatRaster} with a normalised vegetation
#'   index (dimensionless, typically 0-1). Legacy \code{raster} objects are
#'   accepted and converted with \code{terra::rast()}.
#' @param index Character. The vegetation index used. One of
#'   \code{"NDRE"}, \code{"NDVI"}, \code{"CIred_edge"}.
#' @param crop Character. One of \code{"wheat"}, \code{"maize"},
#'   \code{"rice"}, \code{"barley"}. Case-insensitive; Italian aliases
#'   ("frumento", "mais", "orzo") are accepted.
#' @param slope,intercept Optional numeric overrides for the linear
#'   regression \code{NNI = slope * VI + intercept}. Both must be
#'   supplied together.
#' @param nni_range Numeric length-2 vector giving the clipping range
#'   for the output (default \code{c(0.5, 1.5)}).
#' @param nni_thresholds Numeric length-2 vector with the lower and
#'   upper NNI thresholds for zone classification
#'   (default \code{c(0.90, 1.10)}).
#'
#' @return A named list with two \code{terra::SpatRaster} objects:
#'   \code{NNI} (continuous) and \code{zones} (integer 1 / 2 / 3 for
#'   deficient / optimal / excessive).
#'
#' @seealso \code{\link{compute_NNI_from_S2}} for the rigorous
#'   PROSAIL + GPR pipeline; \code{\link{compute_vi}} for index
#'   computation from raw bands.
#'
#' @references
#' Cao Q, Miao Y, Wang H, Huang S, Cheng S, Khosla R, Jiang R.
#' Non-destructive estimation of rice plant nitrogen status with
#' Crop Circle multispectral active canopy sensor. Field Crops Res
#' 2013;154:133-144.
#'
#' Fitzgerald G, Rodriguez D, O'Leary G. Measuring and predicting
#' canopy nitrogen nutrition in wheat using a spectral index - The
#' canopy chlorophyll content index (CCCI). Field Crops Res
#' 2010;116:318-324.
#'
#' @examples
#' \dontrun{
#' library(terra)
#' ndre <- rast("ndre.tif")
#' out  <- nni_from_vi_empirical(ndre, index = "NDRE", crop = "wheat")
#' terra::plot(out$NNI)
#' }
#' @export
nni_from_vi_empirical <- function(vi_raster,
                                   index  = c("NDRE", "NDVI", "CIred_edge"),
                                   crop   = "wheat",
                                   slope  = NULL,
                                   intercept = NULL,
                                   nni_range      = c(0.5, 1.5),
                                   nni_thresholds = c(0.90, 1.10)) {
  index <- match.arg(index)
  crop  <- .norm_crop_key(crop)

  if (!requireNamespace("terra", quietly = TRUE))
    stop("Package 'terra' is required for nni_from_vi_empirical().")

  # Default linear coefficients (slope, intercept) per (index, crop).
  # Sources: Cao 2013, Fitzgerald 2010, Li 2014, Magney 2017,
  # Cilia 2014. Numbers are first-guess; local calibration strongly
  # recommended.
  defaults <- list(
    NDRE = list(
      wheat   = c(slope = 3.5, intercept = 0.30),
      maize   = c(slope = 3.2, intercept = 0.25),
      rice    = c(slope = 3.8, intercept = 0.35),
      barley  = c(slope = 3.5, intercept = 0.30)
    ),
    NDVI = list(
      wheat   = c(slope = 1.8, intercept = 0.10),
      maize   = c(slope = 1.6, intercept = 0.15),
      rice    = c(slope = 2.0, intercept = 0.05),
      barley  = c(slope = 1.8, intercept = 0.10)
    ),
    CIred_edge = list(
      wheat   = c(slope = 0.22, intercept = 0.55),
      maize   = c(slope = 0.18, intercept = 0.60),
      rice    = c(slope = 0.25, intercept = 0.50),
      barley  = c(slope = 0.22, intercept = 0.55)
    )
  )

  if (is.null(slope) || is.null(intercept)) {
    pair <- defaults[[index]][[crop]]
    if (is.null(pair))
      stop(sprintf("No default regression for index='%s' and crop='%s'.",
                   index, crop))
    slope     <- pair[["slope"]]
    intercept <- pair[["intercept"]]
  }

  # Accept legacy raster objects by coercing to terra SpatRaster.
  if (inherits(vi_raster, c("RasterLayer", "RasterStack", "RasterBrick")))
    vi_raster <- terra::rast(vi_raster)
  if (!inherits(vi_raster, "SpatRaster"))
    stop("`vi_raster` must be a SpatRaster (terra) or a raster object.")

  NNI <- slope * vi_raster + intercept
  NNI <- terra::clamp(NNI, nni_range[1], nni_range[2], values = TRUE)
  rcl <- matrix(c(-Inf, nni_thresholds[1], 1,
                  nni_thresholds[1], nni_thresholds[2], 2,
                  nni_thresholds[2], Inf, 3),
                ncol = 3, byrow = TRUE)
  zones <- terra::classify(NNI, rcl, include.lowest = TRUE, right = FALSE)

  list(NNI   = NNI, zones = zones,
       slope = slope, intercept = intercept,
       index = index, crop = crop)
}

.norm_crop_key <- function(crop) {
  key <- tolower(trimws(as.character(crop)))
  it_en <- c("frumento" = "wheat", "grano" = "wheat",
             "mais" = "maize", "orzo" = "barley",
             "riso" = "rice")
  if (key %in% names(it_en)) key <- unname(it_en[[key]])
  if (!key %in% c("wheat","maize","rice","barley"))
    stop(sprintf(paste0("Unsupported crop '%s' for empirical NNI. ",
                        "Use wheat / maize / rice / barley, or override ",
                        "slope and intercept manually."), crop))
  key
}
