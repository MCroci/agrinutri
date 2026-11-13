#' Export a variable-rate prescription map for farm machinery
#'
#' Writes a prescription layer (an \code{sf} polygons object or a raster
#' from \code{\link{variable_rate_N}} / \code{\link{farm_balance}}) in
#' one of the formats accepted by the on-board monitors of modern
#' tractors and sprayers. Supported formats: plain Shapefile, GeoJSON,
#' KML, GeoPackage, \emph{John Deere-ready} Shapefile, \emph{Trimble-
#' ready} Shapefile and ISOXML TASKDATA (ISOBUS ISO 11783-10).
#'
#' @section Manufacturer-specific conventions:
#' \describe{
#'   \item{\strong{John Deere}}{WGS84 CRS, integer rate field named
#'     \code{RATE}, 8.3 DOS-safe file names.}
#'   \item{\strong{Trimble}}{WGS84 CRS, rate field named \code{TGT_RATE},
#'     unique feature \code{ID}.}
#'   \item{\strong{ISOXML}}{Directory containing \code{TASKDATA.XML}
#'     following the ISOBUS ISO 11783-10 standard (VRT zones with DDI
#'     0006 = \emph{application rate, mass per area}).}
#' }
#'
#' @param x Input map. Either an \code{sf} polygons object (as returned
#'   by \code{\link{farm_balance}}) or a \code{RasterLayer} /
#'   \code{SpatRaster} (as returned by \code{\link{variable_rate_N}}).
#'   Rasters are polygonised via \code{terra::as.polygons()} before
#'   export.
#' @param path For single-file formats, the output path (with the
#'   proper extension: \code{.shp}, \code{.geojson}, \code{.kml},
#'   \code{.gpkg}). For ISOXML, the output \strong{directory} (the
#'   \code{TASKDATA.XML} file will be created inside).
#' @param format Character. One of \code{"shp"}, \code{"geojson"},
#'   \code{"kml"}, \code{"gpkg"}, \code{"johndeere"}, \code{"trimble"},
#'   \code{"isoxml"}. Case-insensitive; if \code{NULL}, inferred from
#'   the file extension.
#' @param dose_field Character. Name of the numeric column carrying the
#'   N rate (kg N ha\eqn{^{-1}}). Defaults try \code{"N_target"},
#'   \code{"dose"}, \code{"rate"} in that order.
#' @param area_min Numeric. Drop polygon slivers smaller than this area
#'   in square metres (default \code{1}).
#' @param isoxml_opts Named list with metadata used by
#'   \code{format = "isoxml"}: \code{task_name}, \code{field_name},
#'   \code{crop}, \code{product}, \code{unit}, \code{ddi_code}. All
#'   optional, sensible defaults are applied.
#'
#' @return Invisibly, the \code{sf} object actually written to disk
#'   (after projection to WGS84, validity cleaning, field renaming and
#'   sliver removal).
#'
#' @seealso \code{\link{export_prescription_all}},
#'   \code{\link{variable_rate_N}}, \code{\link{farm_balance}}
#'
#' @examples
#' \dontrun{
#' farm <- agrinutri::farm_balance(
#'   system.file("extdata/example_farm.geojson", package = "agrinutri"))
#'
#' # Universal Shapefile
#' export_prescription(farm, "field_rx.shp")
#'
#' # John Deere-ready Shapefile (integer RATE)
#' export_prescription(farm, "JD/field_rx.shp", format = "johndeere")
#'
#' # ISOXML directory
#' export_prescription(farm, "TASKDATA", format = "isoxml",
#'   isoxml_opts = list(task_name = "N top-dress",
#'                       product = "Urea 46 pct",
#'                       unit = "kg/ha"))
#' }
#' @export
export_prescription <- function(x, path,
                                format      = NULL,
                                dose_field  = NULL,
                                area_min    = 1,
                                isoxml_opts = list()) {
  if (!requireNamespace("sf", quietly = TRUE))
    stop("Package 'sf' is required for export_prescription().")

  # 1. Normalise input to an sf object -------------------------------
  sfobj <- .as_sf_prescription(x)

  # 2. Pick the dose field -------------------------------------------
  if (is.null(dose_field))
    dose_field <- .auto_dose_field(sfobj)

  # 3. Resolve format from the path extension if missing -------------
  if (is.null(format)) format <- .guess_format(path)
  format <- tolower(format)[1]

  # 4. Dispatch --------------------------------------------------------
  switch(format,
    shp       = .write_prescription(sfobj, path, dose_field,
                                     out_name = "DOSE",    digits = 1,
                                     area_min = area_min),
    geojson   = .write_prescription(sfobj, path, dose_field,
                                     out_name = "dose",    digits = 2,
                                     area_min = area_min),
    kml       = .write_prescription(sfobj, path, dose_field,
                                     out_name = "dose",    digits = 1,
                                     area_min = area_min, driver = "KML"),
    gpkg      = .write_prescription(sfobj, path, dose_field,
                                     out_name = "dose",    digits = 2,
                                     area_min = area_min,
                                     gpkg_layer = "prescription"),
    johndeere = .write_prescription(sfobj, path, dose_field,
                                     out_name = "RATE",    digits = 0,
                                     as_integer = TRUE,    area_min = area_min),
    trimble   = .write_prescription(sfobj, path, dose_field,
                                     out_name = "TGT_RATE", digits = 1,
                                     area_min = area_min),
    isoxml    = .export_isoxml(sfobj, path, dose_field, area_min,
                                isoxml_opts),
    stop("Unknown export format: '", format, "'. Supported: shp, ",
         "geojson, kml, gpkg, johndeere, trimble, isoxml.")
  )
}

