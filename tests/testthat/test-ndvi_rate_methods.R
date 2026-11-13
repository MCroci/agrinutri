# estimate_N_rate_from_calibration_curve() and
# estimate_N_rate_from_holland_schepers(): exact values, layer selection,
# plotting branch and error paths.

.ndvi <- function(vals, nr = 1L, crs = "EPSG:32632") {
  nc <- length(vals) / nr
  terra::rast(nrows = nr, ncols = nc, xmin = 0, xmax = nc, ymin = 0, ymax = nr,
              crs = crs, vals = vals)
}

.with_null_device <- function(expr) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  force(expr)
}

test_that("two-point calibration maps NDVI min/max linearly onto maxN/minN", {
  skip_if_not_installed("terra")
  r <- .ndvi(c(0.2, 0.4, 0.6, NA))
  out <- estimate_N_rate_from_calibration_curve(r, minN = 40, maxN = 120)
  expect_s4_class(out, "SpatRaster")
  expect_equal(names(out), "Nrate")
  # N = 120 - (NDVI - 0.2) / 0.4 * 80
  expect_equal(terra::values(out, mat = FALSE), c(120, 80, 40, NA))
})

test_that("three-point calibration fits a least-squares line through the 3 points", {
  skip_if_not_installed("terra")
  v <- c(0.2, 0.3, 0.7)                       # mean 0.4
  out <- estimate_N_rate_from_calibration_curve(.ndvi(v), minN = 40, maxN = 120,
                                                meanN = 90,
                                                calibration_type = "three-point")
  fit <- stats::lm(y ~ x, data.frame(x = c(0.2, 0.4, 0.7), y = c(120, 90, 40)))
  expect_equal(terra::values(out, mat = FALSE),
               unname(stats::predict(fit, data.frame(x = v))))

  expect_error(estimate_N_rate_from_calibration_curve(.ndvi(v), 40, 120,
                                                      calibration_type = "three-point"),
               "meanN")
  expect_error(estimate_N_rate_from_calibration_curve(.ndvi(v), 40, 120,
                                                      calibration_type = "spline"),
               "Invalid calibration_type")
})

test_that("calibration curve picks the NDVI layer of a multi-layer raster", {
  skip_if_not_installed("terra")
  s <- c(.ndvi(c(0.9, 0.1, 0.5)), .ndvi(c(0.2, 0.4, 0.6)))
  names(s) <- c("B04", "NDVI")
  out <- estimate_N_rate_from_calibration_curve(s, minN = 0, maxN = 100)
  expect_equal(terra::values(out, mat = FALSE), c(100, 50, 0))

  names(s) <- c("B04", "ndvi_2024")           # prefix match
  out2 <- estimate_N_rate_from_calibration_curve(s, minN = 0, maxN = 100)
  expect_equal(terra::values(out2, mat = FALSE), c(100, 50, 0))

  names(s) <- c("a", "b")                      # no match -> first layer
  out3 <- estimate_N_rate_from_calibration_curve(s, minN = 0, maxN = 100)
  expect_equal(terra::values(out3, mat = FALSE), c(0, 100, 50))

  expect_error(estimate_N_rate_from_calibration_curve(c(0.2, 0.4), 0, 100),
               "terra SpatRaster")
})

test_that("calibration curve plotting branch runs on a null device", {
  skip_if_not_installed("terra")
  out <- .with_null_device(
    estimate_N_rate_from_calibration_curve(.ndvi(c(0.2, 0.5, 0.8)), 40, 120,
                                           meanN = 80,
                                           calibration_type = "three-point",
                                           plot = TRUE))
  expect_s4_class(out, "SpatRaster")
})

test_that("Holland-Schepers dose follows the sufficiency-index formula", {
  skip_if_not_installed("terra")
  v <- seq(0.3, 0.8, by = 0.05)
  out <- estimate_N_rate_from_holland_schepers(.ndvi(v), base_N_rate = 60, plot = FALSE)
  expect_named(out, c("dose_raster", "sufficiency_index_raster"))
  q95 <- unname(stats::quantile(v, 0.95))
  q05 <- unname(stats::quantile(v, 0.05))
  SI <- pmin(v / q95, 1)
  si_idx <- sqrt((1 - SI) / (1 - q05 / q95))
  expect_equal(terra::values(out$sufficiency_index_raster, mat = FALSE), si_idx,
               tolerance = 1e-6)
  expect_equal(terra::values(out$dose_raster, mat = FALSE), 60 * si_idx,
               tolerance = 1e-6)
  expect_equal(names(out$dose_raster), "Nrate_kg_ha")
  # Pixels at or above the 95th percentile get zero N
  expect_true(all(terra::values(out$dose_raster, mat = FALSE)[v >= q95] == 0))
})

test_that("Holland-Schepers validates the base rate and warns on degenerate inputs", {
  skip_if_not_installed("terra")
  r <- .ndvi(seq(0.3, 0.8, length.out = 6))
  expect_error(estimate_N_rate_from_holland_schepers(r, base_N_rate = 0, plot = FALSE),
               "between 1-300")
  expect_error(estimate_N_rate_from_holland_schepers(r, base_N_rate = 301, plot = FALSE),
               "between 1-300")
  expect_warning(estimate_N_rate_from_holland_schepers(.ndvi(rep(0.6, 4)), plot = FALSE),
                 "Low NDVI variability")
  expect_warning(estimate_N_rate_from_holland_schepers(.ndvi(seq(0.3, 0.8, length.out = 6),
                                                             crs = ""),
                                                       plot = FALSE),
                 "projection information missing")
})

test_that("Holland-Schepers plotting branch runs on a null device", {
  skip_if_not_installed("terra")
  v <- seq(0.3, 0.8, length.out = 16)
  out <- .with_null_device(
    estimate_N_rate_from_holland_schepers(.ndvi(v, nr = 4L), base_N_rate = 50,
                                          plot = TRUE))
  expect_s4_class(out$dose_raster, "SpatRaster")
})
