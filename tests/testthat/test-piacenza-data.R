# The bundled Piacenza example data must be present and reproduce the article numbers.

test_that("Piacenza example files are bundled", {
  for (f in c("piacenza_farm.geojson", "piacenza_p01_rotation.csv",
              "sentinel-2/S2_piacenza_P01_20240813.tif", "rer_soil_piacenza.tif"))
    expect_true(nzchar(system.file("extdata", f, package = "agrinutri")), info = f)
})

test_that("farm_balance() on the Piacenza farm gives the article doses", {
  skip_if_not_installed("sf")
  farm <- sf::st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"),
                      quiet = TRUE)
  out <- farm_balance(farm)
  expect_equal(nrow(out), 4L)
  expect_equal(out$N_target[out$plot == "P01"], 175, tolerance = 0.5)
  expect_false(out$MAS_ok[out$plot == "P02"])          # processing tomato above its MAS
})

test_that("the P01 rotation table runs year by year", {
  rot <- read.csv(system.file("extdata/piacenza_p01_rotation.csv", package = "agrinutri"))
  expect_equal(rot$year, 2019:2026)
  expect_true(all(rot$crop %in% uptake_table$crop))
})

test_that("regional soil clip has six layers in plausible ranges", {
  skip_if_not_installed("terra")
  soil <- terra::rast(system.file("extdata/rer_soil_piacenza.tif", package = "agrinutri"))
  expect_equal(names(soil), c("clay", "sand", "corg", "ntot", "olsen_p", "k_exch"))
  rng <- terra::global(soil, "range", na.rm = TRUE)
  expect_true(all(rng[, 1] >= 0))
  expect_lt(rng["ntot", 2], 5)                         # g/kg, not percent x 10
})
