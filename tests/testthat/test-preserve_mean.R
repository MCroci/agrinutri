test_that(".preserve_mean hits the weighted target within the bounds", {
  pm <- agrinutri:::.preserve_mean
  d <- c(150, 230, 240, 240, 180); w <- c(1, 2, 1, 3, 1)
  out <- pm(d, w, target = 200, lo = 160, hi = 240)
  expect_equal(sum(out * w) / sum(w), 200, tolerance = 1e-8)
  expect_true(all(out >= 160 & out <= 240))
  # order of doses is preserved
  expect_identical(order(out), order(pmin(pmax(d, 160), 240)))
})

test_that(".preserve_mean warns when the target is infeasible", {
  pm <- agrinutri:::.preserve_mean
  expect_warning(out <- pm(c(100, 120), c(1, 1), target = 300, lo = 0, hi = 250),
                 "cannot reach")
  expect_equal(out, c(250, 250))
})

test_that("variable rate maps keep the field mean when the MAS cap binds", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 10, ncols = 10, vals = seq(0.2, 0.9, length.out = 100))
  vr <- variable_rate_N(r, n_dose = 180, method = "calibration", mas_cap = 200)
  expect_equal(vr$mean_kg_ha, 180, tolerance = 1e-6)
  expect_lte(vr$max_kg_ha, 200)
})
