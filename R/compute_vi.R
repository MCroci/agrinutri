#' Compute a vegetation index from a multi-band raster
#'
#' Generic engine that computes the main vegetation indices used in nitrogen
#' diagnosis from a multi-band `terra::SpatRaster`.
#' agrinutri supports six indices with configurable band mapping, so the function
#' works with Sentinel-2 L2A, UAV multispectral sensors (MicaSense, Parrot
#' Sequoia, Pix4D) or any other multispectral product.
#'
#' Index formulas (references in the References section):
#'
#' \describe{
#'   \item{NDVI}{(NIR minus Red) divided by (NIR plus Red). Rouse 1974.}
#'   \item{NDRE}{(NIR minus RedEdge) divided by (NIR plus RedEdge).
#'     Gitelson and Merzlyak 1994.}
#'   \item{GNDVI}{(NIR minus Green) divided by (NIR plus Green).
#'     Gitelson 1996.}
#'   \item{CIred}{NIR divided by RedEdge, minus one. Gitelson 2003.}
#'   \item{MCARI}{The quantity RedEdge minus Red minus 0.2 times the
#'     quantity RedEdge minus Green, all multiplied by the ratio
#'     RedEdge over Red. Daughtry 2000.}
#'   \item{MSAVI2}{2 NIR + 1 minus the square root of (2 NIR + 1)^2
#'     minus 8 times NIR minus Red, all divided by two. Qi 1994.}
#' }
#'
#' NDVI saturates at LAI > 3--4 in closed canopies; in mid- to late-vegetative
#' stages (GS30+ for cereals, V8+ for maize) the red-edge indices (NDRE,
#' CIred) are considerably more sensitive to canopy nitrogen status (Clarke
#' 2001; Li 2014; Cao 2015). agrinutri variable-rate functions
#' (`variable_rate_N()`, `estimate_N_rate_from_calibration_curve()`,
#' `estimate_N_rate_from_holland_schepers()`) all accept any normalised VI on
#' a 0--1 scale, so the user can substitute NDVI with NDRE or GNDVI
#' transparently.
#'
#' @param stack A `terra::SpatRaster` with the required spectral bands (a
#'   legacy `raster` object is accepted and converted with `terra::rast()`).
#'   Band names (or layer indices) are mapped through \code{bands}.
#' @param index One of \code{"NDVI"}, \code{"NDRE"}, \code{"GNDVI"},
#'   \code{"CIred"}, \code{"MCARI"}, \code{"MSAVI2"} (case-insensitive).
#' @param bands Named list or character vector mapping the index inputs
#'   (\code{red}, \code{red_edge}, \code{nir}, \code{green}) to layer names
#'   in \code{stack}. Defaults to Sentinel-2 L2A naming
#'   (\code{red="B04"}, \code{red_edge="B05"}, \code{nir="B08"},
#'   \code{green="B03"}). Only the bands required by the chosen index are
#'   looked up.
#' @param scale_factor Numeric. If the input reflectance is stored as integer
#'   DN (e.g. Sentinel-2 L2A 0--10000), divide by this factor before
#'   computing the index. Default \code{1} (reflectance already in 0--1).
#' @param clamp Logical. If \code{TRUE} (default for bounded indices NDVI,
#'   NDRE, GNDVI, MSAVI2), clamp output to the range -1 to 1. Ignored
#'   for CIred and MCARI (unbounded).
#'
#' @return A single-layer \code{terra::SpatRaster} with the computed index.
#'   Layer name is set to the index name.
#'
#' @references
#' Rouse, J.W. et al. (1974). Monitoring vegetation systems in the Great
#' Plains with ERTS. NASA SP-351.
#'
#' Gitelson, A.A. & Merzlyak, M.N. (1994). Quantitative estimation of
#' chlorophyll-a using reflectance spectra. J. Photochem. Photobiol. B 22.
#'
#' Gitelson, A.A. et al. (1996). Use of a green channel in remote sensing of
#' global vegetation from EOS-MODIS. Remote Sens. Environ. 58, 289-298.
#'
#' Gitelson, A.A. et al. (2003). Relationships between leaf chlorophyll
#' content and spectral reflectance. J. Plant Physiol. 160, 271-282.
#'
#' Daughtry, C.S.T. et al. (2000). Estimating corn leaf chlorophyll
#' concentration from leaf and canopy reflectance. Remote Sens. Environ. 74.
#'
#' Qi, J. et al. (1994). A modified soil adjusted vegetation index. Remote
#' Sens. Environ. 48, 119-126.
#'
#' Clarke, T.R. et al. (2001). Remote sensing of nitrogen status in wheat.
#' Proc. Beltwide Cotton Conf.
#'
#' Li, F. et al. (2014). Improving estimation of summer maize nitrogen
#' status with red edge-based spectral vegetation indices. F. Crops Res. 157.
#'
#' Cao, Q. et al. (2015). Active canopy sensing of winter wheat nitrogen
#' status: An evaluation of two sensor systems. Comput. Electron. Agric. 112.
#'
#' @examples
#' \dontrun{
#' library(terra)
#' library(agrinutri)
#'
#' # Sentinel-2 L2A stack (integer DN, 0-10000)
#' s2 <- terra::rast("S2_Cremonesi_20260415.tif")
#' names(s2) <- c("B03", "B04", "B05", "B08")
#'
#' ndvi  <- compute_vi(s2, "NDVI",  scale_factor = 10000)
#' ndre  <- compute_vi(s2, "NDRE",  scale_factor = 10000)
#' gndvi <- compute_vi(s2, "GNDVI", scale_factor = 10000)
#'
#' # Use any VI as input to the VRT pipeline
#' vr <- variable_rate_N(ndre, n_dose = 142, method = "holland",
#'                       minN = 60, maxN = 180)
#' }
#' @export
compute_vi <- function(stack,
                       index,
                       bands = list(red      = "B04",
                                    red_edge = "B05",
                                    nir      = "B08",
                                    green    = "B03"),
                       scale_factor = 1,
                       clamp = TRUE) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Package 'terra' is required.")
  }
  if (missing(stack))
    stop("`stack` (SpatRaster) is required.")
  # Accept legacy raster objects by coercing to terra SpatRaster.
  if (inherits(stack, c("RasterStack", "RasterBrick", "RasterLayer")))
    stack <- terra::rast(stack)
  if (!inherits(stack, "SpatRaster"))
    stop("`stack` must be a terra SpatRaster (or a raster object).")
  if (missing(index) || length(index) != 1)
    stop("`index` is required (single character).")

  valid <- c("NDVI", "NDRE", "GNDVI", "CIRED", "MCARI", "MSAVI2")
  idx <- toupper(index)
  if (idx == "CIRED-EDGE" || idx == "CI_RED_EDGE") idx <- "CIRED"
  if (!idx %in% valid)
    stop("`index` must be one of: ",
         paste(c("NDVI", "NDRE", "GNDVI", "CIred", "MCARI", "MSAVI2"),
               collapse = ", "))

  if (!is.list(bands)) bands <- as.list(bands)
  required <- switch(idx,
                     NDVI   = c("red", "nir"),
                     NDRE   = c("red_edge", "nir"),
                     GNDVI  = c("green", "nir"),
                     CIRED  = c("red_edge", "nir"),
                     MCARI  = c("red", "red_edge", "green"),
                     MSAVI2 = c("red", "nir"))
  missing_bands <- setdiff(required, names(bands))
  if (length(missing_bands) > 0)
    stop("Missing band mapping for: ",
         paste(missing_bands, collapse = ", "),
         ". Provide them in `bands` (named list).")

  get_band <- function(key) {
    ref <- bands[[key]]
    if (is.numeric(ref)) {
      if (ref < 1 || ref > terra::nlyr(stack))
        stop("Band index '", ref, "' for '", key,
             "' is out of range (stack has ",
             terra::nlyr(stack), " layers).")
      return(stack[[ref]])
    }
    if (!ref %in% names(stack))
      stop("Band '", ref, "' (for '", key,
           "') not found in stack. Available layers: ",
           paste(names(stack), collapse = ", "))
    stack[[ref]]
  }

  get_scaled <- function(key) {
    r <- get_band(key)
    if (!is.null(scale_factor) && is.finite(scale_factor) &&
        scale_factor != 1)
      r <- r / scale_factor
    r
  }

  out <- switch(idx,
    NDVI = {
      red <- get_scaled("red"); nir <- get_scaled("nir")
      (nir - red) / (nir + red)
    },
    NDRE = {
      re <- get_scaled("red_edge"); nir <- get_scaled("nir")
      (nir - re) / (nir + re)
    },
    GNDVI = {
      gre <- get_scaled("green"); nir <- get_scaled("nir")
      (nir - gre) / (nir + gre)
    },
    CIRED = {
      re <- get_scaled("red_edge"); nir <- get_scaled("nir")
      nir / re - 1
    },
    MCARI = {
      red <- get_scaled("red"); re <- get_scaled("red_edge")
      gre <- get_scaled("green")
      ((re - red) - 0.2 * (re - gre)) * (re / red)
    },
    MSAVI2 = {
      red <- get_scaled("red"); nir <- get_scaled("nir")
      (2 * nir + 1 - sqrt((2 * nir + 1)^2 - 8 * (nir - red))) / 2
    }
  )

  if (isTRUE(clamp) && idx %in% c("NDVI", "NDRE", "GNDVI", "MSAVI2"))
    out <- terra::clamp(out, lower = -1, upper = 1, values = TRUE)

  names(out) <- switch(idx,
                       NDVI = "NDVI", NDRE = "NDRE", GNDVI = "GNDVI",
                       CIRED = "CIred", MCARI = "MCARI", MSAVI2 = "MSAVI2")
  out
}