#' Export a prescription map in many formats at once
#'
#' Convenience wrapper around \code{\link{export_prescription}} that
#' writes several formats side-by-side into the same output directory.
#'
#' @param x Input map (\code{sf} or raster, see
#'   \code{\link{export_prescription}}).
#' @param output_dir Directory where the files are written (created if
#'   missing).
#' @param basename File name stem (without extension); defaults to
#'   \code{"prescription"}.
#' @param formats Character vector. Any subset of
#'   \code{c("shp", "geojson", "kml", "gpkg", "johndeere", "trimble",
#'   "isoxml")}. Default: all seven.
#' @param dose_field,area_min,isoxml_opts Passed through to
#'   \code{\link{export_prescription}}.
#'
#' @return Invisibly, a named list of file paths written (one entry per
#'   format).
#' @seealso \code{\link{export_prescription}}
#' @examples
#' \dontrun{
#' farm <- agrinutri::farm_balance(
#'   system.file("extdata/example_farm.geojson", package = "agrinutri"))
#' export_prescription_all(farm, "rx_maps", "farm_2026",
#'   formats = c("shp", "geojson", "isoxml", "johndeere"))
#' }
#' @export
export_prescription_all <- function(x,
                                    output_dir,
                                    basename   = "prescription",
                                    formats    = c("shp", "geojson", "kml",
                                                   "gpkg", "johndeere",
                                                   "trimble", "isoxml"),
                                    dose_field  = NULL,
                                    area_min    = 1,
                                    isoxml_opts = list()) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  formats <- tolower(formats)
  out <- list()

  if ("shp" %in% formats) {
    p <- file.path(output_dir, paste0(basename, ".shp"))
    export_prescription(x, p, "shp", dose_field, area_min)
    out$shp <- p
  }
  if ("geojson" %in% formats) {
    p <- file.path(output_dir, paste0(basename, ".geojson"))
    export_prescription(x, p, "geojson", dose_field, area_min)
    out$geojson <- p
  }
  if ("kml" %in% formats) {
    p <- file.path(output_dir, paste0(basename, ".kml"))
    export_prescription(x, p, "kml", dose_field, area_min)
    out$kml <- p
  }
  if ("gpkg" %in% formats) {
    p <- file.path(output_dir, paste0(basename, ".gpkg"))
    export_prescription(x, p, "gpkg", dose_field, area_min)
    out$gpkg <- p
  }
  if ("johndeere" %in% formats) {
    sub <- file.path(output_dir, "johndeere")
    dir.create(sub, showWarnings = FALSE)
    p <- file.path(sub, paste0(basename, "_JD.shp"))
    export_prescription(x, p, "johndeere", dose_field, area_min)
    out$johndeere <- p
  }
  if ("trimble" %in% formats) {
    sub <- file.path(output_dir, "trimble")
    dir.create(sub, showWarnings = FALSE)
    p <- file.path(sub, paste0(basename, "_TR.shp"))
    export_prescription(x, p, "trimble", dose_field, area_min)
    out$trimble <- p
  }
  if ("isoxml" %in% formats) {
    sub <- file.path(output_dir, "TASKDATA")
    export_prescription(x, sub, "isoxml", dose_field, area_min,
                        isoxml_opts = isoxml_opts)
    out$isoxml <- file.path(sub, "TASKDATA.XML")
  }
  message("Exported ", length(out), " format(s) to ",
          normalizePath(output_dir))
  invisible(out)
}

