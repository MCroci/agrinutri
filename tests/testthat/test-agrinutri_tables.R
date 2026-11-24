# Replacement coefficient tables change the balance and can be removed again.

test_that("agrinutri_tables() re-parameterises the balance and restores the defaults", {
  crop <- "Grain maize 500-700 (grain)"
  base <- calc_crop_N_demand(10, crop)$N_requirement
  my <- uptake_table
  my$N[my$crop == crop] <- my$N[my$crop == crop] * 1.1
  old <- agrinutri_tables(uptake_table = my)
  on.exit(options(agrinutri.tables = old), add = TRUE)
  expect_equal(calc_crop_N_demand(10, crop)$N_requirement, base * 1.1, tolerance = 1e-8)
  agrinutri_tables()
  expect_equal(calc_crop_N_demand(10, crop)$N_requirement, base)
})

test_that("agrinutri_tables() rejects unnamed or incomplete tables", {
  expect_error(agrinutri_tables(uptake_table[1:3]), "by name")
  expect_error(agrinutri_tables(uptake_table = data.frame(crop = "x")), "columns of the bundled table")
  expect_null(getOption("agrinutri.tables"))
})
