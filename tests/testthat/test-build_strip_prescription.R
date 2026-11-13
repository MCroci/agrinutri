# Tests for strip prescription builder (sf + terra zonal means)

test_that("build_strip_prescription uniform returns sf with target dose", {
  skip_if_not_installed("sf")
  ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
  skip_if(!nzchar(ex), "no bundled example_farm.geojson")
  farm <- sf::st_read(ex, quiet = TRUE)
  field <- farm[1, , drop = FALSE]
  rx <- build_strip_prescription(
    field,
    machine_width = 24,
    cell_length   = 30,
    variability   = "uniform",
    n_target      = 150,
    min_dose      = 50,
    max_dose      = 250
  )
  expect_s3_class(rx, "sf")
  expect_true(nrow(rx) >= 1L)
  expect_true(max(abs(rx$dose - 150)) < 2) # uniform + rounding + strip weighting
})

test_that("build_strip_prescription calibration inverse vs not changes dose order", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
  skip_if(!nzchar(ex), "no bundled example_farm.geojson")
  farm <- sf::st_read(ex, quiet = TRUE)
  field <- farm[1, , drop = FALSE]
  f3857 <- sf::st_transform(field, 3857)
  bb <- sf::st_bbox(f3857)
  r <- terra::rast(
    xmin = bb[["xmin"]], xmax = bb[["xmax"]],
    ymin = bb[["ymin"]], ymax = bb[["ymax"]],
    nrows = 40, ncols = 40,
    crs = sf::st_crs(3857)$wkt
  )
  set.seed(1L)
  terra::values(r) <- stats::runif(terra::ncell(r), 0.35, 0.75)

  rx_inv <- build_strip_prescription(
    field,
    machine_width = 24,
    cell_length   = 30,
    variability   = "calibration",
    vi_raster     = r,
    n_target      = 160,
    min_dose      = 80,
    max_dose      = 220,
    vi_low        = 0.35,
    vi_high       = 0.80,
    calibration_inverse = TRUE,
    preserve_mean = TRUE
  )
  rx_dir <- build_strip_prescription(
    field,
    machine_width = 24,
    cell_length   = 30,
    variability   = "calibration",
    vi_raster     = r,
    n_target      = 160,
    min_dose      = 80,
    max_dose      = 220,
    vi_low        = 0.35,
    vi_high       = 0.80,
    calibration_inverse = FALSE,
    preserve_mean = TRUE
  )

  expect_false(isTRUE(all.equal(rx_inv$dose, rx_dir$dose)))
  wm_inv <- stats::weighted.mean(rx_inv$dose, rx_inv$area_ha, na.rm = TRUE)
  wm_dir <- stats::weighted.mean(rx_dir$dose, rx_dir$area_ha, na.rm = TRUE)
  expect_equal(wm_inv, 160, tolerance = 1)
  expect_equal(wm_dir, 160, tolerance = 1)
})

test_that("build_strip_prescription rejects non-sf field", {
  expect_error(
    build_strip_prescription(list(a = 1), variability = "uniform", n_target = 100),
    regexp = "must be an sf"
  )
})

test_that("strips have the true machine width and area (local UTM, not Web Mercator)", {
  skip_if_not_installed("sf")
  # 240 m x 300 m rectangle at 45 deg N, built in UTM 32N and passed as lon/lat
  rect <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(560000, 4985000), c(560240, 4985000), c(560240, 4985300),
    c(560000, 4985300), c(560000, 4985000)))), crs = 32632)
  field <- sf::st_sf(id = 1, geometry = sf::st_transform(rect, 4326))
  rx <- build_strip_prescription(field, machine_width = 24, angle_deg = 90,
                                 variability = "uniform", n_target = 150)
  # strips are centred on the field centroid: 9 full 24 m strips + 2 halves
  expect_equal(nrow(rx), 11L)
  expect_equal(max(rx$area_ha), 24 * 300 / 1e4, tolerance = 1e-3)
  expect_equal(sum(rx$area_ha), 7.2, tolerance = 1e-3)         # 240 x 300 m
  expect_equal(sum(rx$area_ha),
               sum(as.numeric(sf::st_area(rx))) / 1e4, tolerance = 5e-3)
})