# ---------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------

# Coerce raster / sf / path into an sf polygons object
.as_sf_prescription <- function(x) {
  if (inherits(x, "sf")) return(x)
  if (is.character(x) && length(x) == 1 && file.exists(x))
    return(sf::st_read(x, quiet = TRUE))
  # SpatRaster (or a legacy raster object, coerced) -> polygons
  if (inherits(x, c("RasterLayer", "RasterStack", "RasterBrick"))) {
    if (!requireNamespace("terra", quietly = TRUE))
      stop("Package 'terra' is required to polygonise a raster.")
    x <- terra::rast(x)
  }
  if (inherits(x, "SpatRaster")) {
    if (!requireNamespace("terra", quietly = TRUE))
      stop("Package 'terra' is required to polygonise a SpatRaster.")
    poly <- terra::as.polygons(x, dissolve = FALSE, na.rm = TRUE,
                                values = TRUE)
    return(sf::st_as_sf(poly))
  }
  stop("`x` must be an sf object, a file path, or a raster.")
}

.auto_dose_field <- function(sfobj) {
  candidates <- c("N_target", "dose", "rate", "DOSE", "RATE",
                  "TGT_RATE", "N_rate")
  hit <- intersect(candidates, names(sfobj))
  if (length(hit) > 0) return(hit[1])
  # Fallback: first numeric non-geometry column
  is_num <- vapply(sf::st_drop_geometry(sfobj), is.numeric, logical(1))
  if (any(is_num)) return(names(sfobj)[which(is_num)[1]])
  stop("No numeric field found. Supply `dose_field` explicitly.")
}

.guess_format <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (!nzchar(ext)) {
    # No extension: treat as a directory -> ISOXML
    return("isoxml")
  }
  switch(ext,
    shp = "shp", geojson = "geojson", json = "geojson",
    kml = "kml", gpkg = "gpkg",
    xml = "isoxml",
    stop("Cannot infer format from extension '.", ext, "'. ",
         "Pass `format` explicitly."))
}

# Common polygon-prep + write for the non-ISOXML drivers
.write_prescription <- function(sfobj, path, dose_field,
                                out_name = "DOSE",
                                digits   = 1,
                                as_integer = FALSE,
                                area_min = 1,
                                driver   = NULL,
                                gpkg_layer = NULL) {
  if (!dose_field %in% names(sfobj))
    stop("Dose field '", dose_field, "' not found in the input.")
  # True area (geodesic for lon/lat input; Web Mercator would inflate it by
  # 1 / cos^2(latitude), i.e. about x2 at 45 deg N)
  sfobj$area_m2 <- as.numeric(sf::st_area(sfobj))
  keep <- sfobj$area_m2 >= area_min
  sfobj <- sfobj[keep, , drop = FALSE]
  sfobj <- sf::st_make_valid(sfobj)
  sfobj <- sf::st_transform(sfobj, 4326)

  val <- round(as.numeric(sfobj[[dose_field]]), digits)
  if (isTRUE(as_integer)) val <- as.integer(val)
  sfobj[[out_name]] <- val
  sfobj$ID <- seq_len(nrow(sfobj))

  cols <- intersect(c("ID", out_name, "area_m2"), names(sfobj))
  sfobj <- sfobj[, cols, drop = FALSE]

  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  if (identical(driver, "KML"))
    sfobj <- sf::st_zm(sfobj, drop = TRUE, what = "ZM")

  write_args <- list(obj = sfobj, dsn = path,
                     delete_dsn = file.exists(path), quiet = TRUE)
  if (!is.null(driver))     write_args$driver <- driver
  if (!is.null(gpkg_layer)) write_args$layer  <- gpkg_layer
  do.call(sf::st_write, write_args)

  message("Wrote ", path, "  (", nrow(sfobj), " polygons)")
  invisible(sfobj)
}

