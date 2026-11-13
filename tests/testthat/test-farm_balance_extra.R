# farm_balance(): sf input, P/K balances, output file, per-row error capture
# and input validation. MAS values are deliberately not asserted here.

.farm <- function() {
  skip_if_not_installed("sf")
  ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
  skip_if(!nzchar(ex), "no bundled example_farm.geojson")
  sf::st_read(ex, quiet = TRUE)
}

test_that("farm_balance accepts an sf object and matches a direct N_balance()", {
  farm <- .farm()
  out <- farm_balance(farm)
  expect_equal(nrow(out), nrow(farm))
  expect_true(all(is.na(out$balance_error)))
  # Plot P07 (durum wheat, no organic) recomputed by hand
  r <- sf::st_drop_geometry(farm)[farm$plot_id == "P07", ]
  bal <- N_balance(
    expected_yield_tons_ha = r$expected_yield_tons_ha, crop = r$crop, ccp = r$ccp,
    sand = r$sand, clay = r$clay, Ntot = r$Ntot, SOM = r$SOM, CN = r$CN,
    oxygen_availability = agrinutri_normalize_oxygen(r$oxygen_availability),
    winter_rain = r$winter_rain, start_spring_rain = r$start_spring_rain,
    prev_crop = r$prev_crop, source = NA, fertorg_frequency = r$fertorg_frequency,
    location = r$location, forg_quantity = r$forg_quantity,
    organic_previous_year_N = 0
  )
  i <- which(out$plot_id == "P07")
  expect_equal(out$N_target[i], round(calculate_N_fertilization(bal), 1))
  expect_equal(out$N_total_kg, round(out$N_target * out$area_ha, 1))
  expect_true(all(out$N_target >= 0))
})

test_that("farm_balance adds P2O5 / K2O targets when requested", {
  farm <- .farm()[1:3, ]
  farm$olsen_value <- c(10, 20, NA)
  farm$k_value <- c(80, 150, 200)
  out <- farm_balance(farm, p_balance = TRUE, k_balance = TRUE)
  expect_true(all(c("P2O5_target", "K2O_target") %in% names(out)))
  expect_true(is.na(out$P2O5_target[3]))               # no Olsen value
  p1 <- P_balance(expected_yield_tons_ha = farm$expected_yield_tons_ha[1],
                  crop = farm$crop[1], olsen_value = 10, olsen_unit = "P2O5",
                  sand = farm$sand[1], clay = farm$clay[1])
  expect_equal(out$P2O5_target[1], round(p1$P2O5_required, 1))
  k2 <- K_balance(expected_yield_tons_ha = farm$expected_yield_tons_ha[2],
                  crop = farm$crop[2], k_value = 150, k_unit = "K2O",
                  sand = farm$sand[2], clay = farm$clay[2])
  expect_equal(out$K2O_target[2], round(k2$K2O_required, 1))
  expect_true(all(out$K2O_target >= 0))

  plain <- farm_balance(farm)
  expect_false(any(c("P2O5_target", "K2O_target") %in% names(plain)))
})

test_that("farm_balance writes the enriched layer and overwrites existing output", {
  farm <- .farm()[1:2, ]
  p <- tempfile(fileext = ".geojson")
  on.exit(unlink(p), add = TRUE)
  writeLines("stale", p)
  out <- farm_balance(farm, output = p)
  back <- sf::st_read(p, quiet = TRUE)
  expect_equal(nrow(back), 2L)
  expect_equal(back$N_target, out$N_target)
})

test_that("farm_balance records per-row errors without dropping rows", {
  farm <- .farm()[1:2, ]
  farm$crop[2] <- "Not a crop at all"
  expect_warning(out <- farm_balance(farm), "not found in lookup")
  expect_equal(nrow(out), 2L)
  expect_true(is.na(out$balance_error[1]))
  expect_true(is.character(out$balance_error[2]) && nzchar(out$balance_error[2]))
  expect_true(is.na(out$N_target[2]))
})

test_that("farm_balance validates its input", {
  farm <- .farm()
  expect_error(farm_balance(42), "path to a vector file or an sf object")
  expect_error(farm_balance(farm[, c("crop", "sand")]), "Missing required columns")
})

test_that("%||% returns the fallback for NULL", {
  `%||%` <- agrinutri:::`%||%`
  expect_equal(NULL %||% 1, 1)
  expect_equal(NA %||% 1, NA)
  expect_equal(0 %||% 1, 0)
})

test_that("%||% also treats zero-length values as missing (as farm_balance.R intends)", {
  expect_equal(agrinutri:::`%||%`(character(0), "a"), "a")
})
