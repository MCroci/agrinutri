# The bundled CERZOO example data must be present and usable by the pipeline.

test_that("CERZOO example files are bundled", {
  expect_true(nzchar(system.file("extdata/cerzoo_field.geojson", package = "agrinutri")))
  expect_true(nzchar(system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif",
                                 package = "agrinutri")))
})

test_that("compute_vi runs on the bundled CERZOO Sentinel-2 scene", {
  skip_if_not_installed("terra")
  s2 <- terra::rast(system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif",
                                package = "agrinutri"))
  expect_equal(terra::nlyr(s2), 10L)
  ndvi <- compute_vi(s2, "NDVI", scale_factor = 10000)
  expect_s4_class(ndvi, "SpatRaster")
  rng <- range(terra::values(ndvi, mat = FALSE), na.rm = TRUE)
  expect_true(rng[1] >= -1 && rng[2] <= 1)        # valid NDVI
  expect_gt(rng[2], 0.3)                           # vegetated August maize canopy
})

test_that("CERZOO Field 3 carries the agronomic attributes for N_balance", {
  skip_if_not_installed("sf")
  f  <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "agrinutri"),
                    quiet = TRUE)
  f3 <- f[as.character(f$id) == "3", ]
  expect_equal(nrow(f3), 1L)
  expect_true(all(c("clay", "sand", "SOM", "CN") %in% names(f3)))
  expect_equal(as.numeric(f3$clay), 37)
  expect_equal(as.numeric(f3$sand), 16.8)
})