# ISOXML TASKDATA.XML writer (ISO 11783-10)
.export_isoxml <- function(sfobj, dir_path, dose_field, area_min,
                           opts = list()) {
  if (!requireNamespace("xml2", quietly = TRUE))
    stop("Package 'xml2' is required for ISOXML export.")

  def <- list(task_name  = "Prescription",
              field_name = "Field1",
              crop       = "Cereal",
              product    = "Fertilizer",
              unit       = "kg/ha",
              ddi_code   = "0006")   # mass per area
  opts <- utils::modifyList(def, opts)

  # Prepare polygons in WGS84 with a DOSE integer*100 field
  sfobj <- .write_prep_for_isoxml(sfobj, dose_field, area_min)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)

  root <- xml2::xml_new_root(
    "ISO11783_TaskData",
    VersionMajor = "4", VersionMinor = "2",
    ManagementSoftwareManufacturer = "agrinutri",
    ManagementSoftwareVersion = as.character(
      utils::packageVersion("agrinutri")),
    DataTransferOrigin = "1")

  xml2::xml_add_child(root, "PFD",
    A = "PFD1", C = opts$field_name,
    D = as.character(round(sum(sfobj$area_m2))))
  xml2::xml_add_child(root, "CTP", A = "CTP1", B = opts$crop)
  xml2::xml_add_child(root, "PDT", A = "PDT1", B = opts$product)
  tsk <- xml2::xml_add_child(root, "TSK",
    A = "TSK1", B = opts$task_name,
    C = "PFD1", E = "1", G = "1")

  doses <- sort(unique(sfobj$DOSE))
  for (k in seq_along(doses)) {
    d <- doses[k]
    tzn <- xml2::xml_add_child(tsk, "TZN",
      A = sprintf("TZN%d", k),
      B = sprintf("Rate %s %s", d, opts$unit))
    xml2::xml_add_child(tzn, "PDV",
      A = opts$ddi_code,
      B = as.character(as.integer(d * 100)),
      C = "PDT1")
  }

  coords <- sf::st_coordinates(sfobj)
  for (i in seq_len(nrow(sfobj))) {
    k       <- match(sfobj$DOSE[i], doses)
    tzn_ref <- sprintf("TZN%d", k)
    tzn_nd  <- xml2::xml_find_first(tsk,
      sprintf(".//TZN[@A='%s']", tzn_ref))
    pln <- xml2::xml_add_child(tzn_nd, "PLN", A = "1")
    lsg <- xml2::xml_add_child(pln, "LSG", A = "1")
    pts <- coords[coords[, "L2"] == i, , drop = FALSE]
    for (r in seq_len(nrow(pts))) {
      xml2::xml_add_child(lsg, "PNT",
        A = "2",
        C = sprintf("%.8f", pts[r, "Y"]),
        D = sprintf("%.8f", pts[r, "X"]))
    }
  }

  xml_file <- file.path(dir_path, "TASKDATA.XML")
  xml2::write_xml(root, xml_file)
  message("ISOXML written to ", xml_file)
  invisible(xml_file)
}

.write_prep_for_isoxml <- function(sfobj, dose_field, area_min) {
  if (!dose_field %in% names(sfobj))
    stop("Dose field '", dose_field, "' not found in the input.")
  sfobj$area_m2 <- as.numeric(sf::st_area(sfobj))
  sfobj <- sfobj[sfobj$area_m2 >= area_min, , drop = FALSE]
  sfobj <- sf::st_make_valid(sfobj)
  sfobj <- sf::st_transform(sfobj, 4326)
  sfobj$DOSE <- round(as.numeric(sfobj[[dose_field]]), 1)
  sfobj$ID <- seq_len(nrow(sfobj))
  sfobj[, c("ID", "DOSE", "area_m2"), drop = FALSE]
}
