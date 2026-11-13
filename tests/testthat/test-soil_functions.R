test_that("tri2 returns valid ID_Rag", {
  result <- tri2(clay = 10, sand = 35)
  expect_type(result, "integer")
  expect_true(!is.na(result))
  expect_true(result > 0)
})

test_that("tri3 returns valid texture class", {
  result <- tri3(clay = 25, sand = 20)
  expect_type(result, "character")
  expect_true(!is.na(result))
  expect_true(nchar(result) > 0)
})

test_that("calc_soil_group_and_id_rag returns correct structure", {
  result <- calc_soil_group_and_id_rag(clay = 25, sand = 20)
  
  expect_type(result, "list")
  expect_named(result, c("soil.group", "id_rag", "TRI3"))
  expect_type(result$soil.group, "character")
  expect_type(result$id_rag, "double")
  expect_true(!is.na(result$soil.group))
  expect_true(!is.na(result$id_rag))
})

test_that("soil texture functions validate input", {
  expect_error(tri2(clay = -5), "Invalid clay percentage")
  expect_error(tri2(sand = 150), "Invalid sand percentage")
  expect_error(tri2(clay = 60, sand = 50), "sum must not exceed 100%")
})

test_that("soil_fertility returns correct structure", {
  result <- soil_fertility(
    Ntot = 1.2,
    SOM = 2,
    soil.group = "Sandy textures",
    CN = 8,
    ccp = "Autumn-winter crop <150 days"
  )
  
  expect_type(result, "list")
  expect_named(result, c("b1", "b2", "b1_potential", "no_till_reduction", "B",
                         "C_tempo", "units"))
  expect_true(is.numeric(result$b1))
  expect_true(is.numeric(result$b2))
  expect_equal(result$units, "kg/ha")
  expect_true(result$b1 >= 0)
  expect_true(result$b2 >= 0)
})

test_that("tri3.table holds only codes of soil.table (no typo cells)", {
  codes <- unique(stats::na.omit(as.vector(tri3.table)))
  expect_true(all(codes %in% soil.table$ID_Suo))
  expect_identical(unname(tri3(22, 27)), "FL")   # silt loam; was the typo "FSS"
})
