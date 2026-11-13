# export_prescription() / export_prescription_all(): formats, field naming,
# CRS, sliver removal, format inference and ISOXML structure.

.rx_sf <- function() {
  sq <- function(x0, y0, s) {
    sf::st_polygon(list(rbind(c(x0, y0), c(x0 + s, y0), c(x0 + s, y0 + s),
                              c(x0, y0 + s), c(x0, y0))))
  }
  # Two 100 m x 100 m plots plus a 0.5 m x 0.5 m sliver (UTM 32N, metres)
  sf::st_sf(
    N_target = c(120.46, 80.04, 50),
    label    = c("a", "b", "sliver"),
    geometry = sf::st_sfc(sq(600000, 5000000, 100), sq(600100, 5000000, 100),
                          sq(600300, 5000000, 0.5), crs = 32632)
  )
}

.rx_read <- function(path, ...) sf::st_read(path, quiet = TRUE, ...)

# Writing to a new path must not raise GDAL warnings; only the progress
# messages are silenced.
.rx_quiet <- function(expr) suppressMessages(expr)

test_that("export_prescription writes GeoJSON in WGS84 with rounded dose and drops slivers", {
  skip_if_not_installed("sf")
  p <- file.path(tempdir(), "rx_test", "rx.geojson")
  on.exit(unlink(dirname(p), recursive = TRUE), add = TRUE)
  expect_message(out <- export_prescription(.rx_sf(), p), "2 polygons")
  expect_true(file.exists(p))
  expect_equal(nrow(out), 2L)                       # sliver (0.25 m2) removed
  expect_equal(names(sf::st_drop_geometry(out)), c("ID", "dose", "area_m2"))
  expect_equal(out$dose, c(120.46, 80.04))
  expect_equal(out$ID, 1:2)
  expect_equal(out$area_m2, c(1e4, 1e4), tolerance = 1e-6)
  expect_equal(sf::st_crs(out)$epsg, 4326L)

  back <- .rx_read(p)
  expect_equal(back$dose, c(120.46, 80.04))
  # area_min = 0 keeps the sliver
  expect_equal(nrow(.rx_quiet(export_prescription(.rx_sf(), p, area_min = 0))), 3L)
})

test_that("export_prescription applies the manufacturer conventions", {
  skip_if_not_installed("sf")
  d <- file.path(tempdir(), "rx_vendor")
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  x <- .rx_sf()

  jd <- .rx_quiet(export_prescription(x, file.path(d, "jd", "rx.shp"),
                                             format = "JohnDeere"))
  expect_type(jd$RATE, "integer")
  expect_equal(jd$RATE, c(120L, 80L))
  expect_equal(.rx_read(file.path(d, "jd", "rx.shp"))$RATE, c(120, 80))

  tr <- .rx_quiet(export_prescription(x, file.path(d, "tr.shp"), format = "trimble"))
  expect_equal(tr$TGT_RATE, c(120.5, 80))
  expect_equal(tr$ID, 1:2)

  shp <- .rx_quiet(export_prescription(x, file.path(d, "plain.shp")))
  expect_equal(shp$DOSE, c(120.5, 80))
  expect_equal(sf::st_crs(.rx_read(file.path(d, "plain.shp")))$epsg, 4326L)

  gp <- .rx_quiet(export_prescription(x, file.path(d, "rx.gpkg")))
  expect_equal(sf::st_layers(file.path(d, "rx.gpkg"))$name, "prescription")
  expect_equal(.rx_read(file.path(d, "rx.gpkg"), layer = "prescription")$dose,
               c(120.46, 80.04))

  skip_if_not("KML" %in% sf::st_drivers()$name, "no KML driver")
  km <- .rx_quiet(export_prescription(x, file.path(d, "rx.kml")))
  expect_equal(km$dose, c(120.5, 80))
  expect_true(file.exists(file.path(d, "rx.kml")))
})

test_that("export_prescription picks the dose field automatically or explicitly", {
  skip_if_not_installed("sf")
  p <- tempfile(fileext = ".geojson")
  on.exit(unlink(p), add = TRUE)
  x <- .rx_sf()

  names(x)[names(x) == "N_target"] <- "my_dose"      # no candidate -> first numeric
  out <- .rx_quiet(export_prescription(x, p))
  expect_equal(out$dose, c(120.46, 80.04))

  x$rate <- c(1, 2, 3)                               # 'rate' is a known candidate
  out2 <- .rx_quiet(export_prescription(x, p))
  expect_equal(out2$dose, c(1, 2))

  out3 <- .rx_quiet(export_prescription(x, p, dose_field = "my_dose"))
  expect_equal(out3$dose, c(120.46, 80.04))

  expect_error(export_prescription(x, p, dose_field = "missing_col"),
               "Dose field 'missing_col' not found")
  expect_error(export_prescription(x[, "label"], p), "No numeric field found")
})

