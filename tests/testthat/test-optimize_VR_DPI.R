test_that("agrinutri_to_quefts_crop reads bundled IT table", {
  cp <- agrinutri_to_quefts_crop("Grano duro (granella)")
  expect_true(is.list(cp))
  expect_true(all(c("Yzero", "SeasonLength") %in% names(cp)))
})

test_that("agrinutri_to_quefts_soil returns QUEFTS soil list", {
  s <- agrinutri_to_quefts_soil(45)
  expect_identical(names(s)[1], "N_base_supply")
  expect_true(is.matrix(s$UptakeAdjust))
})

test_that("optimize_VR_DPI runs on tiny raster (optional deps)", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  skip_if_not_installed("limSolve")
  # Some Windows builds segfault in Rquefts::optApp; skip there for CI stability
  if (identical(.Platform$OS.type, "windows")) {
    skip("skip optApp integration on Windows (Rquefts)")
  }

  fld <- list(
    crop = "Grano duro (granella)",
    expected_yield_tons_ha = 6,
    ccp = "Spring-summer crop 100-130 days",
    sand = 15.5,
    clay = 18.5,
    Ntot = 1.5,
    SOM = 2,
    CN = 7.73,
    oxygen_availability = "Slow",
    winter_rain = 150,
    start_spring_rain = 0,
    prev_crop = "Winter cereals straw removal",
    source = "Cattle slurry",
    fertorg_frequency = "every year",
    location = "Isolated plain",
    forg_quantity = 0,
    organic_previous_year_N = 0,
    E_to_D = TRUE
  )
  r <- terra::rast(
    nrows = 3L,
    ncols = 3L,
    xmin = 0,
    xmax = 30,
    ymin = 0,
    ymax = 30,
    crs = "EPSG:32632",
    vals = runif(9, 0.6, 1)
  )
  out <- optimize_VR_DPI(fld, r, prices = list(p_y = 280))
  expect_s4_class(out$N_prescription, "SpatRaster")
  expect_type(out$compliance, "list")
})
