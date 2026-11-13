#' Spatially-explicit Nitrogen Balance
#'
#' Applies \code{\link{N_balance}()} pixel-by-pixel to a set of soil-property
#' rasters, returning one or more raster layers with the spatially-resolved
#' balance terms.
#'
#' @param soil_stack A \code{terra::SpatRaster} whose layers encode the soil
#'   properties that vary in space (a legacy \code{raster} object is accepted
#'   and converted with \code{terra::rast()}).
#'   Required layers (matched by name, case-insensitive):
#'   \describe{
#'     \item{TN}{Total soil nitrogen, pct}
#'     \item{SOM}{Soil organic matter, pct}
#'     \item{Clay}{Clay content, pct}
#'     \item{Sand}{Sand content, pct}
#'     \item{CNratio}{Carbon-to-nitrogen ratio (dimensionless)}
#'   }
#' @param expected_yield_tons_ha Numeric scalar. Expected crop yield
#'   (t ha\eqn{^{-1}}).
#' @param crop Character. Crop name (Italian or English, see
#'   \code{\link{resolve_crop}()}).
#' @param ccp Character. Crop calendar period.
#' @param oxygen_availability Character. Oxygen availability class (default
#'   \code{"Normal"}).
#' @param winter_rain,start_spring_rain Numeric scalars. Rainfall (mm).
#' @param prev_crop Character. Previous crop.
#' @param source,fertorg_frequency,location,forg_quantity Organic-fertilization
#'   parameters (see \code{\link{N_balance}()}).
#' @param terms Character vector of balance terms to return as layers in the
#'   output \code{terra::SpatRaster}. Default
#'   \code{c("A", "B", "C1", "C2", "D", "E", "F", "Forg", "G", "N_to_apply")}.
#'   Use \code{"all"} to return every column of the \code{N_balance()} output.
#' @param ... Additional arguments passed to \code{N_balance()}.
#'
#' @return A \code{terra::SpatRaster} with one layer per requested balance term,
#'   at the same resolution, extent and CRS as \code{soil_stack}.
#'
#' @details
#' Agronomic and climatic parameters that do not depend on location within the
#' field (yield target, crop, rainfall, previous crop, organic history) are
#' treated as scalars: the spatial variability of the balance is driven
#' exclusively by the soil-property rasters.
#'
#' The function iterates over all non-NA cells.
#' For a 96 \eqn{\times}{x} 101 raster (~10 000 pixels) the computation
#' takes approximately one second on a modern laptop.
#'
#' @seealso \code{\link{N_balance}()}, \code{\link{estimate_N_rate_from_holland_schepers}()}
#' @export
#'
#' @examples
#' \dontrun{
#' library(terra)
#' ext <- system.file("extdata", package = "NFert")
#' soil <- terra::rast(c(
#'   file.path(ext, "Cremonesi_TN.tif"),
#'   file.path(ext, "Cremonesi_SOM.tif"),
#'   file.path(ext, "Cremonesi_Clay.tif"),
#'   file.path(ext, "Cremonesi_Sand.tif"),
#'   file.path(ext, "Cremonesi_CNratio.tif")
#' ))
#' names(soil) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
#'
#' n_map <- spatial_N_balance(
#'   soil_stack = soil,
#'   expected_yield_tons_ha = 60,
#'   crop = "Mais trinciato (classe 700)",
#'   ccp  = "Spring-summer crop 100-130 days",
#'   oxygen_availability = "Normal",
#'   winter_rain = 160, start_spring_rain = 40,
#'   prev_crop = "Winter cereals straw removal",
#'   source = "Cattle slurry", fertorg_frequency = "every year",
#'   location = "Plain adjacent to urbanized areas",
#'   forg_quantity = 100
#' )
#' terra::plot(n_map[["N_to_apply"]])
#' }
spatial_N_balance <- function(
    soil_stack,
    expected_yield_tons_ha,
    crop,
    ccp,
    oxygen_availability = "Normal",
    winter_rain,
    start_spring_rain,
    prev_crop,
    source        = "Cattle slurry",
    fertorg_frequency = "every year",
    location      = "Plain adjacent to urbanized areas",
    forg_quantity = 0,
    terms         = c("A", "B", "C1", "C2", "D", "E", "F", "Forg", "G", "N_to_apply"),
    ...) {

  if (!requireNamespace("terra", quietly = TRUE))
    stop("Package 'terra' is required for spatial_N_balance().")

  # Accept legacy raster objects by coercing to terra SpatRaster.
  if (inherits(soil_stack, c("RasterStack", "RasterBrick", "RasterLayer")))
    soil_stack <- terra::rast(soil_stack)

  # --- Match layer names (case-insensitive) --------------------------------
  lnames  <- tolower(names(soil_stack))
  need    <- c("tn", "som", "clay", "sand", "cnratio")
  idx     <- match(need, lnames)
  if (any(is.na(idx)))
    stop("soil_stack must contain layers named: TN, SOM, Clay, Sand, CNratio. ",
         "Missing: ", paste(c("TN", "SOM", "Clay", "Sand", "CNratio")[is.na(idx)],
                            collapse = ", "))

  # --- Extract values matrix  (rows = pixels, cols = layers) ---------------
  vals <- terra::values(soil_stack)
  n_px <- nrow(vals)

  # Identify valid (all-non-NA) pixels
  valid <- which(stats::complete.cases(vals[, idx, drop = FALSE]))

  # --- Run N_balance per pixel --------------------------------------------
  # Pre-allocate a matrix: rows = pixels, cols filled after first call
  first <- N_balance(
    expected_yield_tons_ha = expected_yield_tons_ha,
    crop = crop, ccp = ccp,
    sand = vals[valid[1], idx[4]],
    clay = vals[valid[1], idx[3]],
    Ntot = vals[valid[1], idx[1]],
    SOM  = vals[valid[1], idx[2]],
    CN   = vals[valid[1], idx[5]],
    oxygen_availability = oxygen_availability,
    winter_rain = winter_rain, start_spring_rain = start_spring_rain,
    prev_crop = prev_crop,
    source = source, fertorg_frequency = fertorg_frequency,
    location = location, forg_quantity = forg_quantity,
    ...
  )

  # Mineral N to apply, as in farm_balance() and Fert_Office (phase share,
  # crop ceiling, current-year organic N subtracted, never negative)
  compute_N <- function(row) calculate_N_fertilization(row)

  # Numeric columns only (drop logical like surplus_pluviometrico)
  num_cols <- names(first)[vapply(first, is.numeric, logical(1))]

  out_mat <- matrix(NA_real_, nrow = n_px, ncol = length(num_cols) + 1)
  colnames(out_mat) <- c(num_cols, "N_to_apply")

  out_mat[valid[1], seq_along(num_cols)] <- as.numeric(first[1, num_cols])
  out_mat[valid[1], "N_to_apply"] <- compute_N(first)

  for (i in valid[-1]) {
    nb <- N_balance(
      expected_yield_tons_ha = expected_yield_tons_ha,
      crop = crop, ccp = ccp,
      sand = vals[i, idx[4]],
      clay = vals[i, idx[3]],
      Ntot = vals[i, idx[1]],
      SOM  = vals[i, idx[2]],
      CN   = vals[i, idx[5]],
      oxygen_availability = oxygen_availability,
      winter_rain = winter_rain, start_spring_rain = start_spring_rain,
      prev_crop = prev_crop,
      source = source, fertorg_frequency = fertorg_frequency,
      location = location, forg_quantity = forg_quantity,
      ...
    )
    out_mat[i, seq_along(num_cols)] <- as.numeric(nb[1, num_cols])
    out_mat[i, "N_to_apply"] <- compute_N(nb)
  }

  # --- Build output RasterStack -------------------------------------------
  if (identical(terms, "all")) terms <- colnames(out_mat)
  bad <- setdiff(terms, colnames(out_mat))
  if (length(bad))
    stop("Unknown term(s): ", paste(bad, collapse = ", "),
         ". Available: ", paste(colnames(out_mat), collapse = ", "))

  template <- terra::rast(soil_stack[[1]])
  layers <- lapply(terms, function(t) {
    r <- terra::rast(template)          # fresh SpatRaster (own pointer), same geom
    terra::values(r) <- out_mat[, t]
    names(r) <- t
    r
  })
  terra::rast(layers)
}