test_that("export_prescription infers the format from the extension and rejects bad input", {
  skip_if_not_installed("sf")
  g <- NFert:::.guess_format
  expect_equal(g("a.shp"), "shp")
  expect_equal(g("a.JSON"), "geojson")
  expect_equal(g("a.geojson"), "geojson")
  expect_equal(g("a.kml"), "kml")
  expect_equal(g("a.gpkg"), "gpkg")
  expect_equal(g("dir/TASKDATA.XML"), "isoxml")
  expect_equal(g("TASKDATA"), "isoxml")
  expect_error(g("a.csv"), "Cannot infer format")

  expect_error(export_prescription(.rx_sf(), tempfile(), format = "dxf"),
               "Unknown export format")
  expect_error(export_prescription(42, tempfile(fileext = ".geojson")),
               "must be an sf object, a file path, or a raster")
})

test_that("export_prescription accepts a file path and polygonises a SpatRaster", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  d <- file.path(tempdir(), "rx_inputs")
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  dir.create(d, showWarnings = FALSE)

  src <- file.path(d, "src.geojson")
  sf::st_write(.rx_sf(), src, quiet = TRUE)
  out <- .rx_quiet(export_prescription(src, file.path(d, "from_path.geojson")))
  expect_equal(out$dose, c(120.46, 80.04))

  r <- terra::rast(nrows = 2, ncols = 2, xmin = 600000, xmax = 600020,
                   ymin = 5000000, ymax = 5000020, crs = "EPSG:32632",
                   vals = c(100, 110, NA, 130))
  names(r) <- "rate"
  outr <- .rx_quiet(export_prescription(r, file.path(d, "from_rast.geojson")))
  expect_equal(nrow(outr), 3L)                     # NA cell dropped
  expect_setequal(outr$dose, c(100, 110, 130))
  expect_equal(outr$area_m2, rep(100, 3), tolerance = 1e-6)
})

test_that("ISOXML export writes one treatment zone per unique dose", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  d <- file.path(tempdir(), "rx_iso", "TASKDATA")
  on.exit(unlink(dirname(d), recursive = TRUE), add = TRUE)
  x <- .rx_sf()
  x$N_target[1:2] <- c(80, 80)
  x <- rbind(x, x[1, ])
  sf::st_geometry(x)[[4]] <- sf::st_geometry(x)[[1]] + c(500, 0)
  x$N_target[4] <- 140.04

  expect_message(f <- export_prescription(
    x, d, isoxml_opts = list(task_name = "N top-dress", product = "Urea 46")),
    "ISOXML written")
  expect_equal(basename(f), "TASKDATA.XML")
  doc <- xml2::read_xml(f)
  root <- xml2::xml_root(doc)
  expect_equal(xml2::xml_name(root), "ISO11783_TaskData")
  expect_equal(xml2::xml_attr(root, "ManagementSoftwareManufacturer"), "NFert")
  expect_equal(xml2::xml_attr(xml2::xml_find_first(doc, "//TSK"), "B"), "N top-dress")
  expect_equal(xml2::xml_attr(xml2::xml_find_first(doc, "//PDT"), "B"), "Urea 46")
  expect_equal(xml2::xml_attr(xml2::xml_find_first(doc, "//CTP"), "B"), "Cereal")

  tzn <- xml2::xml_find_all(doc, "//TZN")
  expect_length(tzn, 2L)                            # doses 80 and 140 (sliver dropped)
  pdv <- xml2::xml_attr(xml2::xml_find_all(doc, "//TZN/PDV"), "B")
  expect_equal(pdv, c("8000", "14000"))
  expect_equal(unique(xml2::xml_attr(xml2::xml_find_all(doc, "//PDV"), "A")), "0006")
  # 3 polygons (2 at 80, 1 at 140), each a closed 5-vertex ring
  expect_length(xml2::xml_find_all(doc, "//PLN"), 3L)
  expect_length(xml2::xml_find_all(doc, "//TZN[1]/PLN"), 2L)
  expect_length(xml2::xml_find_all(doc, "//PNT"), 15L)
  # field area (PFD@D) = sum of retained polygons, 3 x 1 ha
  expect_equal(as.numeric(xml2::xml_attr(xml2::xml_find_first(doc, "//PFD"), "D")),
               3e4, tolerance = 1)
  expect_error(NFert:::.write_prep_for_isoxml(x, "nope", 1), "Dose field 'nope'")
})

test_that("export_prescription_all writes every requested format", {
  skip_if_not_installed("sf")
  skip_if_not_installed("xml2")
  d <- file.path(tempdir(), "rx_all")
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  fmts <- c("shp", "geojson", "gpkg", "johndeere", "trimble", "isoxml")
  if ("KML" %in% sf::st_drivers()$name) fmts <- c(fmts, "kml")
  out <- .rx_quiet(export_prescription_all(.rx_sf(), d, basename = "farm",
                                                  formats = toupper(fmts)))
  expect_setequal(names(out), fmts)
  expect_true(all(file.exists(unlist(out))))
  expect_equal(basename(out$johndeere), "farm_JD.shp")
  expect_equal(basename(out$trimble), "farm_TR.shp")
  expect_equal(out$isoxml, file.path(d, "TASKDATA", "TASKDATA.XML"))
  expect_message(export_prescription_all(.rx_sf(), d, formats = character(0)),
                 "Exported 0 format")
})
