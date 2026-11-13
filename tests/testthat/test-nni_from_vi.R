# nni_from_vi_empirical(): linear VI -> NNI regression, clipping and zones

.vi_rast <- function(vals) {
  terra::rast(nrows = 1, ncols = length(vals), xmin = 0, xmax = length(vals),
              ymin = 0, ymax = 1, crs = "EPSG:32632", vals = vals)
}

test_that("nni_from_vi_empirical applies the default NDRE wheat regression", {
  skip_if_not_installed("terra")
  out <- nni_from_vi_empirical(.vi_rast(c(0.1, 0.2, 0.25, 0.4)),
                               index = "NDRE", crop = "wheat")
  expect_named(out, c("NNI", "zones", "slope", "intercept", "index", "crop"))
  expect_equal(c(out$slope, out$intercept), c(3.5, 0.30))
  # 3.5 * VI + 0.3 = 0.65, 1.0, 1.175, 1.70 -> clipped to [0.5, 1.5]
  expect_equal(terra::values(out$NNI, mat = FALSE), c(0.65, 1.0, 1.175, 1.5))
  # zones: [-Inf,0.9) = 1, [0.9,1.1) = 2, [1.1, Inf] = 3
  expect_equal(terra::values(out$zones, mat = FALSE), c(1, 2, 3, 3))
})

test_that("nni_from_vi_empirical defaults differ by index and crop", {
  skip_if_not_installed("terra")
  r <- .vi_rast(0.3)
  ndvi_m <- nni_from_vi_empirical(r, index = "NDVI", crop = "maize")
  expect_equal(c(ndvi_m$slope, ndvi_m$intercept), c(1.6, 0.15))
  expect_equal(terra::values(ndvi_m$NNI, mat = FALSE), 1.6 * 0.3 + 0.15)

  ci_r <- nni_from_vi_empirical(.vi_rast(2), index = "CIred_edge", crop = "rice")
  expect_equal(terra::values(ci_r$NNI, mat = FALSE), 0.25 * 2 + 0.50)

  # default index is NDRE (first of match.arg choices)
  expect_equal(nni_from_vi_empirical(r, crop = "rice")$index, "NDRE")
})

test_that("nni_from_vi_empirical accepts Italian crop aliases", {
  skip_if_not_installed("terra")
  r <- .vi_rast(0.2)
  expect_equal(nni_from_vi_empirical(r, crop = "Frumento")$crop, "wheat")
  expect_equal(nni_from_vi_empirical(r, crop = "grano")$crop, "wheat")
  expect_equal(nni_from_vi_empirical(r, crop = " MAIS ")$crop, "maize")
  expect_equal(nni_from_vi_empirical(r, crop = "orzo")$crop, "barley")
  expect_equal(nni_from_vi_empirical(r, crop = "riso")$crop, "rice")
})

test_that("nni_from_vi_empirical honours slope/intercept, range and thresholds", {
  skip_if_not_installed("terra")
  out <- nni_from_vi_empirical(.vi_rast(c(0, 0.5, 1)), index = "NDVI",
                               crop = "wheat", slope = 2, intercept = 0,
                               nni_range = c(0, 3), nni_thresholds = c(0.5, 1.5))
  expect_equal(c(out$slope, out$intercept), c(2, 0))
  expect_equal(terra::values(out$NNI, mat = FALSE), c(0, 1, 2))
  expect_equal(terra::values(out$zones, mat = FALSE), c(1, 2, 3))

  # Only one of slope/intercept supplied -> defaults are used for both
  half <- nni_from_vi_empirical(.vi_rast(0.2), index = "NDRE", crop = "wheat",
                                slope = 10)
  expect_equal(c(half$slope, half$intercept), c(3.5, 0.30))
})

test_that("nni_from_vi_empirical validates inputs", {
  skip_if_not_installed("terra")
  expect_error(nni_from_vi_empirical(matrix(0.2), crop = "wheat"),
               "must be a SpatRaster")
  expect_error(nni_from_vi_empirical(.vi_rast(0.2), index = "EVI"))
  # NOTE: the error message is malformed (sprintf() receives extra arguments
  # and R warns "arguments not used by format"); see the test below.
  expect_error(suppressWarnings(nni_from_vi_empirical(.vi_rast(0.2), crop = "sorghum")),
               "Unsupported crop")
})

test_that("unsupported-crop error names the offending crop without warnings", {
  expect_error(nni_from_vi_empirical(.vi_rast(0.2), crop = "sorghum"),
               "Unsupported crop 'sorghum'")
})
