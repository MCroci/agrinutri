test_that("calc_crop_N_demand returns correct structure", {
  result <- calc_crop_N_demand(
    expected_yield_tons_ha = 10,
    crop = "Soft wheat FF - strong (grain)"
  )

  expect_type(result, "list")
  # Since agrinutri 0.12.1 the list includes `n_fixation_pct` (0 for
  # non-legumes). Use `expect_setequal()` so the test survives future
  # additions to the return value.
  expect_setequal(names(result),
                  c("N_requirement", "units", "n_fixation_pct"))
  expect_true(is.numeric(result$N_requirement))
  expect_equal(result$units, "kg/ha")
  expect_true(result$N_requirement > 0)
  # Wheat is not a legume -> no fixation reduction
  expect_equal(result$n_fixation_pct, 0)
})

test_that("calc_crop_N_demand validates input", {
  expect_error(
    calc_crop_N_demand(expected_yield_tons_ha = -5),
    "Expected yield must be a positive value"
  )
  # resolve_crop() issues a warning for unknown crop then returns input;
  # calc_crop_N_demand then raises "not found in the uptake table".
  expect_error(
    suppressWarnings(calc_crop_N_demand(crop = "Invalid Crop")),
    "not found in the uptake table"
  )
})

test_that("calc_crop_N_demand calculates correctly", {
  result <- calc_crop_N_demand(expected_yield_tons_ha = 10, crop = "Shredded corn class 700")
  # N_requirement should be positive
  expect_true(result$N_requirement > 0)
})
