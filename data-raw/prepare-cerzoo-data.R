# ---------------------------------------------------------------------------
# data-raw/prepare-cerzoo-data.R
#
# Build the bundled CERZOO example datasets shipped in inst/extdata so that
# package users can run the agrinutri functions on a real field out of the box.
#
# Source data live in the companion teaching repository (not part of the
# package). Only the maintainer needs them; running this script regenerates
# the small, redistributable subsets stored under inst/extdata.
#
#   * inst/extdata/cerzoo_field.geojson
#       Field boundaries of the CERZOO experimental farm (Universita Cattolica
#       del Sacro Cuore, Po Valley, Piacenza) with the agronomic attributes
#       used by N_balance()/farm_balance() (crop, expected yield, sand, clay,
#       SOM, C/N, previous crop). Field id = 3 is the case-study silage-maize
#       plot (3.24 ha).
#
#   * inst/extdata/sentinel-2/S2_cerzoo_field3_20240813.tif
#       Sentinel-2 L2A surface-reflectance subset (10 bands, canonical order
#       B02 B03 B04 B05 B06 B07 B08 B8A B11 B12) cropped and masked to CERZOO
#       Field 3 for the acquisition of 13 August 2024, the scene used in the
#       variable-rate prescription case study. Small enough to ship on CRAN.
#
# Usage (maintainer only):
#   source("data-raw/prepare-cerzoo-data.R")
# ---------------------------------------------------------------------------

stopifnot(file.exists("DESCRIPTION"))
if (!requireNamespace("terra", quietly = TRUE) ||
    !requireNamespace("sf", quietly = TRUE)) {
  stop("Packages 'terra' and 'sf' are required to rebuild the CERZOO data.")
}

# --- Source paths in the companion teaching repository ----------------------
lab <- file.path(
  "C:/Users/michele.croci/OneDrive - Universita Cattolica del Sacro Cuore",
  "rds/teaching/2027/Fondamenti di agricoltura di precisione",
  "lab-agricoltura-di-precisione"
)
# OneDrive folder uses an accented "Università"; normalizePath resolves it.
if (!dir.exists(lab)) {
  lab <- normalizePath(file.path(
    "C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
    "rds/teaching/2027/Fondamenti di agricoltura di precisione",
    "lab-agricoltura-di-precisione"), mustWork = TRUE)
}

src_fields <- file.path(lab, "input/field/cerzoo_field.geojson")
src_scene  <- file.path(lab, "input/sentinel-2",
                        "S2_20240813_B02_B03_B04_B05_B06_B07_B08_B8A_B11_B12_SCL_10m.tif")
stopifnot(file.exists(src_fields), file.exists(src_scene))

# --- Destinations -----------------------------------------------------------
dir.create("inst/extdata/sentinel-2", recursive = TRUE, showWarnings = FALSE)
dst_fields <- "inst/extdata/cerzoo_field.geojson"
dst_scene  <- "inst/extdata/sentinel-2/S2_cerzoo_field3_20240813.tif"

# --- 1. Field boundaries ----------------------------------------------------
fields <- sf::st_read(src_fields, quiet = TRUE)
sf::st_write(fields, dst_fields, delete_dsn = TRUE, quiet = TRUE)
message(sprintf("Wrote %s (%d fields).", dst_fields, nrow(fields)))

# --- 2. Sentinel-2 subset cropped/masked to Field 3 -------------------------
field3 <- fields[as.character(fields$id) == "3", ]

scene <- terra::rast(src_scene)
# Keep the 10 reflectance bands in canonical order, drop the SCL mask layer.
band_names <- c("B02", "B03", "B04", "B05", "B06", "B07",
                "B08", "B8A", "B11", "B12")
scene <- scene[[seq_len(10)]]
names(scene) <- band_names

# Crop to the field (small buffer) then mask, in the raster CRS.
field3_r <- sf::st_transform(field3, terra::crs(scene))
field3_v <- terra::vect(field3_r)
sub <- terra::crop(scene, terra::buffer(field3_v, 20))
sub <- terra::mask(sub, field3_v)

terra::writeRaster(sub, dst_scene, overwrite = TRUE,
                   gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
message(sprintf("Wrote %s (%d x %d px, %d bands, %.0f KB).",
                dst_scene, terra::nrow(sub), terra::ncol(sub),
                terra::nlyr(sub), file.size(dst_scene) / 1024))
