test_that("soilgrids_input validates its inputs before any download", {
  skip_if_not_installed("geodata")
  skip_if_not_installed("sf")

  # a small valid AOI polygon in Emilia-Romagna (WGS84)
  aoi <- sf::st_as_sf(sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(9.70, 45.00), c(9.71, 45.00), c(9.71, 45.01),
      c(9.70, 45.01), c(9.70, 45.00)))),
    crs = 4326))

  # unknown depth interval is rejected up front (no network hit)
  expect_error(soilgrids_input(aoi, depths = "0-10"), "depth interval")

  # a non-spatial AOI is rejected
  expect_error(soilgrids_input(42), "sf/sfc")
})

test_that("soilgrids_input returns a balance-ready stack (online)", {
  skip_on_cran()
  skip_if_not_installed("geodata")
  skip_if_not_installed("sf")
  skip_if_offline()

  aoi <- sf::st_as_sf(sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(9.70, 45.00), c(9.71, 45.00), c(9.71, 45.01),
      c(9.70, 45.01), c(9.70, 45.00)))),
    crs = 4326))

  soil <- tryCatch(
    soilgrids_input(aoi, crs_out = 32632, uncertainty = TRUE),
    error = function(e) skip(paste("SoilGrids unreachable:", conditionMessage(e))))

  expect_true(all(c("TN", "SOM", "Clay", "Sand", "CNratio") %in% names(soil)))
  expect_true(all(c("Clay_sd", "Sand_sd", "TN_sd", "SOM_sd") %in% names(soil)))

  rng <- function(ly) range(terra::values(soil[[ly]]), na.rm = TRUE)
  # physically plausible topsoil ranges (Po Valley alluvial soils)
  expect_gt(rng("Clay")[1], 5);  expect_lt(rng("Clay")[2], 80)
  expect_gt(rng("Sand")[1], 0);  expect_lt(rng("Sand")[2], 90)
  expect_gt(rng("TN")[1], 0.3);  expect_lt(rng("TN")[2], 8)   # g/kg
  expect_gt(rng("CNratio")[1], 4); expect_lt(rng("CNratio")[2], 20)

  # the stack feeds spatial_N_balance without error
  n <- spatial_N_balance(
    soil[[c("TN", "SOM", "Clay", "Sand", "CNratio")]],
    expected_yield_tons_ha = 9, crop = "Grano tenero FF (granella)",
    ccp = "Spring-summer crop 100-130 days",
    winter_rain = 150, start_spring_rain = 0, prev_crop = "Maize stalks buried",
    source = "None", forg_quantity = 0)
  expect_true("N_to_apply" %in% names(n))
})
